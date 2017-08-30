<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<!DOCTYPE html>

<script runat="server">

    public DateTime currentDate;

    protected void Page_Load(object sender, EventArgs e)
    {
        ThreadStart ts = new ThreadStart(RefreshPriceVolumeIncreaseStocksForToday);
        Thread t = new Thread(ts);
        t.Start();
        if (!IsPostBack)
        {
            currentDate = DateTime.Parse(DateTime.Now.ToShortDateString());
            dg.DataSource = GetData();
            dg.DataBind();
        }

    }


    public static void FillPastData()
    {
        for (DateTime i = DateTime.Parse("2017-8-29"); i < DateTime.Now.AddDays(1); i = i.AddDays(1))
        {
            RefreshPriceVolumeIncreaseStocksForADay(i);
        }
    }

    public static void RefreshPriceVolumeIncreaseStocksForToday()
    {
        if (Util.IsTransacDay(DateTime.Parse(DateTime.Now.ToShortDateString())))
        {
            RefreshPriceVolumeIncreaseStocksForADay(DateTime.Parse(DateTime.Now.ToShortDateString()));
        }
    }

    public static void RefreshPriceVolumeIncreaseStocksForADay(DateTime currentDate)
    {
        double volumeIncreaseFilter = 0.3;
        double kLineEntityLengthFilter = 0.03;
        double priceIncreaseFilter = 0.08;

        if (Util.IsTransacDay(currentDate)
            && ((currentDate.ToShortDateString().Equals(DateTime.Now.ToShortDateString()) && DateTime.Now.Hour >= 14 && DateTime.Now.Minute >= 40)
            || !currentDate.ToShortDateString().Equals(DateTime.Now.ToShortDateString())))
        {
            string[] gidArr = Util.GetAllGids();
            for (int i = 0; i < gidArr.Length; i++)
            {
                try
                {
                    Stock s = new Stock(gidArr[i]);
                    s.LoadKLineDay();
                    int currentIndex = s.GetItemIndex(DateTime.Parse(currentDate.ToShortDateString()));
                    if (currentIndex > 0)
                    {
                        double currentVolume = Stock.GetVolumeAndAmount(gidArr[i], DateTime.Parse(currentDate.ToShortDateString() + " 14:40"))[0];
                        double previousVolume = Stock.GetVolumeAndAmount(gidArr[i],
                            DateTime.Parse(s.kLineDay[currentIndex - 1].startDateTime.ToShortDateString() + " 14:40"))[0];
                        if ((currentVolume - previousVolume) / previousVolume >= volumeIncreaseFilter
                            && (s.kLineDay[currentIndex].endPrice - s.kLineDay[currentIndex].startPrice) / s.kLineDay[currentIndex].startPrice >= kLineEntityLengthFilter
                            && (s.kLineDay[currentIndex].endPrice - s.kLineDay[currentIndex - 1].endPrice) / s.kLineDay[currentIndex - 1].endPrice >= priceIncreaseFilter)
                        {
                            DBHelper.InsertData("price_increase_volume_increase", new string[,] {
                            { "alarm_date", "datetime", s.kLineDay[currentIndex].startDateTime.ToShortDateString()},
                            { "gid", "varchar", gidArr[i].Trim()},
                            { "open_price", "float", s.kLineDay[currentIndex].startPrice.ToString()},
                            { "settle_price", "float", s.kLineDay[currentIndex].endPrice.ToString()},
                            { "price_increase", "float", ((s.kLineDay[currentIndex].endPrice - s.kLineDay[currentIndex-1].endPrice)/s.kLineDay[currentIndex-1].endPrice).ToString()},
                            { "volume_increase", "float", ((currentVolume-previousVolume)/previousVolume).ToString()}
                        });
                        }

                    }
                }
                catch
                {

                }
            }
        }
    }

    public DataTable GetData()
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("底价");
        dt.Columns.Add("收盘");
        dt.Columns.Add("涨幅");
        dt.Columns.Add("调整天数");
        dt.Columns.Add("今收");
        dt.Columns.Add("今量");
        dt.Columns.Add("1日");
        dt.Columns.Add("2日");
        dt.Columns.Add("3日");
        dt.Columns.Add("4日");
        dt.Columns.Add("5日");

        DataTable dtOri = DBHelper.GetDataTable(" select * from price_increase_volume_increase where alarm_date > '" + currentDate.AddDays(-20).ToShortDateString() + "' order by  alarm_date ") ;
        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock s = new Stock(drOri["gid"].ToString().Trim());
            s.LoadKLineDay();
            int currentIndex = s.GetItemIndex(currentDate);
            int startIndex = s.GetItemIndex(DateTime.Parse(drOri["alarm_date"].ToString()));
            if (startIndex < 1 || currentIndex < 1)
                continue;
            double volumeReduce = VolumeReduce(s, startIndex, currentIndex);
            if (currentIndex - startIndex <= 8
                && IsCrossStar(s, currentIndex)
                && NotBelowStartPrice(s, startIndex, currentIndex, double.Parse(drOri["open_price"].ToString()))
                && volumeReduce < 0.67
                )
            {
                DataRow dr = dt.NewRow();
                dr["代码"] = s.gid.Trim();
                dr["名称"] = s.Name.Trim();
                dr["底价"] = s.kLineDay[startIndex].startPrice;
                dr["收盘"] = s.kLineDay[startIndex].endPrice;
                dr["涨幅"]
                    = Math.Round(100 * (s.kLineDay[startIndex].endPrice - s.kLineDay[startIndex - 1].endPrice) / s.kLineDay[startIndex - 1].endPrice, 2).ToString() + "%";
                dr["调整天数"] = currentIndex - startIndex;
                dr["今收"] = s.kLineDay[currentIndex].endPrice;
                dr["今量"] = Math.Round(volumeReduce*100, 2).ToString() + "%";
                for (int i = 0; i < 5; i++)
                {
                    if (currentIndex + i + 1 < s.kLineDay.Length)
                    {
                        dr[(i + 1).ToString() + "日"]
                            = Math.Round(100 * (s.kLineDay[currentIndex + i + 1].highestPrice - s.kLineDay[currentIndex].endPrice) / s.kLineDay[currentIndex].endPrice, 2).ToString() + "%";
                    }
                    else
                    {
                        dr[(i + 1).ToString() + "日"] = "-";
                    }
                }
                dt.Rows.Add(dr);
            }


        }

        return dt;
    }

    public static bool IsCrossStar(Stock s, int index)
    {
        bool ret = false;
        if (index > 0
            && Math.Abs(s.kLineDay[index].endPrice - s.kLineDay[index].startPrice) / s.kLineDay[index - 1].endPrice <= 0.01)
        {
            ret = true;
        }
        return ret;
    }

    public static double VolumeReduce(Stock s, int volumePriceIncreaseIndex, int currentIndex)
    {
        DateTime startDate = s.kLineDay[volumePriceIncreaseIndex].startDateTime;
        DateTime endDate = s.kLineDay[currentIndex].startDateTime;
        if (endDate.ToShortDateString().Equals(DateTime.Now.ToShortDateString()))
        {
            endDate = DateTime.Parse(endDate.ToShortDateString() + " " + DateTime.Now.ToShortTimeString());
            startDate = DateTime.Parse(startDate.ToShortDateString() + " " + DateTime.Now.ToShortTimeString());
        }
        else
        {
            endDate = DateTime.Parse(endDate.ToShortDateString() + " 15:30");
            startDate = DateTime.Parse(startDate.ToShortDateString() + " 15:30");
        }
        double startVolume = Stock.GetVolumeAndAmount(s.gid, startDate)[0];
        double endVolume = Stock.GetVolumeAndAmount(s.gid, endDate)[0];
        return endVolume / startVolume;
    }

    public static bool NotBelowStartPrice(Stock s, int volumePriceIncreaseIndex, int currentIndex, double startPrice)
    {
        bool ret = true;
        for (int i = volumePriceIncreaseIndex + 1; i <= currentIndex; i++)
        {
            if (s.kLineDay[i].endPrice < startPrice)
            {
                ret = false;
                break;
            }
        }
        return ret;
    }

    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {
        currentDate = DateTime.Parse(calendar.SelectedDate.ToShortDateString());
        dg.DataSource = GetData();
        dg.DataBind();
    }

    protected void dg_SortCommand(object source, DataGridSortCommandEventArgs e)
    {

    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
 <table width="100%" >
        <tr>
            <td><asp:Calendar runat="server" id="calendar" Width="100%" OnSelectionChanged="calendar_SelectionChanged" BackColor="White" BorderColor="Black" BorderStyle="Solid" CellSpacing="1" Font-Names="Verdana" Font-Size="9pt" ForeColor="Black" Height="250px" NextPrevFormat="ShortMonth" >
                    <DayHeaderStyle Font-Bold="True" Font-Size="8pt" ForeColor="#333333" Height="8pt" />
                    <DayStyle BackColor="#CCCCCC" />
                    <NextPrevStyle Font-Bold="True" Font-Size="8pt" ForeColor="White" />
                    <OtherMonthDayStyle ForeColor="#999999" />
                    <SelectedDayStyle BackColor="#333399" ForeColor="White" />
                    <TitleStyle BackColor="#333399" BorderStyle="Solid" Font-Bold="True" Font-Size="12pt" ForeColor="White" Height="12pt" />
                    <TodayDayStyle BackColor="#999999" ForeColor="White" />
                    </asp:Calendar></td>
        </tr>
        <tr>
            <td><asp:DataGrid ID="dg" runat="server" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" Width="100%" AutoGenerateColumns="False" OnSortCommand="dg_SortCommand" AllowSorting="True" >
                <AlternatingItemStyle BackColor="#DCDCDC" />
                <Columns>
                    <asp:BoundColumn DataField="代码" HeaderText="代码"></asp:BoundColumn>
                    <asp:BoundColumn DataField="名称" HeaderText="名称"></asp:BoundColumn>
                    <asp:BoundColumn DataField="底价" HeaderText="底价"></asp:BoundColumn>
                    <asp:BoundColumn DataField="收盘" HeaderText="收盘"></asp:BoundColumn>
                    <asp:BoundColumn DataField="涨幅" HeaderText="涨幅"></asp:BoundColumn>
                    <asp:BoundColumn DataField="调整天数" HeaderText="调整天数"></asp:BoundColumn>
                    <asp:BoundColumn DataField="今收" HeaderText="今收"></asp:BoundColumn>
                    <asp:BoundColumn DataField="今量" HeaderText="今量" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="1日" HeaderText="1日" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="2日" HeaderText="2日" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="3日" HeaderText="3日" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="4日" HeaderText="4日" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="5日" HeaderText="5日" ></asp:BoundColumn>
                </Columns>
                <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
                <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
                <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
                <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
                <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
                </asp:DataGrid></td>
        </tr>
    </table>
    </form>
</body>
</html>
