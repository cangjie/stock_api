<%@ Page Language="C#" %>
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

        //for (DateTime startDate = DateTime.Parse("2018-1-10"); startDate >= DateTime.Parse("2018-1-10"); startDate = startDate.AddDays(-1))
        //{
        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", DateTime.Now.ToShortDateString()));

        if (Util.IsTransacDay(startDate))
        {
            for (int i = 10; i >= 3; i--)
            {
                LogAbove3LineForDays(startDate, i);
            }
        }
        //}

        Response.End();

        sort = Util.GetSafeRequestValue(Request, "sort", "3线日 desc,MACD,KDJ,综指 desc");
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
                    //tQ.Start();
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
        DataTable dtOri = GetData(currentDate, int.Parse(Util.GetSafeRequestValue(Request, "days", "10")));
        DataRow[] drOriArr = dtOri.Select(Util.GetSafeRequestValue(Request, "whereclause", "   ").Trim(), sort);
        return RenderHtml(drOriArr);
    }

    public void AddTotal(DataRow[] drOriArr, DataTable dt)
    {
        int totalCount = 0;
        int[] totalSum = new int[] { 0, 0, 0, 0, 0, 0,0,0,0,0,0 };

        int raiseCount = 0;
        int[] raiseSum = new int[] { 0, 0, 0, 0, 0, 0,0,0,0,0,0 };

        int fireCount = 0;
        int[] fireSum = new int[] { 0, 0, 0, 0, 0, 0,0,0,0,0,0 };

        int starCount = 0;
        int[] starSum = new int[] { 0, 0, 0, 0, 0, 0,0,0,0,0,0 };

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
                for (int i = 1; i < 12; i++)
                {
                    string colName = ((i == 11) ? "总计" : i.ToString() + "日");
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
        drTotal["昨收"] = totalCount.ToString();

        DataRow drShit = dt.NewRow();
        drShit["信号"] = "💩";
        drShit["昨收"] = shitCount.ToString();
        drShit["今开"] = Math.Round(100 * (double)shitCount / (double)drOriArr.Length, 2).ToString() + "%";

        DataRow drRaise = dt.NewRow();
        drRaise["名称"] = "双金叉";
        drRaise["信号"] = "📈";
        drRaise["昨收"] = raiseCount.ToString();
        DataRow drFire = dt.NewRow();
        drFire["名称"] = "缺口";
        drFire["信号"] = "🔥";
        drFire["昨收"] = fireCount.ToString();
        DataRow drStar = dt.NewRow();
        drStar["信号"] = "🌟";
        drStar["昨收"] = starCount.ToString();

        for (int i = 1; i < 12; i++)
        {
            string columeCaption = ((i == 11) ? "总计" : i.ToString() + "日");
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
            double settle = Math.Round((double)drOri["昨收"], 2);
            double currentPrice = Math.Round((double)drOri["今收"], 2);
            for (int i = 0; i < drArr[0].Table.Columns.Count; i++)
            {

                if (drArr[0].Table.Columns[i].DataType.FullName.ToString().Equals("System.Double"))
                {
                    switch (drArr[0].Table.Columns[i].Caption.Trim())
                    {
                        case "综指":
                        case "昨收":
                        case "MACD率":
                        case "KDJ率":
                            dr[i] = Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2).ToString();
                            break;
                        case "买入":
                            double buyPrice = Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2);
                            dr[i] = "<font color=\"" + ((buyPrice > currentPrice) ? "red" : ((buyPrice==currentPrice)? "gray" : "green")) + "\" >" + Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2).ToString() + "</font>";
                            break;
                        case "今开":
                        case "今收":
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

    public static DataTable GetData(DateTime currentDate, int days)
    {
        DateTime  break3LineDate = Util.GetLastTransactDate(currentDate, days);
        DataTable dtOri = new DataTable();
        SqlDataAdapter da = new SqlDataAdapter(" select *  from alert_above_3_line_for_days where alert_date = '" + currentDate.ToShortDateString()
            + "' and above_3_line_days >= 10 ", Util.conStr);
        da.Fill(dtOri);

        DataTable dt = new DataTable();
        dt.Columns.Add("代码", Type.GetType("System.String"));
        dt.Columns.Add("名称", Type.GetType("System.String"));
        dt.Columns.Add("信号", Type.GetType("System.String"));
        dt.Columns.Add("昨收", Type.GetType("System.Double"));
        dt.Columns.Add("今开", Type.GetType("System.Double"));
        dt.Columns.Add("今收", Type.GetType("System.Double"));
        dt.Columns.Add("今涨", Type.GetType("System.Double"));
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
        for (int i = 1; i <= 10; i++)
        {
            dt.Columns.Add(i.ToString() + "日", Type.GetType("System.Double"));
        }
        dt.Columns.Add("总计", Type.GetType("System.Double"));

        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock stock = new Stock(drOri["gid"].ToString().Trim());
            stock.LoadKLineDay();
            int currentIndex = stock.GetItemIndex(currentDate);


            KLine.ComputeMACD(stock.kLineDay);
            KLine.ComputeRSV(stock.kLineDay);
            KLine.ComputeKDJ(stock.kLineDay);



            if (currentIndex < 1)
                continue;


            DataRow dr = dt.NewRow();

            dr["代码"] = stock.gid.Trim();
            dr["名称"] = stock.Name.Trim();
            double settlePrice = stock.kLineDay[currentIndex - 1].endPrice;
            double openPrice = stock.kLineDay[currentIndex].startPrice;
            double currentPrice = stock.kLineDay[currentIndex].endPrice;
            dr["昨收"] = settlePrice;
            dr["今开"] = openPrice;
            dr["今收"] = currentPrice;
            int macdDays = stock.macdDays(currentIndex);
            dr["MACD"] = macdDays;
            dr["TD"] = currentIndex - KLine.GetLastDeMarkBuyPointIndex(stock.kLineDay, currentIndex);
            dr["今涨"] = (stock.kLineDay[currentIndex].startPrice - settlePrice) / settlePrice;

            DateTime lastDate = DateTime.Parse(stock.kLineDay[currentIndex - 1].startDateTime.ToShortDateString());
            double lastDayVolume = Stock.GetVolumeAndAmount(stock.gid, lastDate)[0];
            double currentVolume = Stock.GetVolumeAndAmount(stock.gid, currentDate)[0];
            double volumeIncrease = (currentVolume - lastDayVolume) / lastDayVolume;
            dr["放量"] = currentVolume / lastDayVolume;
            int kdjDays = stock.kdjDays(currentIndex);
            dr["kdj"] = kdjDays.ToString();

            int days3Line = KLine.Above3LineDays(stock, currentIndex);
            dr["3线日"] = int.Parse(drOri["above_3_line_days"].ToString());
            dr["3线"] = stock.GetAverageSettlePrice(currentIndex, 3, 3);
            double buyPrice = stock.kLineDay[currentIndex].startPrice;
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
            double macdDegree = KLine.ComputeMacdDegree(stock.kLineDay, currentIndex-macdDays)*100;
            dr["MACD率"] = macdDegree;
            double kdjDegree = KLine.ComputeKdjDegree(stock.kLineDay, currentIndex);
            dr["KDJ率"] = kdjDegree;
            double maxPrice = 0;
            for (int i = 1; i <= 10; i++)
            {
                if (currentIndex + i >= stock.kLineDay.Length)
                    break;
                double highPrice = stock.kLineDay[currentIndex + i].highestPrice;
                maxPrice = Math.Max(maxPrice, highPrice);
                dr[i.ToString() + "日"] = (highPrice - buyPrice) / buyPrice;
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
            double totalScore = macdDegree + kdjDegree;



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

            if (stock.kLineDay[currentIndex].endPrice > stock.kLineDay[currentIndex].startPrice && (double)dr["放量"] >= 1.5
                && (stock.kLineDay[currentIndex].highestPrice - stock.kLineDay[currentIndex].endPrice) / (stock.kLineDay[currentIndex].endPrice - stock.kLineDay[currentIndex].startPrice) < 0.1 )
            {
                //dr["信号"] = "📈";
            }
            if (stock.kLineDay[currentIndex].lowestPrice > stock.kLineDay[currentIndex - 1].highestPrice )
            {
                dr["信号"] = "🔥";
            }
            highestPrice = KLine.GetHighestPrice(stock.kLineDay, currentIndex - 1, 40);
            if (kdjDays >= 0 && macdDays >= 0)
            {
                dr["信号"] = dr["信号"].ToString() + "📈";
            }
            //if (totalScore !=0 && (stock.kLineDay[currentIndex].highestPrice - settlePrice) / settlePrice < 0.07 )
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


    public static void LogAbove3LineForDays(DateTime currentDate, int days)
    {
        
        DateTime  break3LineDate = Util.GetLastTransactDate(currentDate, days);
        if (DateTime.Now.Hour >= 16)
        {
            currentDate = currentDate.AddDays(1);
            break3LineDate = Util.GetLastTransactDate(currentDate, days);
        }
        currentDate = currentDate.AddDays(-1);
        DataTable dtOri = new DataTable();
        SqlDataAdapter da = new SqlDataAdapter(" select * from bottom_break_cross_3_line where suggest_date = '" + break3LineDate.ToShortDateString() + "' " , Util.conStr);
        da.Fill(dtOri);
        da.Dispose();
        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock s = new Stock(drOri["gid"].ToString().Trim());
            s.kLineDay = Stock.LoadLocalKLineFromDB(s.gid, "day");
            s.kArr = s.kLineDay;
            int currentIndex = s.GetItemIndex(currentDate);
            int break3LineIndex = s.GetItemIndex(break3LineDate);

            bool isAlwaysAbove3Line = true;
            for (int i = 0; i < days; i++)
            {
                if (break3LineIndex + i < s.kLineDay.Length && s.kLineDay[break3LineIndex + i].endPrice < s.GetAverageSettlePrice(break3LineIndex + i, 3, 3))
                {
                    isAlwaysAbove3Line = false;
                    break;
                }
            }

            if (!isAlwaysAbove3Line)
                continue;
            try
            {
                DBHelper.InsertData("alert_above_3_line_for_days", new string[,] { {"alert_date", "datetime", currentDate.ToShortDateString() },
                    {"gid", "varchar", drOri["gid"].ToString().Trim() }, {"above_3_line_days", "int", days.ToString() } });
            }
            catch
            {

            }
        }
    }



    public static void PageWatcher()
    {
        if (Util.IsTransacDay(Util.GetDay(DateTime.Now)) && DateTime.Now.Hour == 9 && DateTime.Now.Minute >= 30  )
        {
            string[] gidArr = Util.GetAllGids();
            foreach (string gid in gidArr)
            {
                Stock stock = new Stock(gid);
                stock.LoadKLineDay();
                KLine.ComputeMACD(stock.kLineDay);
                KLine.ComputeRSV(stock.kLineDay);
                KLine.ComputeKDJ(stock.kLineDay);
                if (stock.kLineDay.Length > 0 && stock.kLineDay[stock.kLineDay.Length - 1].startDateTime.ToShortDateString().Equals(DateTime.Now.ToShortDateString()))
                {
                    int j = stock.kLineDay.Length - 1;
                    if (KLine.IsJumpHigh(stock.kLineDay, j))
                    {
                        int macdDays = stock.macdDays(j);
                        int kdjDays = stock.kdjDays(j);
                        try
                        {
                            DBHelper.InsertData("alert_jump_high", new string[,] { {"gid", "varhcar", stock.gid },
                                {"alert_time", "datetime", Util.GetDay(stock.kLineDay[j].endDateTime).ToShortDateString() },
                                {"alert_price", "float", stock.kLineDay[j].startPrice.ToString() },
                                {"settle", "float", stock.kLineDay[j - 1].endPrice.ToString() },
                                {"macd_days", "int", macdDays.ToString() },
                                {"kdj_days", "int", kdjDays.ToString() } });
                        }
                        catch
                        {

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
                    <asp:BoundColumn DataField="综指" HeaderText="综指" SortExpression="综指|desc" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="今涨" HeaderText="今涨" SortExpression="今涨|desc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="放量" HeaderText="放量" SortExpression="放量|desc"></asp:BoundColumn>

                    <asp:BoundColumn DataField="KDJ" HeaderText="KDJ" SortExpression="KDJ|desc"></asp:BoundColumn>
					
                    <asp:BoundColumn DataField="MACD" HeaderText="MACD" SortExpression="MACD|desc"></asp:BoundColumn>
                    
					<asp:BoundColumn DataField="3线日" HeaderText="3线日"></asp:BoundColumn>
					<asp:BoundColumn DataField="TD" HeaderText="TD" SortExpression="TD|desc" ></asp:BoundColumn>	
                    <asp:BoundColumn DataField="KDJ率" HeaderText="KDJ率" SortExpression="KDJ率|asc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="MACD率" HeaderText="MACD率" SortExpression="MACD率|asc"></asp:BoundColumn>			

                    <asp:BoundColumn DataField="F3" HeaderText="F3"></asp:BoundColumn>
                    <asp:BoundColumn DataField="F5" HeaderText="F5"></asp:BoundColumn>
                    <asp:BoundColumn DataField="买入" HeaderText="买入"  ></asp:BoundColumn>
			        <asp:BoundColumn DataField="涨幅" HeaderText="涨幅"  ></asp:BoundColumn>
					<asp:BoundColumn DataField="跌幅" HeaderText="跌幅"  ></asp:BoundColumn>
                    <asp:BoundColumn DataField="震幅" HeaderText="震幅"  ></asp:BoundColumn>
                    <asp:BoundColumn DataField="1日" HeaderText="1日" SortExpression="1日|desc" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="2日" HeaderText="2日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="3日" HeaderText="3日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="4日" HeaderText="4日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="5日" HeaderText="5日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="6日" HeaderText="6日" SortExpression="1日|desc" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="7日" HeaderText="7日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="8日" HeaderText="8日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="9日" HeaderText="9日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="10日" HeaderText="10日"></asp:BoundColumn>
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
