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

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    protected void Page_Load(object sender, EventArgs e)
    {
        sort = Util.GetSafeRequestValue(Request, "sort", "放量 desc");
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
                    t.Start();

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
        string filter = "";
        if (Util.GetSafeRequestValue(Request, "option", "").Trim().Equals("openhigh"))
        {
            filter = "信号 like '%🔺%'";
        }
        else if (Util.GetSafeRequestValue(Request, "option", "").Trim().Equals("openlow"))
        {
            filter = "信号 not like '%🔺%'";
        }
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
                        case "量比":
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
                        case "均线压力":
                        case "均线支撑":
                        case "前高压力":
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
                if (drOri["信号"].ToString().IndexOf("👑") >= 0)
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
                        if (drOri["信号"].ToString().IndexOf("👑") >= 0)
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
        drRaise["信号"] = "📈";
        drRaise["昨收"] = raiseCount.ToString();
        DataRow drFire = dt.NewRow();
        drFire["信号"] = "👑";
        drFire["昨收"] = fireCount.ToString();
        DataRow drStar = dt.NewRow();
        drStar["信号"] = "🌟";
        drStar["昨收"] = starCount.ToString();

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
        DateTime prevDate = Util.GetLastTransactDate(currentDate, 1);
        DataTable dtOri = DBHelper.GetDataTable(" select * from alert_bull where alert_date = '" + currentDate + "' ");
        DataTable dtAlert = DBHelper.GetDataTable(" select * from stock_alert_message where alert_date = '" + currentDate.ToShortDateString() + "' and alert_type = 'bull' ");
        DataTable dt = new DataTable();
        dt.Columns.Add("代码", Type.GetType("System.String"));
        dt.Columns.Add("名称", Type.GetType("System.String"));
        dt.Columns.Add("信号", Type.GetType("System.String"));
        dt.Columns.Add("昨收", Type.GetType("System.Double"));
        dt.Columns.Add("今开", Type.GetType("System.Double"));
        dt.Columns.Add("今收", Type.GetType("System.Double"));
        dt.Columns.Add("今涨", Type.GetType("System.Double"));
        dt.Columns.Add("放量", Type.GetType("System.Double"));
        dt.Columns.Add("量比", Type.GetType("System.Double"));
        dt.Columns.Add("均线压力", Type.GetType("System.Double"));
        dt.Columns.Add("前高压力", Type.GetType("System.Double"));
        dt.Columns.Add("均线支撑", Type.GetType("System.Double"));

        dt.Columns.Add("TD", Type.GetType("System.Int32"));
        dt.Columns.Add("KDJ日", Type.GetType("System.Int32"));
        dt.Columns.Add("KDJ率", Type.GetType("System.Double"));
        dt.Columns.Add("MACD日", Type.GetType("System.Int32"));
        dt.Columns.Add("MACD率", Type.GetType("System.Double"));
        dt.Columns.Add("调整日", Type.GetType("System.Int32"));
        dt.Columns.Add("3线", Type.GetType("System.Double"));
        dt.Columns.Add("低点", Type.GetType("System.Double"));
        dt.Columns.Add("F1", Type.GetType("System.Double"));
        dt.Columns.Add("F3", Type.GetType("System.Double"));
        dt.Columns.Add("F5", Type.GetType("System.Double"));
        dt.Columns.Add("高点", Type.GetType("System.Double"));
        dt.Columns.Add("买入", Type.GetType("System.Double"));
        dt.Columns.Add("涨幅", Type.GetType("System.Double"));
        dt.Columns.Add("跌幅", Type.GetType("System.Double"));
        dt.Columns.Add("震幅", Type.GetType("System.Double"));
        dt.Columns.Add("综指", Type.GetType("System.Double"));
        dt.Columns.Add("均涨", Type.GetType("System.Double"));
        dt.Columns.Add("0日", Type.GetType("System.Double"));

        for (int i = 1; i <= 5; i++)
        {
            dt.Columns.Add(i.ToString() + "日", Type.GetType("System.Double"));
        }
        dt.Columns.Add("总计", Type.GetType("System.Double"));

        string[] gidArr = new string[dtOri.Rows.Count];
        for (int i = 0; i < gidArr.Length; i++)
        {
            gidArr[i] = dtOri.Rows[i]["gid"].ToString().Trim();
        }
        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock stock = new Stock(drOri["gid"].ToString().Trim());

            if (!stock.gid.Trim().Equals("sz000673"))
            {
                //continue;
            }


            stock.LoadKLineDay(rc);
            int currentIndex = stock.GetItemIndex(currentDate);
            if (currentIndex < 1)
                continue;
            double ma5 = stock.GetAverageSettlePrice(currentIndex, 5, 0);
            double prevMa5 = stock.GetAverageSettlePrice(currentIndex - 1, 5, 0);
            double ma10 = stock.GetAverageSettlePrice(currentIndex, 10, 0);
            double ma20 = stock.GetAverageSettlePrice(currentIndex, 20, 0);
            double ma30 = stock.GetAverageSettlePrice(currentIndex, 30, 0);

            if (ma5 <= ma10 || ma10 <= ma20 || ma20 <= ma30)
            {
                continue;
            }

            if (stock.kLineDay[currentIndex].highestPrice < ma5)
            {
                continue;
            }

            KLine.ComputeMACD(stock.kLineDay);
            KLine.ComputeRSV(stock.kLineDay);
            KLine.ComputeKDJ(stock.kLineDay);

            bool correctKlineStyle = true;

            if (prevMa5 < stock.kLineDay[currentIndex - 1].endPrice && stock.kLineDay[currentIndex].startPrice < ma5
                && (stock.kLineDay[currentIndex - 1].endPrice - stock.kLineDay[currentIndex].startPrice) / stock.kLineDay[currentIndex - 1].endPrice > 0.0382)
            //昨天收在均线上, 今天开盘在均线下且跌幅超过3.82%
            {
                correctKlineStyle = false;
            }

            if (ma5 < stock.kLineDay[currentIndex].startPrice && stock.kLineDay[currentIndex].lowestPrice > ma5 * 1.0382)
            {
                correctKlineStyle = false;
            }



            if (stock.kLineDay[currentIndex - 1].macd < stock.kLineDay[currentIndex - 2].macd || stock.kLineDay[currentIndex - 1].j < stock.kLineDay[currentIndex - 2].j)
            {
                correctKlineStyle = false;
            }



            if (!correctKlineStyle)
            {
                continue;
            }


            double current3LinePrice = stock.GetAverageSettlePrice(currentIndex, 3, 3);
            double previous3LinePrice = 0;
            int adjustDays = 0;
            for (int i = currentIndex - 1; i >= 0; i--)
            {
                if (stock.kLineDay[i].endPrice < stock.GetAverageSettlePrice(i, 3, 3))
                {
                    adjustDays++;
                }

                if (KLine.IsCross3Line(stock.kLineDay, i))
                {
                    previous3LinePrice = stock.GetAverageSettlePrice(i, 3, 3);
                    break;
                }
            }
            adjustDays++;

            double settlePrice = stock.kLineDay[currentIndex - 1].endPrice;
            double openPrice = stock.kLineDay[currentIndex].startPrice;
            double currentPrice = stock.kLineDay[currentIndex].endPrice;
            double line3Price = stock.GetAverageSettlePrice(currentIndex, 3, 3);
            DateTime lastDate = DateTime.Parse(stock.kLineDay[currentIndex - 1].startDateTime.ToShortDateString());
            double lastDayVolume = stock.kLineDay[currentIndex - 1].VirtualVolume;//Stock.GetVolumeAndAmount(stock.gid, lastDate)[0];
            double currentVolume = stock.kLineDay[currentIndex].VirtualVolume;//Stock.GetVolumeAndAmount(stock.gid, currentDate)[0];
            int kdjDays = stock.kdjDays(currentIndex - 1);
            int macdDays = stock.macdDays(currentIndex - 1);



            if (!(macdDays <= kdjDays && kdjDays <= 1 && Math.Abs(macdDays - kdjDays) < 2))
            {
                continue;
            }

            if (macdDays > kdjDays && kdjDays == -1)
            {
                continue;
            }

            DateTime ma5Time = DateTime.Now;
            Core.Timeline[] timelineArray = Core.Timeline.LoadTimelineArrayFromRedis(stock.gid, currentDate, rc);
            if (timelineArray.Length == 0)
            {
                timelineArray = Core.Timeline.LoadTimelineArrayFromSqlServer(stock.gid, currentDate);
            }
            for (int i = 0; i < timelineArray.Length; i++)
            {
                if (timelineArray[i].todayLowestPrice < ma5 * 1.005 && timelineArray[i].todayEndPrice > ma5 * 1.005)
                {
                    ma5Time = timelineArray[i].tickTime;
                    break;
                }
            }

            double lowestPrice = stock.LowestPrice(currentDate, 20);
            double highestPrice = stock.HighestPrice(currentDate, 40);
            double f1 = lowestPrice + (highestPrice - lowestPrice) * 0.236;
            double f3 = lowestPrice + (highestPrice - lowestPrice) * 0.382;
            double f5 = lowestPrice + (highestPrice - lowestPrice) * 0.618;

            double macdPrice = KLine.GetMACDFolkPrice(stock.kLineDay, currentIndex);
            double macdDegree = KLine.ComputeMacdDegree(stock.kLineDay, currentIndex)*1000;
            double kdjDegree = KLine.ComputeKdjDegree(stock.kLineDay, currentIndex);
            double upSpace = 0;
            double downSpace = 0;



            double buyPrice = ma5;

            bool waitLowPrice = false;

            if (stock.kLineDay[currentIndex].startPrice > ma5)
            {
                buyPrice = Math.Max(stock.kLineDay[currentIndex].lowestPrice, ma5);
                waitLowPrice = true;


            }


            double pressure = stock.GetMaPressure(currentIndex, buyPrice);
            double highPointPressure = 0;

            KeyValuePair<DateTime, double>[] highPoints = Stock.GetHighPoints(stock.kLineDay, currentIndex);
            for (int i = 0; i < highPoints.Length; i++)
            {
                if (highPoints[i].Value >= stock.kLineDay[currentIndex].highestPrice * 0.99)
                {
                    highPointPressure = highPoints[i].Value;
                    break;
                }
            }


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

            DataRow dr = dt.NewRow();
            dr["代码"] = stock.gid.Trim();
            dr["名称"] = stock.Name.Trim();
            dr["昨收"] = settlePrice;
            dr["今开"] = openPrice;
            dr["今收"] = currentPrice;
            dr["今涨"] = (stock.kLineDay[currentIndex].startPrice - settlePrice) / settlePrice;
            dr["放量"] = currentVolume / lastDayVolume;
            if (timelineArray != null)
            {
                dr["量比"] = Stock.ComputeQuantityRelativeRatio(stock.kLineDay, timelineArray, ma5Time);
            }
            else
            {
                dr["量比"] = 0;
            }
            dr["3线"] = line3Price;
            dr["低点"] = lowestPrice;
            dr["调整日"] = adjustDays.ToString();// currentIndex - previous3LineIndex;
            dr["F1"] = f1;
            dr["F3"] = f3;
            dr["F5"] = f5;
            dr["高点"] = highestPrice;

            dr["KDJ日"] = kdjDays;
            dr["MACD日"] = macdDays; //stock.macdDays(currentIndex);
            dr["MACD率"] = macdDegree;
            dr["KDJ率"] = kdjDegree;
            dr["涨幅"] = upSpace;
            dr["跌幅"] = downSpace;
            dr["震幅"] = upSpace + downSpace;
            dr["综指"] = macdDegree + kdjDegree;
            dr["TD"] = KLine.GetLastDeMarkBuyPointIndex(stock.kLineDay, currentIndex);
            dr["均涨"] = (line3Price - previous3LinePrice) /previous3LinePrice / adjustDays;

            dr["均线支撑"] = buyPrice;



            dr["前高压力"] = highPointPressure;
            buyPrice = Math.Max(buyPrice, stock.kLineDay[currentIndex].lowestPrice);
            KeyValuePair<string, double>[] quota = stock.GetSortedQuota(currentIndex);
            for (int j = quota.Length - 1; j >= 0; j--)
            {
                if (quota[j].Key.Trim().StartsWith("ma")
                    && stock.kLineDay[currentIndex].highestPrice >= quota[j].Value && buyPrice < quota[j].Value)
                {
                    buyPrice = quota[j].Value;
                    break;
                }
            }

            double totalPressure = 0;
            if (pressure > 0 && highPointPressure > 0)
            {
                totalPressure = Math.Min(pressure, highPointPressure);
            }
            else
            {
                totalPressure = Math.Max(pressure, highPointPressure);
            }
            if (buyPrice == 0)
            {
                buyPrice = currentPrice;
            }

            if (stock.kLineDay[currentIndex - 3].volume * 1.25 < stock.kLineDay[currentIndex - 2].volume 
                && stock.kLineDay[currentIndex - 2].volume * 1.25 < stock.kLineDay[currentIndex - 1].volume)
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"持续放量\" >👍</a>";
            }


            if (((totalPressure - buyPrice) / buyPrice > 0.1 || totalPressure == 0)  && buyPrice > line3Price)
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"上无压力，放量\" >🌟</a>";
            }

            if (buyPrice > line3Price
                && stock.kLineDay[currentIndex - 1].startPrice < prevMa5 )
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"三线以上，当日穿越5日均线\" >📈</a>";
            }

            if (waitLowPrice)
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"等待回抽\" >🔺</a>";
            }

            if (stock.kLineDay[currentIndex].VirtualVolume >= Stock.GetAvarageVolume(stock.kLineDay, currentIndex, 5)
                && stock.kLineDay[currentIndex].VirtualVolume >= Stock.GetAvarageVolume(stock.kLineDay, currentIndex, 10))
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"大于5 10日均量线\" >🔥</a>";
            }
            if (currentPrice > line3Price && stock.kLineDay[currentIndex - 1].endPrice < previous3LinePrice)
            {
                dr["信号"] = dr["信号"].ToString().Trim() + "<a title=\"过3线\" >👫</a>";
            }

            if ((int)dr["KDJ日"] == 0 && (int)dr["MACD日"] == 0 && (double)dr["今涨"] <= 0.0618 && (double)dr["放量"] > 1.5)
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"同日双金叉\" >👑</a>";
            }



            if (stock.kLineDay[currentIndex].startPrice <= ma30)
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"一阳穿三线\" >🌞</a>";
            }

            if ((dr["信号"].ToString().IndexOf("🔺") < 0 && currentPrice <= buyPrice * 1.01 && currentPrice >= buyPrice)
                || (dr["信号"].ToString().IndexOf("🔺") >= 0 && stock.kLineDay[currentIndex].lowestPrice <= ma5 * 1.005 && currentPrice > ma5 * 1.005 && currentPrice < ma5 * 1.01 ) )
            {
                dr["信号"] = dr["信号"].ToString() + "🛍️";
            }

            if (dtAlert.Select(" gid = '" + stock.gid.Trim() + "' ").Length > 0)
            {
                dr["信号"] = dr["信号"].ToString().Trim() + "<a title=\"已经预警过\" >❗️</a>";
            }

            /*
            if (buyPrice < stock.kLineDay[currentIndex].startPrice)
            {
                dr["信号"] = "";
            }
            */
            dr["买入"] = buyPrice;
            dr["均线压力"] = pressure;

            dr["0日"] = (currentPrice - buyPrice) / buyPrice;

            double maxPrice = 0;
            for (int i = 1; i <= 5; i++)
            {
                if (currentIndex + i >= stock.kLineDay.Length)
                    break;
                double highPrice = stock.kLineDay[currentIndex + i].startPrice;
                maxPrice = Math.Max(maxPrice, highPrice);
                dr[i.ToString() + "日"] = (highPrice - buyPrice) /buyPrice;
            }
            dr["总计"] = (maxPrice - buyPrice) / buyPrice;



            dt.Rows.Add(dr);
        }
        //rc.Dispose();
        return dt;
    }

    public static void PageWatcher()
    {
        for(; true; )
        {
            DateTime currentDate = Util.GetDay(DateTime.Now);
            if (Util.IsTransacDay(currentDate) && Util.IsTransacTime(DateTime.Now))
            {
                DataTable dt = GetData(currentDate);
                foreach(DataRow dr in dt.Rows)
                {
                    //string signalStr = Util.RemoveHTMLTag()
                    /*
                    if (dr["信号"].ToString().IndexOf("🛍️") >= 0
                        && dr["信号"].ToString().IndexOf("🔥") >= 0
                        && (dr["信号"].ToString().IndexOf("👑") >= 0
                || dr["信号"].ToString().IndexOf("🌟") >= 0
                || dr["信号"].ToString().IndexOf("📈") >= 0))
                */
                    if (dr["信号"].ToString().IndexOf("🛍️") >= 0)
                    {
                        string message = Util.RemoveHTMLTag(dr["信号"].ToString()) + " " + dr["代码"].ToString()
                + " " + dr["名称"].ToString() + " 放量：" + Math.Round(100 * double.Parse(dr["放量"].ToString()), 2).ToString()
                + "% 量比:" + Math.Round((double)dr["量比"], 2).ToString() +  " KDJ:" + dr["KDJ日"].ToString() + " MACD：" + dr["MACD日"].ToString();
                        double price = Math.Round(double.Parse(dr["买入"].ToString()), 2);
                        if (StockWatcher.AddAlert(DateTime.Parse(DateTime.Now.ToShortDateString()),
                                dr["代码"].ToString().Trim(),
                                "bull",
                                dr["名称"].ToString().Trim(),
                                "买入价：" + price.ToString() + " " + message.Trim(), price))
                        {
                            StockWatcher.SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message, price, "bull");
                        }
                    }
                    /*
                    if (dr["信号"].ToString().IndexOf("🛍️") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                    {
                        string message = dr["信号"].ToString().Trim() + " " + dr["代码"].ToString() + " " + dr["名称"].ToString()
                            + " 均涨：" + Math.Round(double.Parse(dr["均涨"].ToString()) * 100, 2).ToString()  + "% 调整日：" + dr["调整日"].ToString();
                        double price = Math.Round(double.Parse(dr["买入"].ToString()), 2);
                        if (StockWatcher.AddAlert(DateTime.Parse(DateTime.Now.ToShortDateString()),
                                dr["代码"].ToString().Trim(),
                                "break_3_line_twice",
                                dr["名称"].ToString().Trim(),
                                "买入价：" + price.ToString() + " " + message.Trim()))
                        {
                            StockWatcher.SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", dr["代码"].ToString().Trim(),
                                dr["名称"].ToString() + " " + message, price, "break_3_line_twice");
                        }

                    }*/
                }
            }
            Thread.Sleep(600000);
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
                    <asp:BoundColumn DataField="昨收" HeaderText="昨收"></asp:BoundColumn>
                    <asp:BoundColumn DataField="今开" HeaderText="今开"></asp:BoundColumn>
                    <asp:BoundColumn DataField="今收" HeaderText="今收"></asp:BoundColumn>
                    <asp:BoundColumn DataField="今涨" HeaderText="今涨" SortExpression="今涨|desc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="放量" HeaderText="放量" SortExpression="放量|desc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="量比" HeaderText="量比" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="前高压力" HeaderText="前高压力"></asp:BoundColumn>
                    <asp:BoundColumn DataField="均线压力" HeaderText="均线压力"></asp:BoundColumn>
                    <asp:BoundColumn DataField="均线支撑" HeaderText="均线支撑"></asp:BoundColumn>

					<asp:BoundColumn DataField="MACD日" HeaderText="MACD日" SortExpression="MACD日|asc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="KDJ日" HeaderText="KDJ日" SortExpression="KDJ率|asc"></asp:BoundColumn>
                    
                   
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
 
        </table>
    </div>
    </form>
</body>
</html>
