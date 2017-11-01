﻿<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Threading" %>
<!DOCTYPE html>

<script runat="server">

    public string sort = "";

    public static ThreadStart ts = new ThreadStart(PageWatcher);

    public static Thread t = new Thread(ts);

    public static ThreadStart tsQ = new ThreadStart(StockWatcher.LogQuota);

    public static Thread tQ = new Thread(tsQ);

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            try
            {
                if (t.ThreadState != ThreadState.Running && t.ThreadState != ThreadState.WaitSleepJoin)
                {
                    t.Abort();
                    ts = new ThreadStart(PageWatcher);
                    t = new Thread(ts);
                    //t.Start();
                }
            }
            catch(Exception err)
            {
                Console.WriteLine(err.ToString());
            }
            try
            {
                if (tQ.ThreadState != ThreadState.Running && tQ.ThreadState != ThreadState.WaitSleepJoin)
                {
                    tQ.Abort();
                    tsQ = new ThreadStart(StockWatcher.LogQuota);
                    tQ = new Thread(tsQ);
                    tQ.Start();
                }
            }
            catch(Exception err)
            {
                Console.WriteLine(err.ToString());
            }
            dg.DataSource = GetData();
            dg.DataBind();
        }
    }

    public DataTable GetData()
    {
        DateTime currentDate = calendar.SelectedDate;
        if (currentDate.Year < 2000)
            currentDate = DateTime.Now;
        DataTable dtOri = GetData(currentDate);
        DataRow[] drOriArr = dtOri.Select(Util.GetSafeRequestValue(Request, "whereclause", "   ").Trim(), sort + (!sort.Trim().Equals("")?",":"") + " TD, KDJ, 时间, 放量 desc   ");
        return RenderHtml(drOriArr);
    }

    public void AddTotal(DataRow[] drOriArr, DataTable dt)
    {
        int totalCount = 0;
        int[] totalSum = new int[] { 0, 0, 0, 0, 0, 0 };

        int raiseCount = 0;
        int[] raiseSum = new int[] { 0, 0, 0, 0, 0, 0 };

        int fireCount = 0;
        int[] fireSum = new int[] { 0, 0, 0, 0, 0, 0 };

        int starCount = 0;
        int[] starSum = new int[] { 0, 0, 0, 0, 0, 0 };

        int shitCount = 0;

        foreach (DataRow drOri in drOriArr)
        {
            if (drOri["信号"].ToString().IndexOf("💩") < 0)
            {
                totalCount++;
                if (drOri["信号"].ToString().IndexOf("📈") >= 0)
                {
                    raiseCount++;
                }
                if (drOri["信号"].ToString().IndexOf("🔥") >= 0)
                {
                    fireCount++;
                }
                if (drOri["信号"].ToString().IndexOf("🌟") >= 0)
                {
                    starCount++;
                }
                for (int i = 1; i < 7; i++)
                {
                    string colName = ((i == 6) ? "总计" : i.ToString() + "日");
                    if (!drOri[colName].ToString().Equals("") && (double)(drOri[colName]) >= 0.01)
                    {
                        totalSum[i - 1]++;
                        if (drOri["信号"].ToString().IndexOf("📈") >= 0)
                        {
                            raiseSum[i - 1]++;
                        }
                        if (drOri["信号"].ToString().IndexOf("🔥") >= 0)
                        {
                            fireSum[i - 1]++;
                        }
                        if (drOri["信号"].ToString().IndexOf("🌟") >= 0)
                        {
                            starSum[i - 1]++;
                        }
                    }
                }

            }
            else
            {
                shitCount++;
            }
        }
        DataRow drTotal = dt.NewRow();
        drTotal["名称"] = "总计";
        drTotal["今收"] = totalCount.ToString();

        DataRow drShit = dt.NewRow();
        drShit["信号"] = "💩";
        drShit["今收"] = shitCount.ToString();
        drShit["明开"] = Math.Round(100 * (double)shitCount / (double)drOriArr.Length, 2).ToString() + "%";

        DataRow drRaise = dt.NewRow();
        drRaise["信号"] = "📈";
        drRaise["今收"] = raiseCount.ToString();
        DataRow drFire = dt.NewRow();
        drFire["信号"] = "🔥";
        drFire["今收"] = fireCount.ToString();
        DataRow drStar = dt.NewRow();
        drStar["信号"] = "🌟";
        drStar["今收"] = starCount.ToString();

        for (int i = 1; i < 7; i++)
        {
            string columeCaption = ((i == 6) ? "总计" : i.ToString() + "日");
            drTotal[columeCaption] = Math.Round(100 * (double)totalSum[i - 1] / (double)totalCount, 2).ToString() + "%";
            drFire[columeCaption] = Math.Round(100 * (double)fireSum[i-1] / (double)fireCount, 2).ToString() + "%";
            drRaise[columeCaption] = Math.Round(100 * (double)raiseSum[i-1] / (double)raiseCount, 2).ToString() + "%";
            drStar[columeCaption] = Math.Round(100 * (double)starSum[i - 1] / (double)starCount, 2).ToString() + "%";
        }

        dt.Rows.Add(drTotal);
        dt.Rows.Add(drShit);
        dt.Rows.Add(drRaise);
        dt.Rows.Add(drFire);
        dt.Rows.Add(drStar);
    }

    public DataTable RenderHtml(DataRow[] drArr)
    {

        DataTable dt = new DataTable();
        if (drArr.Length == 0)
            return dt;
        for (int i = 0; i < drArr[0].Table.Columns.Count; i++)
        {
            dt.Columns.Add(drArr[0].Table.Columns[i].Caption.Trim(), Type.GetType("System.String"));
        }
        foreach (DataRow drOri in drArr)
        {
            DataRow dr = dt.NewRow();
            double settle = Math.Round((double)drOri["今收"], 2);
            double currentPrice = Math.Round((double)drOri["明收"], 2);
            for (int i = 0; i < drArr[0].Table.Columns.Count; i++)
            {

                if (drArr[0].Table.Columns[i].DataType.FullName.ToString().Equals("System.Double"))
                {
                    switch (drArr[0].Table.Columns[i].Caption.Trim())
                    {
                        case "综指":
                        case "今收":
                        case "MACD率":
                        case "KDJ率":
                            dr[i] = Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2).ToString();
                            break;
                        case "买入":
                            double buyPrice = Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2);
                            dr[i] = "<font color=\"" + ((buyPrice > currentPrice) ? "red" : ((buyPrice==currentPrice)? "gray" : "green")) + "\" >" + Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2).ToString() + "</font>";
                            break;
                        case "明开":
                        case "明收":
                            double todayPrice = (double)drOri[i];
                            dr[i] = "<font color=\"" + (todayPrice > settle ? "red" : (todayPrice == settle ? "gray" : "green")) + "\"  >"
                                + Math.Round(todayPrice, 2).ToString() + "</font>";
                            break;
                        case "低点":
                        case "F1":
                        case "F3":
                        case "F5":
                        case "高点":
                        case "3线":
                            double currentValuePrice = (double)drOri[i];
                            dr[i] = "<font color=\"" + (currentValuePrice > currentPrice ? "red" : (currentValuePrice == currentPrice ? "gray" : "green")) + "\"  >"
                                + Math.Round(currentValuePrice, 2).ToString() + "</font>";
                            break;
                        default:
                            if (System.Text.RegularExpressions.Regex.IsMatch(drArr[0].Table.Columns[i].Caption.Trim(), "\\d日")
                                || drArr[0].Table.Columns[i].Caption.Trim().Equals("总计"))
                            {
                                if (!drOri[i].ToString().Equals(""))
                                {
                                    double currentValue = (double)drOri[i];
                                    currentValue = Math.Round(currentValue * 100, 2);
                                    dr[i] = "<font color=\"" + (currentValue >= 1 ? "red" : "green") + "\" >" + currentValue.ToString().Trim() + "%</font>";
                                }
                                else
                                {
                                    dr[i] = "--";
                                }
                            }
                            else
                            {
                                double currentValue = (double)drOri[i];
                                dr[i] = Math.Round(currentValue * 100, 2).ToString() + "%";
                            }
                            break;
                    }
                }
                else
                {
                    dr[i] = drOri[i].ToString();
                }
            }
            dr["代码"] = "<a href=\"show_K_line_day.aspx?gid=" + dr["代码"].ToString() + "\" target=\"_blank\" >" + dr["代码"].ToString() + "</a>";
            dt.Rows.Add(dr);
        }
        AddTotal(drArr, dt);
        return dt;
    }

    public static DataTable GetData(DateTime currentDate)
    {
        currentDate = Util.GetDay(currentDate);
        DataTable dtOri = new DataTable();
        SqlDataAdapter da = new SqlDataAdapter(" select * from alert_kdj where alert_type = '1hr' and alert_time  >= '" + currentDate.ToShortDateString() + " 14:00'and  alert_time <= '" + currentDate.ToShortDateString() + " 16:00' ", Util.conStr);
        da.Fill(dtOri);

        DataTable dt = new DataTable();
        dt.Columns.Add("代码", Type.GetType("System.String"));
        dt.Columns.Add("名称", Type.GetType("System.String"));
        dt.Columns.Add("信号", Type.GetType("System.String"));
        dt.Columns.Add("今收", Type.GetType("System.Double"));
        dt.Columns.Add("明开", Type.GetType("System.Double"));
        dt.Columns.Add("明收", Type.GetType("System.Double"));
        dt.Columns.Add("明涨", Type.GetType("System.Double"));
        dt.Columns.Add("时间", Type.GetType("System.String"));
        dt.Columns.Add("放量", Type.GetType("System.Double"));
        dt.Columns.Add("KDJ", Type.GetType("System.Int32"));
        dt.Columns.Add("KDJ率", Type.GetType("System.Double"));
        dt.Columns.Add("MACD", Type.GetType("System.Int32"));
        dt.Columns.Add("MACD率", Type.GetType("System.Double"));
        dt.Columns.Add("TD", Type.GetType("System.Int32"));
        dt.Columns.Add("3线日", Type.GetType("System.Int32"));
        dt.Columns.Add("3线", Type.GetType("System.Double"));
        dt.Columns.Add("低点", Type.GetType("System.Double"));
        dt.Columns.Add("F1", Type.GetType("System.Double"));
        dt.Columns.Add("F3", Type.GetType("System.Double"));
        dt.Columns.Add("F5", Type.GetType("System.Double"));
        dt.Columns.Add("高点", Type.GetType("System.Double"));
        dt.Columns.Add("买入", Type.GetType("System.Double"));
        dt.Columns.Add("综指", Type.GetType("System.Double"));
        dt.Columns.Add("涨幅", Type.GetType("System.Double"));
        dt.Columns.Add("跌幅", Type.GetType("System.Double"));
        dt.Columns.Add("震幅", Type.GetType("System.Double"));
        for (int i = 1; i <= 5; i++)
        {
            dt.Columns.Add(i.ToString() + "日", Type.GetType("System.Double"));
        }
        dt.Columns.Add("总计", Type.GetType("System.Double"));

        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock stock = new Stock(drOri["gid"].ToString().Trim());
            stock.LoadKLineDay();
            stock.kLineHour = KLine.GetLocalKLine(stock.gid.Trim(), "1hr");
            KLine.ComputeMACD(stock.kLineDay);
            KLine.ComputeRSV(stock.kLineDay);
            KLine.ComputeKDJ(stock.kLineDay);
            KLine.ComputeRSV(stock.kLineHour);
            KLine.ComputeKDJ(stock.kLineHour);

            bool isShit = false;
            bool currentDateIsBeforeToday = Util.GetDay(currentDate) < Util.GetDay(stock.kLineDay[stock.kLineDay.Length - 1].endDateTime);
            DateTime currentHour = DateTime.Parse(drOri["alert_time"].ToString());

            int currentHourIndex = Stock.GetItemIndex(stock.kLineHour, DateTime.Parse(currentHour.ToShortDateString() + " " + currentHour.Hour.ToString() + ":00"));

            if (currentHourIndex == -1)
                continue;



            if (!StockWatcher.IsKdjFolk(stock.kLineHour, currentHourIndex))
            {
                isShit = true;
            }


            int currentIndex = stock.GetItemIndex(currentDate);
            if (currentIndex < 1)
                continue;
            DataRow dr = dt.NewRow();

            dr["代码"] = stock.gid.Trim();
            dr["名称"] = stock.Name.Trim();
            dr["时间"] = stock.kLineHour[currentHourIndex].endDateTime.ToShortTimeString();
            double settlePrice = settlePrice = stock.kLineDay[currentIndex].endPrice;
            dr["今收"] = settlePrice;
            if (currentDateIsBeforeToday)
            {
                currentIndex++;
                double openPrice = stock.kLineDay[currentIndex].startPrice;
                double currentPrice = stock.kLineDay[currentIndex].endPrice;

                dr["明开"] = openPrice;
                dr["明收"] = currentPrice;
                int macdDays = stock.macdDays(currentIndex);
                dr["MACD"] = macdDays;
                dr["TD"] = currentIndex - 1 - KLine.GetLastDeMarkBuyPointIndex(stock.kLineDay, currentIndex - 1);
                dr["明涨"] = (stock.kLineDay[currentIndex].highestPrice - settlePrice) / settlePrice;
                DateTime lastDate = DateTime.Parse(stock.kLineDay[currentIndex - 2].startDateTime.ToShortDateString());
                DateTime curDate =  DateTime.Parse(stock.kLineDay[currentIndex - 1].startDateTime.ToShortDateString());
                double lastDayVolume = Stock.GetVolumeAndAmount(stock.gid, lastDate)[0];
                double currentVolume = Stock.GetVolumeAndAmount(stock.gid, curDate)[0];
                double volumeIncrease = (currentVolume - lastDayVolume) / lastDayVolume;
                dr["放量"] = currentVolume / lastDayVolume;
                int kdjDays = stock.kdjDays(currentIndex);
                dr["kdj"] = kdjDays.ToString();
                int days3Line = KLine.Above3LineDays(stock, currentIndex);
                dr["3线日"] = days3Line;
                dr["3线"] = stock.GetAverageSettlePrice(currentIndex, 3, 3);
                //double buyPrice = stock.kLineDay[currentIndex].endPrice;
                double buyPrice = settlePrice;
                double lowestPrice = stock.LowestPrice(currentDate, 20);
                double highestPrice = stock.HighestPrice(currentDate, 40);
                double f1 = lowestPrice + (highestPrice - lowestPrice) * 0.236;
                double f3 = lowestPrice + (highestPrice - lowestPrice) * 0.382;
                double f5 = lowestPrice + (highestPrice - lowestPrice) * 0.618;
                dr["低点"] = lowestPrice;
                dr["F1"] = f1;
                dr["F3"] = f3;
                dr["F5"] = f5;
                dr["高点"] = highestPrice;
                dr["买入"] = buyPrice;
                double macdDegree = KLine.ComputeMacdDegree(stock.kLineDay, currentIndex) * 100;
                dr["MACD率"] = macdDegree;
                double kdjDegree = KLine.ComputeKdjDegree(stock.kLineDay, currentIndex);
                dr["KDJ率"] = kdjDegree;
                double maxPrice = 0;
                for (int i = 0; i < 5; i++)
                {
                    if (currentIndex + i >= stock.kLineDay.Length)
                        break;
                    double highPrice = stock.kLineDay[currentIndex + i].highestPrice;
                    maxPrice = Math.Max(maxPrice, highPrice);
                    dr[(i+1).ToString() + "日"] = (highPrice - buyPrice) / buyPrice;
                }
                dr["总计"] = (maxPrice - buyPrice) / buyPrice;

                if (macdDegree < 0.1 || kdjDays == -1)
                {
                    //dr["信号"] = "💩";
                }

                double upSpace = 0;
                double downSpace = 0;

                if (buyPrice <= lowestPrice)
                {
                    downSpace = 0.1;
                    upSpace = (lowestPrice - buyPrice) / buyPrice;
                }
                else if (buyPrice <= f1)
                {
                    downSpace = (buyPrice - lowestPrice) / buyPrice;
                    upSpace = (f1 - buyPrice) / buyPrice;
                }
                else if (buyPrice <= f3)
                {
                    downSpace = (buyPrice - f1) / buyPrice;
                    upSpace = (f3 - buyPrice) / buyPrice;
                }
                else if (buyPrice <= f5)
                {
                    downSpace = (buyPrice - f3) / buyPrice;
                    upSpace = (f5 - buyPrice) / buyPrice;
                }
                else if (buyPrice <= highestPrice)
                {
                    downSpace = (buyPrice - f5) / buyPrice;
                    upSpace = (highestPrice - buyPrice) / buyPrice;
                }
                else
                {
                    upSpace = 0.1;
                    downSpace = (buyPrice - highestPrice) / buyPrice;
                }

                dr["涨幅"] = upSpace;
                dr["跌幅"] = downSpace;
                dr["震幅"] = upSpace + downSpace;
                double totalScore = 0;
                if (kdjDays > -1 && macdDegree > 0 && days3Line > -1)
                {
                    totalScore = 1000 - kdjDays * 100 - days3Line * 50
                        + macdDegree + kdjDegree - Math.Abs(volumeIncrease) * 100;

                    //double dayDiv = (double)kdjDays + (double)days3Line*0.75;
                    //dayDiv = ((dayDiv==0) ? 0.75 : dayDiv);
                    //totalScore = (macdDegree + kdjDegree)/dayDiv;


                }


                totalScore = Math.Round(totalScore, 2);

                dr["综指"] = totalScore;

                if (currentPrice <= buyPrice * 1.005)
                {
                    //dr["信号"] = dr["信号"].ToString().Trim() + "🛍️";
                }

                if (kdjDays >= 0 && kdjDays <= 1 && (int)dr["TD"] <= 4)
                {
                    //dr["信号"] = dr["信号"].ToString().Trim() + "📈";
                }

                if (kdjDays < 0)
                {
                    //dr["信号"] = "💩";
                }
            }
            //if (totalScore !=0 && (stock.kLineDay[currentIndex].highestPrice - settlePrice) / settlePrice < 0.07 )
            if (isShit)
                dr["信号"] = "💩";
            dt.Rows.Add(dr);
        }


        return dt;
    }

    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {
        dg.DataSource = GetData();
        dg.DataBind();
    }

    protected void dg_SortCommand(object source, DataGridSortCommandEventArgs e)
    {
        Response.Write(e.SortExpression);
        sort = e.SortExpression.Replace("|", " ");
        string columnName = sort.Split(' ')[0].Trim();
        string sortSqu = sort.Split(' ')[1].Trim();
        for (int i = 0; i < dg.Columns.Count; i++)
        {
            if (dg.Columns[i].SortExpression.StartsWith(columnName))
            {
                dg.Columns[i].SortExpression = columnName.Trim() + "|" + (sortSqu.Trim().Equals("asc")? "desc":"asc");
            }
        }
        dg.DataSource = GetData();
        dg.DataBind();
    }

    public static void PageWatcher()
    {
        for (; true;)
        {
            if (Util.IsTransacDay(DateTime.Parse(DateTime.Now.ToShortDateString())) && Util.IsTransacTime(DateTime.Now))
            {
                DataTable dt = GetData(Util.GetDay(DateTime.Now));
                foreach (DataRow dr in dt.Rows)
                {
                    if ((double)dr["放量"] >= 1 && dr["信号"].ToString().IndexOf("📈") >= 0 && dr["信号"].ToString().IndexOf("🛍️") >= 0 && dr["信号"].ToString().IndexOf("💩") < 0)
                    {
                        string gid = dr["代码"].ToString().Trim();
                        Stock s = new Stock(gid);
                        KLine.RefreshKLine(gid, DateTime.Parse(DateTime.Now.ToShortDateString()));
                        double volumeIncrease = Math.Round(100 * double.Parse(dr["放量"].ToString().Trim()), 2);
                        string message = "放量：" + volumeIncrease.ToString() + "%，KDJ：" + dr["KDJ"].ToString().Trim() + "，买入："
                            + Math.Round((double)dr["买入"], 2).ToString() + "，现价：" + Math.Round((double)dr["明收"], 2)
                            + "，F3：" + Math.Round((double)dr["F3"], 2).ToString() + "，F5：" + Math.Round((double)dr["F5"], 2).ToString();
                        if (StockWatcher.AddAlert(Util.GetDay(DateTime.Now), gid, "macd", s.Name.Trim(), message))
                        {
                            StockWatcher.SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", s.gid.Trim(), s.Name + " " + message, Math.Round((double)dr["明收"], 2), "macd");
                        }
                    }
                }
            }
            Thread.Sleep(60000);
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
                    <asp:BoundColumn DataField="信号" HeaderText="信号" SortExpression="信号|desc" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="今收" HeaderText="今收"></asp:BoundColumn>
                    <asp:BoundColumn DataField="明开" HeaderText="明开"></asp:BoundColumn>
                    <asp:BoundColumn DataField="明收" HeaderText="明收"></asp:BoundColumn>
                    <asp:BoundColumn DataField="时间" HeaderText="时间" SortExpression="时间|desc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="放量" HeaderText="放量" SortExpression="放量|desc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="KDJ" HeaderText="KDJ" SortExpression="KDJ|desc"></asp:BoundColumn>
					<asp:BoundColumn DataField="KDJ率" HeaderText="KDJ率" SortExpression="KDJ率|asc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="MACD" HeaderText="MACD" SortExpression="MACD|desc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="MACD率" HeaderText="MACD率" SortExpression="MACD率|asc"></asp:BoundColumn>
					<asp:BoundColumn DataField="3线日" HeaderText="3线日"></asp:BoundColumn>
					<asp:BoundColumn DataField="TD" HeaderText="TD" SortExpression="TD|desc" ></asp:BoundColumn>				
                    <asp:BoundColumn DataField="3线" HeaderText="3线"></asp:BoundColumn>
                    <asp:BoundColumn DataField="低点" HeaderText="低点"></asp:BoundColumn>
                    <asp:BoundColumn DataField="F1" HeaderText="F1"></asp:BoundColumn>
                    <asp:BoundColumn DataField="F3" HeaderText="F3"></asp:BoundColumn>
                    <asp:BoundColumn DataField="F5" HeaderText="F5"></asp:BoundColumn>
                    <asp:BoundColumn DataField="高点" HeaderText="高点"></asp:BoundColumn>
                    <asp:BoundColumn DataField="买入" HeaderText="买入"  ></asp:BoundColumn>
			        <asp:BoundColumn DataField="涨幅" HeaderText="涨幅"  ></asp:BoundColumn>
					<asp:BoundColumn DataField="跌幅" HeaderText="跌幅"  ></asp:BoundColumn>
                    <asp:BoundColumn DataField="震幅" HeaderText="震幅"  ></asp:BoundColumn>
                    <asp:BoundColumn DataField="1日" HeaderText="1日" SortExpression="1日|desc" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="2日" HeaderText="2日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="3日" HeaderText="3日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="4日" HeaderText="4日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="5日" HeaderText="5日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="总计" HeaderText="总计" SortExpression="总计|desc" ></asp:BoundColumn>
                </Columns>
                <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
                <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
                <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
                <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
                <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
                </asp:DataGrid></td>
            </tr>
            <tr>
                <td><%=sort %></td>
            </tr>
        </table>
    </div>
    </form>
</body>
</html>
