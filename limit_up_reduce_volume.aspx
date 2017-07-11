<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Text" %>
<!DOCTYPE html>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            ThreadStart ts = new ThreadStart(RefreshData);
            Thread t = new Thread(ts);
            t.Start();
            calendar.SelectedDate = DateTime.Now;
            dg.DataSource = GetData();
            dg.DataBind();
        }
    }

    public DataTable GetData()
    {
        DateTime currentDate = DateTime.Parse(calendar.SelectedDate.ToShortDateString());
        DataTable dtOri = DBHelper.GetDataTable(" select * from  limit_up_volume_reduce where alert_date >= '"
            + currentDate.ToShortDateString() + "'  and alert_date < '" + currentDate.AddDays(1).ToShortDateString() + "' ");


        DataTable dt = new DataTable();
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("当日收盘");
        dt.Columns.Add("缩量");
        dt.Columns.Add("1日最高");
        dt.Columns.Add("2日最高");
        dt.Columns.Add("3日最高");
        dt.Columns.Add("4日最高");
        dt.Columns.Add("5日最高");
        foreach (DataRow drOri in dtOri.Rows)
        {
            DataRow dr = dt.NewRow();
            Stock s = new Stock(drOri["gid"].ToString());
            s.kArr = KLine.GetLocalKLine(s.gid, "day");
            dr["代码"] = s.gid;
            dr["名称"] = s.Name.Trim();
            dr["代码"] = "<a href=\"show_k_line_day.aspx?gid=" + dr["代码"].ToString() + "&name=" + dr["名称"].ToString().Trim() + "\" target=\"_blank\" >"
                + dr["代码"].ToString() + "</a>";

            double volumeToday = Stock.GetVolumeAndAmount(s.gid, DateTime.Parse(currentDate.ToShortDateString() + " 15:00"))[0];
            double volumeYesterday = Stock.GetVolumeAndAmount(s.gid, DateTime.Parse(currentDate.AddDays(-1).ToShortDateString() + " 15:00"))[0];;
            dr["缩量"] = Math.Round((volumeYesterday - volumeToday) * 100 / volumeYesterday, 2).ToString() + "%";
            int idx = s.GetItemIndex(DateTime.Parse(currentDate.ToShortDateString() + " 9:30"));
            if (idx >= 0)
            {
                double settle = s.kArr[idx].endPrice;
                dr["当日收盘"] = Math.Round(settle, 2).ToString();
                for (int i = 0; i < 5; i++)
                {
                    if (idx + i + 1 < s.kArr.Length)
                    {
                        double hiPrice = s.kArr[idx + i + 1].highestPrice;
                        double rate = (hiPrice - settle) / settle;
                        if (rate > 0.02)
                        {
                            dr[(i + 1).ToString() + "日最高"] = "<font color=\"red\" >" + Math.Round(rate * 100, 2).ToString() + "%</font>";
                        }
                        else
                        {
                            if (rate < 0)
                            {
                                dr[(i + 1).ToString() + "日最高"] = "<font color=\"green\" >" + Math.Round(rate * 100, 2).ToString() + "%</font>";
                            }
                            else
                            {
                                dr[(i + 1).ToString() + "日最高"] = Math.Round(rate * 100, 2).ToString() + "%";
                            }
                        }
                    }
                    else
                    {
                        dr[(i + 1).ToString() + "日最高"] = "-";
                    }
                }
                dt.Rows.Add(dr);
            }
        }
        return dt;
    }

    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {
        dg.DataSource = GetData();
        dg.DataBind();
    }

    public static void RefreshData()
    {
        string[] gidArr = Util.GetAllGids();
        DateTime i = DateTime.Parse(DateTime.Now.ToShortDateString());
        if (!Util.IsTransacDay(i))
            return;
        foreach (string gid in gidArr)
        {
            Stock s = new Stock(gid);
            s.kArr = KLine.GetLocalKLine(gid, "day");

            if (Util.IsTransacDay(i))
            {
                int idx = s.GetItemIndex(DateTime.Parse(i.ToShortDateString() + " 9:30"));
                if (idx > 1)
                {
                    if ((s.kArr[idx - 1].endPrice - s.kArr[idx - 2].endPrice) / s.kArr[idx - 1].endPrice > 0.07)
                    {
                        double volume = Stock.GetVolumeAndAmount(s.gid, DateTime.Parse(i.ToShortDateString() + " 14:30"))[0];
                        double volumeLast = Stock.GetVolumeAndAmount(s.gid, DateTime.Parse(s.kArr[idx - 1].startDateTime.ToShortDateString() + " 14:30"))[0];

                        if (volumeLast - volume > 0 && volume / volumeLast < 0.66)
                        {
                            try
                            {
                                DBHelper.InsertData("limit_up_volume_reduce", new string[,] {
                                { "gid", "varchar", gid},
                                { "alert_date", "datetime", i.ToShortDateString()}
                                });
                            }
                            catch
                            {

                            }
                        }

                    }

                }
            }

        }

    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <asp:Calendar ID="calendar" runat="server" Width="100%" BackColor="White" BorderColor="Black" BorderStyle="Solid"  CellSpacing="1" Font-Names="Verdana" Font-Size="9pt" ForeColor="Black" Height="250px" NextPrevFormat="ShortMonth" OnSelectionChanged="calendar_SelectionChanged" >
            <DayHeaderStyle Font-Bold="True" Font-Size="8pt" ForeColor="#333333" Height="8pt" />
            <DayStyle BackColor="#CCCCCC" />
            <NextPrevStyle Font-Bold="True" Font-Size="8pt" ForeColor="White" />
            <OtherMonthDayStyle ForeColor="#999999" />
            <SelectedDayStyle BackColor="#333399" ForeColor="White" />
            <TitleStyle BackColor="#333399" BorderStyle="Solid" Font-Bold="True" Font-Size="12pt" ForeColor="White" Height="12pt" />
            <TodayDayStyle BackColor="#999999" ForeColor="White" />
        </asp:Calendar>
        <asp:DataGrid ID="dg" runat="server" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
            <AlternatingItemStyle BackColor="#DCDCDC" />
            <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
            <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
            <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
            <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
            <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
        </asp:DataGrid>
    </div>
    </form>
</body>
</html>
