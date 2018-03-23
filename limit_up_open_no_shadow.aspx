<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Threading" %>
<!DOCTYPE html>

<script runat="server">

    public DateTime currentDate = Util.GetDay(DateTime.Now);

    public string sort = "MACD日,KDJ日,综指 desc";

    public static ThreadStart tsQ = new ThreadStart(StockWatcher.LogQuota);

    public static Thread tQ = new Thread(tsQ);

    public static ThreadStart ts = new ThreadStart(PageWatcher);

    public static Thread t = new Thread(ts);

    protected void Page_Load(object sender, EventArgs e)
    {
        sort = Util.GetSafeRequestValue(Request, "sort", "高开 desc, 缩量");
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
        DataTable dtOri = GetData(currentDate);
        return RenderHtml(dtOri.Select("  ", sort));
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
                        case "现价":
                        case "前低":
                        case "F1":
                        case "F3":
                        case "F5":
                        case "现高":
                        case "3线":
                        case "无影":
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

    public static DataTable GetData(DateTime currentDate)
    {
        currentDate = Util.GetDay(currentDate);
        DataTable dt = new DataTable();
        dt.Columns.Add("代码", Type.GetType("System.String"));
        dt.Columns.Add("名称", Type.GetType("System.String"));
        dt.Columns.Add("信号", Type.GetType("System.String"));
        dt.Columns.Add("缩量", Type.GetType("System.Double"));
        dt.Columns.Add("高开", Type.GetType("System.Double"));
        dt.Columns.Add("今涨", Type.GetType("System.Double"));
        dt.Columns.Add("今开", Type.GetType("System.Double"));
        dt.Columns.Add("无影", Type.GetType("System.Double"));
        dt.Columns.Add("最低时间", Type.GetType("System.String"));
        dt.Columns.Add("现高", Type.GetType("System.Double"));
        dt.Columns.Add("F3", Type.GetType("System.Double"));
        dt.Columns.Add("F5", Type.GetType("System.Double"));
        dt.Columns.Add("前低", Type.GetType("System.Double"));
        dt.Columns.Add("幅度", Type.GetType("System.String"));
        dt.Columns.Add("3线", Type.GetType("System.Double"));
        dt.Columns.Add("现价", Type.GetType("System.Double"));
        dt.Columns.Add("评级", Type.GetType("System.String"));
        dt.Columns.Add("买入", Type.GetType("System.Double"));
        dt.Columns.Add("KDJ日", Type.GetType("System.Int32"));
        dt.Columns.Add("MACD日", Type.GetType("System.Int32"));
        //dt.Columns.Add("F3折返", Type.GetType("System.Double"));


        for (int i = 1; i <= 5; i++)
        {
            dt.Columns.Add(i.ToString() + "日", Type.GetType("System.Double"));
        }
        dt.Columns.Add("总计", Type.GetType("System.Double"));
        if (!Util.IsTransacDay(currentDate))
        {
            return dt;
        }

        DateTime lastTransactDate = Util.GetLastTransactDate(currentDate, 1);
        //DateTime limitUpStartDate = Util.GetLastTransactDate(lastTransactDate, 4);



        DataTable dtOri = DBHelper.GetDataTable(" select gid, alert_date from limit_up where alert_date = '"
            + lastTransactDate.ToShortDateString() + "'  order by alert_date desc ");

        Core.RedisClient rc = new Core.RedisClient("127.0.0.1");
        foreach (DataRow drOri in dtOri.Rows)
        {
            try
            {

                /*
                if (!drOri["gid"].ToString().Trim().Equals("sz002549"))
                {
                    continue;
                }
                */


                DateTime alertDate = DateTime.Parse(drOri["alert_date"].ToString().Trim());
                DataRow[] drArrExists = dtOri.Select(" gid = '" + drOri["gid"].ToString() + "' and alert_date > '" + alertDate.ToShortDateString() + "'  ");
                if (drArrExists.Length > 0)
                {
                    continue;
                }
                Stock stock = new Stock(drOri["gid"].ToString().Trim(), rc);
                stock.LoadKLineDay(rc);
                Core.Timeline[] timelineArr = Core.Timeline.LoadTimelineArrayFromRedis(stock.gid, currentDate, rc);
                if (timelineArr.Length == 0)
                {
                    timelineArr = Core.Timeline.LoadTimelineArrayFromSqlServer(stock.gid, currentDate);
                }
                KLine.ComputeMACD(stock.kLineDay);
                KLine.ComputeRSV(stock.kLineDay);
                KLine.ComputeKDJ(stock.kLineDay);

                int currentIndex = stock.GetItemIndex(currentDate);
                if (currentIndex < 0)
                    continue;

                int limitUpIndex = stock.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));

                if (limitUpIndex == -1)
                {
                    continue;
                }

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
                double f3 = lowest + (highest - lowest) * 1.382;
                if (stock.kLineDay[currentIndex].startPrice < stock.kLineDay[limitUpIndex].endPrice)
                    continue;
                double f5 = lowest + (highest - lowest) * 1.618;
                double line3Price = KLine.GetAverageSettlePrice(stock.kLineDay, currentIndex, 3, 3);
                double currentPrice = stock.kLineDay[currentIndex].endPrice;
                double buyPrice = 0;
                //double f3Distance = 0.382 - (highest - stock.kLineDay[currentIndex].lowestPrice) / (highest - lowest);

                double volumeToday = stock.kLineDay[currentIndex].volume;  //Stock.GetVolumeAndAmount(stock.gid, DateTime.Parse(currentDate.ToShortDateString() + " " + DateTime.Now.Hour.ToString() + ":" + DateTime.Now.Minute.ToString()))[0];

                double volumeYesterday = stock.kLineDay[limitUpIndex].VirtualVolume;
                if (DateTime.Now.Date != currentDate.Date || (DateTime.Now.Hour >= 15))
                {
                    volumeYesterday = stock.kLineDay[limitUpIndex].volume;
                }
                // Stock.GetVolumeAndAmount(stock.gid, DateTime.Parse(stock.kLineDay[limitUpIndex].startDateTime.ToShortDateString() + " " + DateTime.Now.Hour.ToString() + ":" + DateTime.Now.Minute.ToString()))[0];
                /*
                for (int j = lowestIndex; j < currentIndex; j++)
                {
                    volumeYesterday = Math.Max(volumeYesterday, stock.kLineDay[j].VirtualVolume);
                }
                */


                double volumeReduce = volumeToday / volumeYesterday;

                if (lowest == 0 || line3Price == 0)
                {
                    continue;
                }
                //buyPrice = Math.Max(stock.kLineDay[limitUpIndex].highestPrice, stock.kLineDay[currentIndex].lowestPrice);

                buyPrice = Math.Max(f3, stock.kLineDay[currentIndex].lowestPrice);

                string memo = "";

                Core.Timeline[] timelineArray = Core.Timeline.LoadTimelineArrayFromRedis(stock.gid, currentDate, rc);
                if (timelineArray.Length == 0)
                {
                    timelineArray = Core.Timeline.LoadTimelineArrayFromSqlServer(stock.gid, currentDate);
                }
                DateTime todayLowestTime = Core.Timeline.GetLowestTime(timelineArray);
                if (todayLowestTime.Hour == 9 && todayLowestTime.Minute < 30)
                {
                    todayLowestTime = todayLowestTime.Date.AddHours(9).AddMinutes(30);
                }
                TimeSpan todayLowestTimeSpan;


                if (DateTime.Now.Date == currentDate.Date && DateTime.Now.Hour < 15)
                {
                    todayLowestTimeSpan = DateTime.Now - todayLowestTime;
                    if (todayLowestTime.Hour < 13)
                    {
                        if (DateTime.Now.Hour < 13)
                        {
                            todayLowestTimeSpan = todayLowestTimeSpan - (DateTime.Now - DateTime.Now.Date.AddHours(11).AddMinutes(30));
                        }
                        else
                        {
                            todayLowestTimeSpan = todayLowestTimeSpan - (DateTime.Now.AddHours(13) - DateTime.Now.Date.AddHours(11).AddMinutes(30));
                        }
                    }
                }
                else
                {
                    todayLowestTimeSpan = todayLowestTime.Date.AddHours(15) - todayLowestTime;
                    if (todayLowestTime.Hour < 13)
                    {
                        todayLowestTimeSpan = todayLowestTimeSpan - (currentDate.Date.AddHours(13) - currentDate.Date.AddHours(11).AddMinutes(30));
                    }
                }

                memo = todayLowestTimeSpan.Hours.ToString() + "小时" + todayLowestTimeSpan.Minutes.ToString() + "分钟";


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

                dr["今涨"] = (stock.kLineDay[currentIndex].endPrice - stock.kLineDay[currentIndex - 1].endPrice) / stock.kLineDay[currentIndex - 1].endPrice;


                double width = Math.Round(100 * (highest - lowest) / lowest, 2);



                //dr["调整"] = currentIndex - limitUpIndex;
                dr["缩量"] = volumeReduce;

                double openRaise = (stock.kLineDay[currentIndex].startPrice - stock.kLineDay[limitUpIndex].endPrice) / stock.kLineDay[limitUpIndex].endPrice;
                /*
                if (volumeReduce < 1.25 && stock.kLineDay[currentIndex].lowestPrice >= highest
                    && stock.kLineDay[currentIndex].startPrice != stock.kLineDay[currentIndex].endPrice)
                {
                    dr["信号"] = "📈";
                    if (stock.kLineDay[currentIndex].startPrice >= stock.kLineDay[currentIndex].endPrice
                        && stock.kLineDay[currentIndex].endPrice > stock.kLineDay[currentIndex].lowestPrice)
                    {
                        dr["信号"] = "📈🛍️";
                    }
                }
                */
                /*
                if ((buyPrice - highest) / highest <= 0.005 && buyPrice >= highest )
                {
                    dr["信号"] = "📈";
                }
                */
                if ((currentPrice - buyPrice) / buyPrice <= 0.005 && ((double)dr["今涨"]) < 0.09 && stock.kLineDay[currentIndex].lowestPrice >= stock.kLineDay[limitUpIndex].highestPrice)
                {
                    dr["信号"] = dr["信号"].ToString() + "🛍️";
                }

                if (timelineArr[0].todayStartPrice > timelineArr[0].todayLowestPrice
                  //&& timelineArr[0].todayLowestPrice > stock.kLineDay[limitUpIndex].highestPrice
                  )//  && timelineArr[0].todayLowestPrice <= stock.kLineDay[currentIndex].lowestPrice)
                {
                    dr["信号"] = dr["信号"].ToString() + "❗️";
                }

                if (timelineArr[0].todayLowestPrice <= stock.kLineDay[currentIndex].lowestPrice)
                {
                    dr["信号"] = dr["信号"].ToString() + "👑";
                }

                if (stock.kLineDay[currentIndex].startPrice > f3 && stock.kLineDay[currentIndex].startPrice < f5 && openRaise < 0.093)
                {
                    dr["信号"] = dr["信号"].ToString() + "📈";
                }

                if (stock.kLineDay[currentIndex].endPrice > f3 && stock.kLineDay[currentIndex].endPrice < f5  && ((double)dr["今涨"]) < 0.093 )
                {
                    dr["信号"] = dr["信号"].ToString() + "🔥";
                    buyPrice = f3;
                }


                /*
                                if (timelineArr[0].todayLowestPrice - highest > 0 && (timelineArr[0].todayLowestPrice - highest) / highest <= 0.005)
                                {
                                    dr["信号"] = dr["信号"].ToString() + "💎";
                                }
                                */
                dr["现高"] = highest;
                dr["F3"] = f3;
                dr["F5"] = f5;
                dr["前低"] = lowest;
                dr["幅度"] = width.ToString() + "%";

                dr["最低时间"] = GetTodayLowestTime(timelineArr);

                //dr["F3折返"] = (stock.kLineDay[currentIndex].lowestPrice - f3) / f3;

                dr["3线"] = line3Price;
                dr["现价"] = currentPrice;
                dr["今开"] = stock.kLineDay[currentIndex].startPrice;
                dr["无影"] = timelineArr[0].todayLowestPrice;
                dr["评级"] = memo;
                dr["买入"] = buyPrice;
                dr["KDJ日"] = stock.kdjDays(currentIndex);
                dr["MACD日"] = stock.macdDays(currentIndex);
                dr["高开"] = openRaise;
                double maxPrice = 0;
                for (int i = 1; i <= 5; i++)
                {
                    if (currentIndex + i >= stock.kLineDay.Length)
                        break;
                    double highPrice = stock.kLineDay[currentIndex + i].highestPrice;
                    maxPrice = Math.Max(maxPrice, highPrice);
                    dr[i.ToString() + "日"] = (highPrice - buyPrice) / buyPrice;
                }
                dr["总计"] = (maxPrice - buyPrice) / buyPrice;
                dt.Rows.Add(dr);
            }
            catch
            {

            }
        }
        rc.Dispose();
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

    public static string GetTodayLowestTime(Core.Timeline[] timelineArr)
    {
        string ret = "9:30";
        double lowest = double.MaxValue;
        int i = 0;
        foreach (Core.Timeline t in timelineArr)
        {
            if (lowest > t.todayLowestPrice)
            {
                lowest = t.todayLowestPrice;
                ret = t.tickTime.Hour.ToString() + ":" + t.tickTime.Minute.ToString();
                if (i > 0)
                {
                    break;
                }
                i++;

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
            if (Util.IsTransacDay(currentDate) && !Util.IsTransacTime(DateTime.Now))
            {
                DataTable dt = GetData(currentDate);
                foreach(DataRow dr in dt.Rows)
                {
                    if (dr["信号"].ToString().IndexOf("🛍️") >= 0 &&
                        (dr["信号"].ToString().IndexOf("📈") >= 0 || dr["信号"].ToString().IndexOf("🔥") >= 0 || dr["信号"].ToString().IndexOf("🌟") >= 0))
                    {
                        double high = Math.Round(double.Parse(dr["现高"].ToString()), 2);
                        double low = Math.Round(double.Parse(dr["前低"].ToString()), 2);
                        double f3 = Math.Round(double.Parse(dr["F3"].ToString()), 2);
                        double line3 = Math.Round(double.Parse(dr["3线"].ToString()), 2);
                        //string message = "F3:" + f3.ToString() + " " + ((f3 >= line3) ? "🐂高于" : "🐻低于") + "3线：" + line3.ToString() + " 现高：" + high.ToString() + " 前低：" + low.ToString();
                        string message = ((f3 >= line3) ? "🐂高于3线" : "");
                        message = message.Trim() + "  " + ((int.Parse(dr["KDJ日"].ToString()) >= 0) ? "👑KDJ" : "");
                        message = message.Trim() + "  幅度：" + Math.Round(100 * (high - low) / low, 2).ToString() + "%";
                        double price = Math.Round(double.Parse(dr["现价"].ToString()), 2);
                        if (StockWatcher.AddAlert(DateTime.Parse(DateTime.Now.ToShortDateString()),
                                dr["代码"].ToString().Trim(),
                                "limit_up_box_f3",
                                dr["名称"].ToString().Trim(),
                                "现价：" + price.ToString() + " " + message.Trim()))
                        {
                            string message_ext = message.Replace("👑KDJ", "👑KDJ" + dr["KDJ日"].ToString().Trim()) + " 调整：" + dr["调整"].ToString().Trim();
                            StockWatcher.SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message_ext, f3, "limit_up_box_f3");
                            StockWatcher.SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message_ext, f3, "limit_up_box_f3");


                            StockWatcher.SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message, f3, "limit_up_box_f3");
                            StockWatcher.SendAlertMessage("oqrMvt2RxLEM7B8a3H6BYD5tXEiY", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message, f3, "limit_up_box_f3");
                            StockWatcher.SendAlertMessage("oqrMvt1-mTlYx0c9qr7EM9ryA6-I", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message, f3, "limit_up_box_f3");
                            StockWatcher.SendAlertMessage("oqrMvtxeGio8mZcm3U69TtcDu9XY", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message, f3, "limit_up_box_f3");

                        }
                    }
                    else
                    {
                        double high = Math.Round(double.Parse(dr["现高"].ToString()), 2);
                        double low = Math.Round(double.Parse(dr["前低"].ToString()), 2);
                        double f5 = Math.Round(double.Parse(dr["F5"].ToString()), 2);
                        double line3 = Math.Round(double.Parse(dr["3线"].ToString()), 2);
                        string message = "F5:" + f5.ToString() + " " + ((f5 >= line3) ? "🐂高于" : "🐻低于") + "3线：" + line3.ToString() + " 现高：" + high.ToString() + " 前低：" + low.ToString();
                        double price = Math.Round(double.Parse(dr["买入"].ToString()), 2);
                        if (StockWatcher.AddAlert(DateTime.Parse(DateTime.Now.ToShortDateString()),
                                dr["代码"].ToString().Trim(),
                                "limit_up_box_f5",
                                dr["名称"].ToString().Trim(),
                                "买入价：" + price.ToString() + " " + message.Trim()))
                        {
                            /*
                            StockWatcher.SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message, price, "limit_up_box_f5");
                            
                            StockWatcher.SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message, price, "limit_up_box_f5");
                            StockWatcher.SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message, price, "limit_up_box_f5");
                            StockWatcher.SendAlertMessage("oqrMvt2RxLEM7B8a3H6BYD5tXEiY", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message, price, "limit_up_box_f5");
                            
                            */

                        }

                    }

                }
            }
            Thread.Sleep(30000);
        }
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
                    <asp:BoundColumn DataField="信号" HeaderText="信号" SortExpression="信号|desc" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="缩量" HeaderText="缩量"></asp:BoundColumn>
					<asp:BoundColumn DataField="MACD日" HeaderText="MACD日" SortExpression="MACD日|asc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="KDJ日" HeaderText="KDJ日" SortExpression="KDJ率|asc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="3线" HeaderText="3线"></asp:BoundColumn>
                    <asp:BoundColumn DataField="最低时间" HeaderText="最低时间"></asp:BoundColumn>
                    <asp:BoundColumn DataField="无影" HeaderText="无影"></asp:BoundColumn>
                    <asp:BoundColumn DataField="今开" HeaderText="今开"></asp:BoundColumn>
                    <asp:BoundColumn DataField="今涨" HeaderText="今涨"></asp:BoundColumn>
                    <asp:BoundColumn DataField="现高" HeaderText="现高"></asp:BoundColumn>
                    <asp:BoundColumn DataField="F3" HeaderText="F3"></asp:BoundColumn>
                    <asp:BoundColumn DataField="F5" HeaderText="F5"></asp:BoundColumn>
                    <asp:BoundColumn DataField="前低" HeaderText="前低"></asp:BoundColumn>
                    <asp:BoundColumn DataField="高开" HeaderText="高开"></asp:BoundColumn>
                    <asp:BoundColumn DataField="幅度" HeaderText="幅度"></asp:BoundColumn>
                    <asp:BoundColumn DataField="现价" HeaderText="现价"></asp:BoundColumn>
                
                    <asp:BoundColumn DataField="买入" HeaderText="买入"  ></asp:BoundColumn>
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
