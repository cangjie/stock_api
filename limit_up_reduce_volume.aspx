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
            //RefreshData();
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
        dt.Columns.Add("前日涨幅");
        dt.Columns.Add("当日收盘");
        dt.Columns.Add("当日涨幅");
        dt.Columns.Add("当日缩量");
        dt.Columns.Add("拉升天数");
        dt.Columns.Add("拉升幅度");
        dt.Columns.Add("1日放量");
        dt.Columns.Add("1日最高");
        dt.Columns.Add("2日最高");
        dt.Columns.Add("3日最高");
        dt.Columns.Add("4日最高");
        dt.Columns.Add("5日最高");
        foreach (DataRow drOri in dtOri.Rows)
        {
            DataRow dr = dt.NewRow();
            Stock s = new Stock(drOri["gid"].ToString());
            s.LoadKLineDay();
            //s.kArr = KLine.GetLocalKLine(s.gid, "day");
            dr["代码"] = s.gid;
            dr["名称"] = "<a href=\"https://touzi.sina.com.cn/public/xray/details/" + s.gid.Trim()
                + "\" target=\"_blank\"  >" + s.Name.Trim() + "</a>";
            dr["代码"] = "<a href=\"show_k_line_day.aspx?gid=" + s.gid + "&name=" + s.Name.Trim() + "\" target=\"_blank\" >"
                + s.gid + "</a>";

            double volumeToday = Stock.GetVolumeAndAmount(s.gid, DateTime.Parse(currentDate.ToShortDateString() + " 15:00"))[0];
            double volumeYesterday = Stock.GetVolumeAndAmount(s.gid, DateTime.Parse(currentDate.AddDays(-1).ToShortDateString() + " 15:00"))[0];



            int currentIndex = s.GetKLineIndexForADay(DateTime.Parse(currentDate.ToShortDateString() + " 9:30"));




            dr["当日涨幅"] = Math.Round(((s.kArr[currentIndex].endPrice - s.kArr[currentIndex - 1].endPrice) * 100 / s.kArr[currentIndex - 1].endPrice), 2).ToString() + "%";
            dr["当日缩量"] = Math.Round((volumeYesterday - volumeToday) * 100 / volumeYesterday, 2).ToString() + "%";
            int raiseUpDays = GetRaiseUpDays(s, currentIndex);
            dr["拉升天数"] = raiseUpDays.ToString();
            dr["拉升幅度"] = Math.Round(GetRaiseUpRate(s, currentIndex, raiseUpDays) * 100, 2).ToString() + "%";
            int idx = currentIndex;

            if (idx > 1)
            {
                dr["前日涨幅"] = Math.Round(100 * (s.kArr[idx - 1].endPrice - s.kArr[idx - 2].endPrice) / s.kArr[idx - 2].endPrice, 2).ToString() + "%";
                double settle = s.kArr[idx].endPrice;
                dr["当日收盘"] = Math.Round(settle, 2).ToString();
                /*
                                double volumeTomorrow = 0;

                                if (currentIndex < s.kArr.Length - 1)
                                {
                                    volumeTomorrow = Stock.GetVolumeAndAmount(s.gid, s.kArr[currentIndex + 1].endDateTime)[0];
                                }
                                dr["1日放量"] = (volumeTomorrow == 0)? "-" : Math.Round((volumeTomorrow - volumeToday)*100/volumeToday, 2).ToString() + "%";
                  */
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
        if (DateTime.Now.Hour < 14 || DateTime.Now.Minute < 30)
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
                    if ((s.kArr[idx - 1].endPrice - s.kArr[idx - 2].endPrice) / s.kArr[idx - 1].endPrice >= 0.05)
                    {
                        double volume = Stock.GetVolumeAndAmount(s.gid, DateTime.Parse(i.ToShortDateString() + " 14:35"))[0];
                        double volumeLast = Stock.GetVolumeAndAmount(s.gid, DateTime.Parse(s.kArr[idx - 1].startDateTime.ToShortDateString() + " 14:30"))[0];

                        if (volumeLast - volume > 0 && volume / volumeLast < 0.67)
                        {
                            try
                            {
                                int ret = DBHelper.InsertData("limit_up_volume_reduce", new string[,] {
                                { "gid", "varchar", gid},
                                { "alert_date", "datetime", i.ToShortDateString()}
                                });
                                if (ret == 1)
                                {
                                    string stockName = (new Stock(gid)).Name;
                                    StockWatcher.SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", gid, stockName, Math.Round(s.LastTrade, 2), "volumedecrease");
                                    StockWatcher.SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", gid, stockName, Math.Round(s.LastTrade, 2), "volumedecrease");
                                    StockWatcher.SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", gid, stockName, Math.Round(s.LastTrade, 2), "volumedecrease");
                                }
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

    protected void dg_SortCommand(object source, DataGridSortCommandEventArgs e)
    {
        string sortCommand = e.SortExpression;
        string colmunName = sortCommand.Split('|')[0].Trim();
        string command = sortCommand.Split('|')[1].Trim();
        DataTable dt = GetData();
        DataTable dtNew = dt.Clone();
        dt.Columns.Add(colmunName + "double", Type.GetType("System.Double"));
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            dt.Rows[i][colmunName + "double"] = GetPercentValue(dt.Rows[i][colmunName].ToString().Trim());
        }
        DataRow[] drArr = dt.Select("", colmunName + "double " + command);
        for (int i = 0; i < drArr.Length; i++)
        {
            DataRow drNew = dtNew.NewRow();
            for (int j = 0; j < dtNew.Columns.Count; j++)
            {
                drNew[j] = drArr[i][j];
            }
            dtNew.Rows.Add(drNew);
        }
        dg.DataSource = dtNew;

        for (int i = 0; i < dg.Columns.Count; i++)
        {
            if (dg.Columns[i].SortExpression.StartsWith(colmunName))
            {
                dg.Columns[i].SortExpression = colmunName.Trim() + "|" + (command.Trim().Equals("asc")? "desc":"asc");
            }
        }

        dg.DataBind();
    }

    public int GetRaiseUpDays(Stock stock, int currentIndex)
    {
        int i = currentIndex-1;
        for (; i > 0; i--)
        {
            double bottomOfKLine = Math.Min(stock.kArr[i].startPrice, stock.kArr[i].endPrice);
            if (bottomOfKLine < stock.GetAverageSettlePrice(i, 3, 3))
            {
                break;
            }
            else
            {

            }
        }
        return currentIndex - i;
    }

    public double GetRaiseUpRate(Stock stock, int currentIndex, int raiseUpDays)
    {
        double lowestPrice = double.MaxValue;
        for (int i = currentIndex - 1; i >= currentIndex - raiseUpDays; i--)
        {
            lowestPrice = Math.Min(lowestPrice, stock.kArr[i].startPrice);
            lowestPrice = Math.Min(lowestPrice, stock.kArr[i].endPrice);
        }
        return (stock.kArr[currentIndex - 1].highestPrice - lowestPrice) / lowestPrice;

    }

    public static double GetPercentValue(string str)
    {
        if (str.Trim().Equals("-") || str.Trim().Equals(""))
            return 0;
        Match m = Regex.Match(str, @"-*\d+.*\d*%");
        try
        {
            return double.Parse(m.Value.Replace(">", "").Replace("<", "").Replace("%", ""));
        }
        catch
        {
            return 0;
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
        <asp:DataGrid ID="dg" runat="server" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" AutoGenerateColumns="False" OnSortCommand="dg_SortCommand" AllowSorting="True" >
            <AlternatingItemStyle BackColor="#DCDCDC" />
            <Columns>
                <asp:BoundColumn DataField="代码" HeaderText="代码"></asp:BoundColumn>
                <asp:BoundColumn DataField="名称" HeaderText="名称"></asp:BoundColumn>
                <asp:BoundColumn DataField="拉升天数" HeaderText="拉升天数" SortExpression="拉升天数|desc"></asp:BoundColumn>
                <asp:BoundColumn DataField="拉升幅度" HeaderText="拉升幅度" SortExpression="拉升幅度|desc"></asp:BoundColumn>
                <asp:BoundColumn DataField="前日涨幅" HeaderText="前日涨幅" SortExpression="前日涨幅|asc"></asp:BoundColumn>
                <asp:BoundColumn DataField="当日缩量" HeaderText="当日缩量" SortExpression="当日缩量|asc"></asp:BoundColumn>
                <asp:BoundColumn DataField="当日涨幅" HeaderText="当日涨幅" SortExpression="当日涨幅|asc"></asp:BoundColumn>
                <asp:BoundColumn DataField="当日收盘" HeaderText="当日收盘"></asp:BoundColumn>
                <asp:BoundColumn DataField="1日最高" HeaderText="1日最高" SortExpression="1日最高|desc"></asp:BoundColumn>
                <asp:BoundColumn DataField="2日最高" HeaderText="2日最高"></asp:BoundColumn>
                <asp:BoundColumn DataField="3日最高" HeaderText="3日最高"></asp:BoundColumn>
                <asp:BoundColumn DataField="4日最高" HeaderText="4日最高"></asp:BoundColumn>
                <asp:BoundColumn DataField="5日最高" HeaderText="5日最高"></asp:BoundColumn>
            </Columns>
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
