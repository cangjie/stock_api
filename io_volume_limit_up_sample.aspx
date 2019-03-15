<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Threading" %>
<!DOCTYPE html>

<script runat="server">

    public DateTime currentDate = Util.GetDay(DateTime.Now);

    public string sort = "缩量";

    public static ThreadStart tsQ = new ThreadStart(StockWatcher.LogQuota);

    public static Thread tQ = new Thread(tsQ);

    public static ThreadStart ts = new ThreadStart(PageWatcher);

    public static Thread t = new Thread(ts);

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    public static double times = 3;

    protected void Page_Load(object sender, EventArgs e)
    {
        sort = Util.GetSafeRequestValue(Request, "sort", "增量 desc");
        times = double.Parse(Util.GetSafeRequestValue(Request, "times", "1.1"));
        if (!IsPostBack)
        {
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

            try
            {
                if (t.ThreadState != ThreadState.Running && t.ThreadState != ThreadState.WaitSleepJoin)
                {
                    t.Abort();
                    t = new Thread(ts);
                    //t.Start();

                }
            }
            catch
            {

            }


            DataTable dt = GetData();
            dg.DataSource = dt;
            dg.DataBind();
        }


    }

    public DataTable GetData()
    {
        if (calendar.SelectedDate.Year < 2000)
            currentDate = Util.GetDay(DateTime.Now);
        else
            currentDate = Util.GetDay(calendar.SelectedDate);
        DataTable dtOri = GetData(currentDate, double.Parse(Util.GetSafeRequestValue(Request, "rate", "0.01")));
        string filter = Util.GetSafeRequestValue(Request, "filter", "");
        /*
        if (Util.GetSafeRequestValue(Request, "goldcross", "0").Trim().Equals("0"))
        {
            filter = "";
        }
        else
        {
            filter = " (KDJ日 >= 0 and MACD日 >= 0)";
        }
        */
        //return RenderHtml(dtOri.Select(" 信号 like '%📈%' ", sort));
        return RenderHtml(dtOri.Select(filter, sort));
    }

    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {
        currentDate = Util.GetDay(calendar.SelectedDate);
        DataTable dt = GetData();
        dg.DataSource = dt;
        dg.DataBind();
    }

    protected void dg_SortCommand(object source, DataGridSortCommandEventArgs e)
    {
        sort = e.SortExpression.Replace("|", " ") + ", " + sort;
        string columnName = e.SortExpression.Split('|')[0].Trim();
        string sortSqu = e.SortExpression.Split('|')[1].Trim();
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
            //double settle = Math.Round((double)drOri["昨收"], 2);
            double currentPrice = Math.Round((double)drOri["现价"], 2);
            double lowPrice = Math.Round((double)drOri["前低"], 2);
            double hightPrice =  Math.Round((double)drOri["现高"], 2);
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
                            dr[i] = "<font color=\"" + ((buyPrice > currentPrice) ? "red" : ((buyPrice == currentPrice) ? "gray" : "green")) + "\" >" + Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2).ToString() + "</font>";
                            break;
                        case "F3":
                        case "F5":
                            double currentValuePrice2 = (double)drOri[i];
                            if (drOri["类型"].ToString().Trim().Equals(drArr[0].Table.Columns[i].Caption.Trim()))
                            {
                                dr[i] = "<font color=\"red\"  >"
                                + Math.Round(currentValuePrice2, 2).ToString() + "</font>";
                            }
                            else
                            {
                                dr[i] = "<font color=\"green\"  >"
                                + Math.Round(currentValuePrice2, 2).ToString() + "</font>";
                            }

                            break;
                        case "今开":
                        case "现价":
                        case "前低":
                        case "F1":
                        case "现高":
                        case "3线":
                        case "无影":

                            double currentValuePrice = (double)drOri[i];
                            dr[i] = "<font color=\"" + (currentValuePrice > currentPrice ? "red" : (currentValuePrice == currentPrice ? "gray" : "green")) + "\"  >"
                                + Math.Round(currentValuePrice, 2).ToString() + "</font>";
                            break;
                        case "价差":
                        case "盘比":
                            double currentValuePrice1 = (double)drOri[i];
                            dr[i] = Math.Round(currentValuePrice1, 2).ToString();
                            break;
                        case "幅度":
                        case "总换手":
                            dr[i] = drOri[i].ToString() + "%";
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
                else if (drArr[0].Table.Columns[i].DataType.FullName.ToString().Equals("System.DateTime"))
                {
                    DateTime footTime = (DateTime)drOri[i];
                    dr[i] = footTime.Hour.ToString() + ":" + footTime.Minute.ToString();
                }
                else
                {
                    dr[i] = drOri[i].ToString();
                }
            }
            string gid = dr["代码"].ToString();
            dr["代码"] = "<a href=\"show_K_line_day.aspx?gid=" + dr["代码"].ToString() + "&maxprice=" + hightPrice.ToString() + "&minprice=" + lowPrice.ToString() + "\" target=\"_blank\" >" + dr["代码"].ToString() + "</a>";
            dr["名称"] = "<a href=\"io_volume_detail.aspx?gid=" + gid.Trim() + "&date=" + calendar.SelectedDate.ToShortDateString() + "\" target=\"_blank\" >" + dr["名称"].ToString() + "</a>";

            dt.Rows.Add(dr);
        }
        AddTotal(drArr, dt);
        return dt;
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
        drTotal["信号"] = "总计";
        drTotal["MACD日"] = totalCount.ToString();

        DataRow drShit = dt.NewRow();
        drShit["信号"] = "💩";
        drShit["MACD日"] = shitCount.ToString();
        drShit["KDJ日"] = Math.Round(100 * (double)shitCount / (double)drOriArr.Length, 2).ToString() + "%";

        DataRow drRaise = dt.NewRow();
        drRaise["信号"] = "📈";
        drRaise["MACD日"] = raiseCount.ToString();
        DataRow drFire = dt.NewRow();
        drFire["信号"] = "🔥";
        drFire["MACD日"] = fireCount.ToString();
        DataRow drStar = dt.NewRow();
        drStar["信号"] = "🌟";
        drStar["MACD日"] = starCount.ToString();

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

    public static DataTable GetData(DateTime currentDate, double increaseRate)
    {
        currentDate = Util.GetDay(currentDate);
        DataTable dt = new DataTable();
        dt.Columns.Add("代码", Type.GetType("System.String"));
        dt.Columns.Add("名称", Type.GetType("System.String"));
        dt.Columns.Add("信号", Type.GetType("System.String"));
        dt.Columns.Add("缩量", Type.GetType("System.Double"));
        dt.Columns.Add("调整", Type.GetType("System.Int32"));
        dt.Columns.Add("现高", Type.GetType("System.Double"));
        dt.Columns.Add("F3", Type.GetType("System.Double"));
        dt.Columns.Add("F5", Type.GetType("System.Double"));
        dt.Columns.Add("前低", Type.GetType("System.Double"));
        dt.Columns.Add("幅度", Type.GetType("System.Double"));
        dt.Columns.Add("3线", Type.GetType("System.Double"));
        dt.Columns.Add("现价", Type.GetType("System.Double"));
        dt.Columns.Add("评级", Type.GetType("System.String"));
        dt.Columns.Add("盘比", Type.GetType("System.Double"));
        dt.Columns.Add("买入", Type.GetType("System.Double"));
        dt.Columns.Add("始盘比", Type.GetType("System.Double"));
        dt.Columns.Add("终盘比", Type.GetType("System.Double"));
        dt.Columns.Add("增量", Type.GetType("System.Double"));
        dt.Columns.Add("KDJ日", Type.GetType("System.Int32"));
        dt.Columns.Add("MACD日", Type.GetType("System.Int32"));
        dt.Columns.Add("F3折返", Type.GetType("System.Double"));
        dt.Columns.Add("无影时", Type.GetType("System.DateTime"));
        dt.Columns.Add("无影", Type.GetType("System.Double"));
        dt.Columns.Add("价差", Type.GetType("System.Double"));
        dt.Columns.Add("价差abs", Type.GetType("System.Double"));
        dt.Columns.Add("类型", Type.GetType("System.String"));
        dt.Columns.Add("总换手", Type.GetType("System.Double"));
        dt.Columns.Add("KDJ60", Type.GetType("System.Int32"));
        dt.Columns.Add("KDJ30", Type.GetType("System.Int32"));


        for (int i = 0; i <= 5; i++)
        {
            dt.Columns.Add(i.ToString() + "日", Type.GetType("System.Double"));
        }
        dt.Columns.Add("总计", Type.GetType("System.Double"));
        if (!Util.IsTransacDay(currentDate))
        {
            return dt;
        }

        //DateTime lastTransactDate = Util.GetLastTransactDate(currentDate, 1);
        //DateTime limitUpStartDate = Util.GetLastTransactDate(lastTransactDate, 10);
        DateTime startLimitupDate = Util.GetLastTransactDate(currentDate, 5);

        DataTable dtDtl = DBHelper.GetDataTable(" select gid, alert_date, price from alert_foot where alert_date > '"
            + currentDate.ToShortDateString() + "' and alert_date < '" + currentDate.AddDays(1).ToShortDateString() + "'  order by alert_date desc ");

        DataTable dtOri = DBHelper.GetDataTable(" select gid, alert_date from limit_up where alert_date >= '" + startLimitupDate.ToShortDateString()
            + "' and alert_date < '" + currentDate.ToShortDateString() + "' order by alert_date desc ");
        DataTable dtIOVolume = DBHelper.GetDataTable(" select  distinct gid from io_volume where in_volume > 0 and out_volume / in_volume >= " + times.ToString()
            + " and trans_date_time > '" + currentDate.ToShortDateString() + "' and trans_date_time < '" + currentDate.ToShortDateString() + " 23:00' "
            + " and (out_volume > 1000000 or in_volume >  1000000) ");

        DataTable dtMonthGold = DBHelper.GetDataTable(" select * from  alert_month_k_line_gold  where alert_date = '" + Util.GetLastTransactDate(currentDate, 1).ToShortDateString() + "' ");

        DataTable dtWeekGold = DBHelper.GetDataTable(" select * from  alert_week_k_line_gold  where alert_date = '" + Util.GetLastTransactDate(currentDate, 1).ToShortDateString() + "' ");


        //Core.RedisClient rc = new Core.RedisClient("127.0.0.1");
        foreach (DataRow drOri in dtIOVolume.Rows)
        {

            Stock stock = new Stock(drOri["gid"].ToString().Trim(), rc);
            stock.LoadKLineDay(rc);
            KLine.ComputeMACD(stock.kLineDay);
            KLine.ComputeRSV(stock.kLineDay);
            KLine.ComputeKDJ(stock.kLineDay);


            KLine[] kArrHour = Stock.LoadRedisKLine(stock.gid, "60min", rc);
            KLine[] kArrHalfHour = Stock.LoadRedisKLine(stock.gid, "30min", rc);
            DateTime currentHalfHourTime = Stock.GetCurrentKLineEndDateTime(currentDate, 30);
            DateTime currentHourTime = Stock.GetCurrentKLineEndDateTime(currentDate, 60);
            int currentIndexHour = Stock.GetItemIndex(kArrHour, currentHourTime);
            int currentIndexHalfHour = Stock.GetItemIndex(kArrHalfHour, currentHalfHourTime);
            KLine.ComputeRSV(kArrHour);
            KLine.ComputeKDJ(kArrHour);
            KLine.ComputeRSV(kArrHalfHour);
            KLine.ComputeKDJ(kArrHalfHour);

            if (dtOri.Select(" gid = '" + stock.gid.Trim() + "'").Length == 0)
            {
                continue;
            }

            bool haveHourKdjCross = false;
            int kdjCrossHourIndex = 0;
            stock.kLineHour = Stock.LoadRedisKLine(stock.gid.Trim(), "60min", rc);
            if (stock.kLineHour == null || stock.kLineHour.Length == 0)
            {
                stock.kLineHour = Stock.LoadLocalKLineFromDB(stock.gid.Trim(), "60min");
            }
            KLine.ComputeMACD(stock.kLineHour);
            KLine.ComputeRSV(stock.kLineHour);
            KLine.ComputeKDJ(stock.kLineHour);
            int startHourIndex = 0;
            int endHourIndex = 0;
            double crossJHour = 0;
            for (int i = 0; i < stock.kLineHour.Length; i++)
            {
                if (stock.kLineHour[i].startDateTime > currentDate && startHourIndex == 0)
                {
                    startHourIndex = i;
                }
                if (stock.kLineHour[i].endDateTime < currentDate.AddDays(1))
                {
                    endHourIndex = i;
                }

                if (stock.kLineHour[i].startDateTime.Date == currentDate.Date)
                {
                    haveHourKdjCross = StockWatcher.IsKdjFolk(stock.kLineHour, i);
                    kdjCrossHourIndex = i;
                    if (haveHourKdjCross)
                    {
                        crossJHour = stock.kLineHour[i].j;
                        break;
                    }
                }
            }



            bool haveHalfHourKdjCross = false;
            int kdjCrossHalfHourIndex = 0;
            stock.kLineHalfHour = Stock.LoadRedisKLine(stock.gid.Trim(), "30min", rc);
            if (stock.kLineHalfHour == null || stock.kLineHalfHour.Length == 0)
            {
                stock.kLineHalfHour = Stock.LoadLocalKLineFromDB(stock.gid.Trim(), "30min");
            }
            KLine.ComputeMACD(stock.kLineHalfHour);
            KLine.ComputeRSV(stock.kLineHalfHour);
            KLine.ComputeKDJ(stock.kLineHalfHour);
            int startHalfHourIndex = 0;
            int endHalfHourIndex = 0;
            double crossJHalfHour = 0;
            for (int i = 0; i < stock.kLineHalfHour.Length; i++)
            {
                if (stock.kLineHalfHour[i].startDateTime > currentDate && startHalfHourIndex == 0)
                {
                    startHalfHourIndex = i;
                }
                if (stock.kLineHalfHour[i].endDateTime < currentDate.AddDays(1))
                {
                    endHalfHourIndex = i;
                }
                if (stock.kLineHalfHour[i].startDateTime.Date == currentDate.Date)
                {
                    haveHalfHourKdjCross = StockWatcher.IsKdjFolk(stock.kLineHalfHour, i);
                    kdjCrossHalfHourIndex = i;
                    if (haveHalfHourKdjCross)
                    {
                        crossJHalfHour = stock.kLineHalfHour[i].j;
                        break;
                    }
                }
            }



            int currentIndex = stock.GetItemIndex(currentDate);

            if (currentIndex < 0)
                continue;

            if ((stock.kLineDay[currentIndex].endPrice - stock.kLineDay[currentIndex - 1].endPrice) / stock.kLineDay[currentIndex - 1].endPrice < -0.095)
            {
                continue;
            }

            int limitUpIndex = stock.GetItemIndex(currentDate);
            int highIndex = 0;
            int lowestIndex = 0;
            double lowest = GetFirstLowestPrice(stock.kLineDay, limitUpIndex, out lowestIndex);
            double highest = 0;
            for (int i = limitUpIndex; i < currentIndex; i++)
            {
                if (highest < stock.kLineDay[i].highestPrice)
                {
                    highest = stock.kLineDay[i].highestPrice;
                    highIndex = i;
                }
            }


            double avarageVolume = 0;
            for (int i = lowestIndex; i < highIndex; i++)
            {
                avarageVolume = avarageVolume + stock.kLineDay[i].volume;
            }
            avarageVolume = (int)Math.Round((double)avarageVolume / (double)(highIndex - lowestIndex), 0);

            double totalVolume = 0;
            for (int i = lowestIndex; i < currentIndex; i++)
            {
                totalVolume += stock.kLineDay[i].volume;
            }

            double f3 = highest - (highest - lowest) * 0.382;
            double f5 = highest - (highest - lowest) * 0.618;
            double line3Price = KLine.GetAverageSettlePrice(stock.kLineDay, currentIndex, 3, 3);
            double currentPrice = stock.kLineDay[currentIndex].endPrice;
            double buyPrice = 0;
            if (stock.kLineDay[currentIndex].lowestPrice >= f3 * 0.99 && stock.kLineDay[currentIndex].lowestPrice <= f3 * 1.01)
            {
                buyPrice = Math.Max(f3, stock.kLineDay[currentIndex].lowestPrice);
            }
            else if (stock.kLineDay[currentIndex].lowestPrice <= f5 * 1.01 && stock.kLineDay[currentIndex].startPrice >= f5 * 1.01)
            {
                buyPrice = Math.Max(f5, stock.kLineDay[currentIndex].lowestPrice);
            }
            else
            {
                buyPrice = 0;
            }
            if (buyPrice == 0)
            {
                //continue;
            }

            double maxVolume = 0;
            for (int i = lowestIndex; i < currentIndex; i++)
            {
                maxVolume = Math.Max(maxVolume, stock.kLineDay[i].volume);
            }


            int tochSupportStatus = 0;
            for (int i = currentIndex - 1; i >= highIndex; i--)
            {
                switch (tochSupportStatus)
                {
                    case 0:
                        if (stock.kLineDay[i].lowestPrice > buyPrice * 1.01)
                        {
                            tochSupportStatus++;
                        }
                        else
                        {
                            tochSupportStatus = 2;
                        }
                        break;
                    case 1:
                        if (stock.kLineDay[i].lowestPrice < buyPrice * 1.01)
                        {
                            tochSupportStatus++;
                        }
                        break;
                }
                if (tochSupportStatus == 2)
                {
                    break;
                }
            }

            double width = Math.Round(100 * (highest - lowest) / lowest, 2);

            if (tochSupportStatus == 2 && width < 40)
            {
                //continue;
            }




            double todayLowestPrice = 0;
            double todayDisplayedLowestPrice = 0;
            DateTime footTime = DateTime.Now;



            double volumeToday = stock.kLineDay[currentIndex].VirtualVolume;

            double volumeYesterday = stock.kLineDay[limitUpIndex].volume;


            double volumeReduce = volumeToday / maxVolume;

            string memo = "";

            Core.Timeline[] timelineArray = Core.Timeline.LoadTimelineArrayFromRedis(stock.gid, currentDate, rc);

            if (timelineArray.Length == 0)
            {
                timelineArray = Core.Timeline.LoadTimelineArrayFromSqlServer(stock.gid, currentDate);
            }



            if (f3 >= line3Price)
            {
                memo = memo + "<br/>F3在3线之上";
            }
            if (stock.kLineDay[currentIndex].lowestPrice >= f3 * 0.995)
            {
                memo = memo + "<br/>折返在F3之上";
            }
            DataRow dr = dt.NewRow();
            dr["代码"] = stock.gid.Trim();
            dr["名称"] = stock.Name.Trim();
            dr["始盘比"] = 0;
            dr["终盘比"] = 0;
            dr["增量"] = 0;
            bool jumpEmpty = false;

            for (int i = highIndex + 1; i <= currentIndex; i++)
            {
                if ((stock.kLineDay[i - 1].startPrice > stock.kLineDay[i - 1].endPrice && stock.kLineDay[i].startPrice < stock.kLineDay[i - 1].endPrice)
                    || (stock.kLineDay[i - 1].endPrice > stock.kLineDay[i - 1].startPrice && stock.kLineDay[i].startPrice < stock.kLineDay[i - 1].startPrice))
                {
                    jumpEmpty = true;
                    break;
                }
            }
            dr["调整"] = currentIndex - limitUpIndex;
            dr["缩量"] = volumeReduce;
            dr["现高"] = highest;
            dr["F3"] = f3;
            dr["F5"] = f5;
            dr["前低"] = lowest;
            dr["幅度"] = width;//.ToString() + "%";


            double f3ReverseRate = (stock.kLineDay[currentIndex].lowestPrice - f3) / f3;
            double f5ReverseRate = (stock.kLineDay[currentIndex].lowestPrice - f5) / f5;
            double supportPrice = 0;
            if (Math.Abs(f3ReverseRate) > Math.Abs(f5ReverseRate))
            {
                dr["价差"] = stock.kLineDay[currentIndex].lowestPrice - f5;
                supportPrice = f5;
                dr["类型"] = "F5";

            }
            else
            {
                dr["价差"] = stock.kLineDay[currentIndex].lowestPrice - f3;
                supportPrice = f3;
                dr["类型"] = "F3";
            }
            dr["价差abs"] = Math.Abs((double)dr["价差"]);



            dr["F3折返"] = (stock.kLineDay[currentIndex].lowestPrice - f3) / f3;

            dr["3线"] = line3Price;
            dr["现价"] = currentPrice;

            dr["评级"] = memo;
            buyPrice = stock.kLineDay[currentIndex].endPrice;
            dr["买入"] = buyPrice;

            dr["KDJ日"] = stock.kdjDays(currentIndex);

            dr["MACD日"] = stock.macdDays(currentIndex);
            if ((int)dr["MACD日"] == -1)
            {
                continue;
            }
            dr["无影时"] = footTime;
            dr["无影"] = todayLowestPrice;
            double maxPrice = 0;
            dr["0日"] = (buyPrice - stock.kLineDay[currentIndex].startPrice) / stock.kLineDay[currentIndex].startPrice;

            DataTable dtIORate = DBHelper.GetDataTable(" select top 1 * from io_volume where gid = '" + stock.gid.Trim() + "' and trans_date_time > '" + currentDate.ToShortDateString() + "' "
                + " and trans_date_time < '" + currentDate.ToShortDateString() + " 23:59:59' order by  trans_date_time desc ");
            if (dtIORate.Rows.Count > 0)
            {
                try
                {

                    dr["盘比"] = (double)dtIORate.Rows[0]["out_volume"] / (double)dtIORate.Rows[0]["in_volume"];
                }
                catch
                {
                    dr["盘比"] = 0;
                }
            }
            else
            {
                dr["盘比"] = 0;
            }

            for (int i = 1; i <= 5; i++)
            {
                if (currentIndex + i >= stock.kLineDay.Length)
                    break;
                double highPrice = stock.kLineDay[currentIndex + i].highestPrice;
                maxPrice = Math.Max(maxPrice, highPrice);
                dr[i.ToString() + "日"] = (highPrice - buyPrice) / buyPrice;
            }
            dr["信号"] = "";
            if (haveHourKdjCross && (crossJHour < 40 || crossJHour > 70))
            {
                dr["信号"] = dr["信号"].ToString().Trim() + "🔥";
            }
            if (haveHalfHourKdjCross && (crossJHalfHour < 40 || crossJHalfHour > 70))
            {
                dr["信号"] = dr["信号"].ToString().Trim() + "📈";
            }

            if (dtMonthGold.Select(" gid = '" + stock.gid.Trim() + "'").Length > 0)
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"月双金叉\" >月</a>";
            }
            if (dtWeekGold.Select(" gid = '" + stock.gid.Trim() + "'").Length > 0)
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"周双金叉\" >周</a>";
            }

            dr["总计"] = (maxPrice - buyPrice) / buyPrice;
            double totalStockCount = stock.TotalStockCount(currentDate);
            if (totalStockCount > 0)
            {
                dr["总换手"] = Math.Round(100 * totalVolume / totalStockCount, 2);
            }
            else
            {
                dr["总换手"] = 0;
            }

            if (((double)dr["总换手"] > 10 && (double)dr["总换手"] < 90) || (double)dr["总换手"] > 110)
            {
                continue;
            }

            if ((double)dr["盘比"] < 1)
            {
                continue;
            }

            if ((double)dr["缩量"] > 1.5)
            {
                continue;
            }

            dr["KDJ30"] = Stock.KDJIndex(kArrHalfHour, currentIndexHalfHour);
            dr["KDJ60"] = Stock.KDJIndex(kArrHour, currentIndexHour);

            if ((int)dr["KDJ60"] >= 0 &&  kArrHour[currentIndexHour-(int)dr["KDJ60"]].j < 40)
            {
                dr["信号"] = "<a title='小时KDJ低位金叉' >🌟</a>" + dr["信号"].ToString().Trim();
            }

            dt.Rows.Add(dr);

        }
        //rc.Dispose();
        return dt;
    }


    public static double GetFirstLowestPrice1(KLine[] kArr, int index, out int lowestIndex)
    {
        double ret = double.MaxValue;
        lowestIndex = 0;
        for (int i = index; i > 0 ; i--)
        {
            if (i < kArr.Length - 1)
            {
                if (kArr[i].lowestPrice <= kArr[i + 1].lowestPrice && kArr[i].lowestPrice <= kArr[i - 1].lowestPrice)
                {
                    ret = kArr[i].lowestPrice;
                    lowestIndex = i;
                    break;
                }
            }
        }
        return ret;
    }


    public static double GetFirstLowestPrice(KLine[] kArr, int index, out int lowestIndex)
    {
        double ret = double.MaxValue;
        int find = 0;
        lowestIndex = 0;
        for (int i = index - 1; i > 0 && find < 2; i--)
        {
            double line3Pirce = KLine.GetAverageSettlePrice(kArr, i, 3, 3);
            ret = Math.Min(ret, kArr[i].lowestPrice);
            if (ret == kArr[i].lowestPrice)
            {
                lowestIndex = i;
            }
            if (kArr[i].endPrice < line3Pirce)
            {
                find = 1;
            }
            if (kArr[i].lowestPrice >= line3Pirce && find == 1)
            {
                find = 2;
            }
        }
        return ret;
    }



    public static void PageWatcher()
    {
        for(; true; )
        {
            DateTime currentDate = Util.GetDay(DateTime.Now);
            if (Util.IsTransacDay(currentDate) && Util.IsTransacTime(DateTime.Now))
            {
                DataTable dt = GetData(currentDate, 0.1);



                foreach (DataRow dr in dt.Rows)
                {
                    double high = Math.Round(double.Parse(dr["现高"].ToString()), 2);
                    double low = Math.Round(double.Parse(dr["前低"].ToString()), 2);
                    double price = Math.Round((double)dr["买入"], 2);
                    string message = "缩量：" + Math.Round(100 * (double)dr["缩量"], 2).ToString() + "% 幅度：" + Math.Round(100 * (high - low) / low, 2).ToString()
                        //+ "% MACD：" + dr["MACD日"].ToString() + " KDJ:" + dr["KDJ日"].ToString();
                        + "% 价差：" + Math.Round(double.Parse(dr["价差"].ToString().Trim()), 2).ToString().Trim() + " 支撑：" + dr["类型"].ToString().Trim();

                    if ((double)dr["价差abs"] <= 0.02 &&  StockWatcher.AddAlert(DateTime.Parse(DateTime.Now.ToShortDateString()),
                        dr["代码"].ToString().Trim(),
                        "limit_up_box",
                        dr["名称"].ToString().Trim(),
                        "现价：" + price.ToString() + " " + message.Trim()))
                    {
                        //StockWatcher.SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", dr["代码"].ToString().Trim(),
                        //        dr["名称"].ToString() + " " + message, price, "limit_up_box");


                        //18601197897
                        StockWatcher.SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message, price, "limit_up_box");

                        //老马
                        StockWatcher.SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message, price, "limit_up_box");
                        //老马的朋友
                        StockWatcher.SendAlertMessage("oqrMvt7eGkY9UejlTH1i8d-oD-V0", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message, price, "limit_up_box");
                        StockWatcher.SendAlertMessage("oqrMvtwvHer0l3SJGYP73ioQeuVo", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message, price, "limit_up_box");



                    }
                }

            }
            Thread.Sleep(15000);
        }
    }


    public static bool foot(Core.Timeline[] tArr, out double lowestPrice, out double displayLowPrice, out DateTime footTime)
    {
        lowestPrice = double.MaxValue;
        displayLowPrice = double.MaxValue;
        footTime = DateTime.MinValue;
        bool noShadow = false;
        bool isRefeshLowestPrice = false;
        int i = 0;
        for (; i < tArr.Length ; i++)
        {
            if (lowestPrice > tArr[i].todayLowestPrice)
            {
                lowestPrice = tArr[i].todayLowestPrice;
                isRefeshLowestPrice = true;
                //lowestTime = tArr[i].tickTime;
            }
            if (lowestPrice < tArr[i].todayStartPrice &&   tArr[i].todayEndPrice - lowestPrice >= 0.05)
            {
                if (isRefeshLowestPrice)
                {
                    footTime = tArr[i].tickTime;
                    noShadow = true;
                    isRefeshLowestPrice = false;

                }

            }
            else
            {
                noShadow = false;
            }
            if (displayLowPrice > Math.Min(tArr[i].todayEndPrice, tArr[i].todayStartPrice))
            {
                displayLowPrice = Math.Min(tArr[i].todayEndPrice, tArr[i].todayStartPrice);
            }
        }
        return noShadow;
    }


</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form2" runat="server">
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
                    <asp:BoundColumn DataField="信号" HeaderText="信号"></asp:BoundColumn>
                    <asp:BoundColumn DataField="缩量" HeaderText="缩量"></asp:BoundColumn>
                    <asp:BoundColumn DataField="盘比" HeaderText="盘比"></asp:BoundColumn>
                    <asp:BoundColumn DataField="总换手" HeaderText="总换手"></asp:BoundColumn>
					<asp:BoundColumn DataField="MACD日" HeaderText="MACD日" SortExpression="MACD日|asc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="KDJ日" HeaderText="KDJ日" SortExpression="KDJ率|asc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="KDJ60" HeaderText="KDJ60" SortExpression="KDJ率|asc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="KDJ30" HeaderText="KDJ30" SortExpression="KDJ率|asc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="3线" HeaderText="3线"></asp:BoundColumn>
                    
                    <asp:BoundColumn DataField="现价" HeaderText="现价"></asp:BoundColumn>
                    <asp:BoundColumn DataField="买入" HeaderText="买入"  ></asp:BoundColumn>
                    <asp:BoundColumn DataField="0日" HeaderText="0日"></asp:BoundColumn>
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
            <tr><td><%=t.ThreadState.ToString() %></td></tr>
        </table>
    </div>
    </form>
</body>
</html>
