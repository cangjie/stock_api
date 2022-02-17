<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Threading" %>
<!DOCTYPE html>

<script runat="server">

    public DateTime currentDate = Util.GetDay(DateTime.Now);

    public string sort = "缩量";



    protected void Page_Load(object sender, EventArgs e)
    {
        sort = Util.GetSafeRequestValue(Request, "sort", "KDJ日,布林宽");
        if (!IsPostBack)
        {


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
        int days = int.Parse(Util.GetSafeRequestValue(Request, "days", "22"));
        DataTable dtOri = GetData(currentDate, days);
        string filter = "";
        if (Util.GetSafeRequestValue(Request, "goldcross", "0").Trim().Equals("0"))
        {
            filter = "";
        }
        else
        {
            filter = " (KDJ日 >= 0 and MACD日 >= 0)";
        }
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
                        case "红绿灯价":
                            double currentValuePrice = (double)drOri[i];
                            dr[i] = "<font color=\"" + (currentValuePrice > currentPrice ? "red" : (currentValuePrice == currentPrice ? "gray" : "green")) + "\"  >"
                                + Math.Round(currentValuePrice, 2).ToString() + "</font>";
                            break;

                        case "价差":
                            double currentValuePrice1 = (double)drOri[i];
                            dr[i] = Math.Round(currentValuePrice1, 2).ToString();
                            break;

                        default:
                            if (System.Text.RegularExpressions.Regex.IsMatch(drArr[0].Table.Columns[i].Caption.Trim(), "\\d日")
                                || drArr[0].Table.Columns[i].Caption.Trim().Equals("总计") || drArr[0].Table.Columns[i].Caption.Trim().Equals("红绿灯涨")
                                || drArr[0].Table.Columns[i].Caption.Trim().Equals("今涨"))
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
                else if (drArr[0].Table.Columns[i].Caption.Trim().Equals("调整"))
                {
                    if (drOri[i].ToString().Trim().Equals("2") || drOri[i].ToString().Trim().Equals("4"))
                    {
                        dr[i] = "<font color='red' >" + drOri[i].ToString() + "</font>";
                    }
                    else
                    {
                        dr[i] = drOri[i].ToString();
                    }
                }
                else
                {
                    dr[i] = drOri[i].ToString();
                }
            }
            string gid = dr["代码"].ToString();
            dr["代码"] = "<a href=\"show_K_line_day.aspx?gid=" + gid.Trim() + "&maxprice=" + hightPrice.ToString() + "&minprice=" + lowPrice.ToString() + "\" target=\"_blank\" >" + dr["代码"].ToString() + "</a>";
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

    public static DataTable GetData(DateTime currentDate, int days)
    {
        currentDate = Util.GetDay(currentDate);
        DataTable dt = new DataTable();
        dt.Columns.Add("红绿灯日", Type.GetType("System.Int32"));
        dt.Columns.Add("代码", Type.GetType("System.String"));
        dt.Columns.Add("名称", Type.GetType("System.String"));
        dt.Columns.Add("信号", Type.GetType("System.String"));
        dt.Columns.Add("缩量", Type.GetType("System.Double"));
        dt.Columns.Add("板数", Type.GetType("System.Int32"));
        dt.Columns.Add("调整", Type.GetType("System.Int32"));
        dt.Columns.Add("现高", Type.GetType("System.Double"));
        dt.Columns.Add("红绿灯价", Type.GetType("System.Double"));
        dt.Columns.Add("F3", Type.GetType("System.Double"));
        dt.Columns.Add("F5", Type.GetType("System.Double"));
        dt.Columns.Add("前低", Type.GetType("System.Double"));
        dt.Columns.Add("幅度", Type.GetType("System.String"));
        dt.Columns.Add("3线", Type.GetType("System.Double"));
        dt.Columns.Add("现价", Type.GetType("System.Double"));
        dt.Columns.Add("今涨", Type.GetType("System.Double"));
        dt.Columns.Add("评级", Type.GetType("System.String"));
        dt.Columns.Add("买入", Type.GetType("System.Double"));
        dt.Columns.Add("KDJ日", Type.GetType("System.Int32"));
        dt.Columns.Add("MACD日", Type.GetType("System.Int32"));
        dt.Columns.Add("F3折返", Type.GetType("System.Double"));
        dt.Columns.Add("无影时", Type.GetType("System.DateTime"));
        dt.Columns.Add("无影", Type.GetType("System.Double"));
        dt.Columns.Add("价差", Type.GetType("System.Double"));
        dt.Columns.Add("红绿灯涨", Type.GetType("System.Double"));
        dt.Columns.Add("价差abs", Type.GetType("System.Double"));
        dt.Columns.Add("类型", Type.GetType("System.String"));
        dt.Columns.Add("涨幅", Type.GetType("System.Double"));

        dt.Columns.Add("布林宽", Type.GetType("System.Double"));
        for (int i = 0; i <= 10; i++)
        {
            dt.Columns.Add(i.ToString() + "日", Type.GetType("System.Double"));
        }
        dt.Columns.Add("总计", Type.GetType("System.Double"));
        if (!Util.IsTransacDay(currentDate))
        {
            return dt;
        }

        //DateTime lastTransactDate = Util.GetLastTransactDate(currentDate, 2);
        //DateTime limitUpStartDate = Util.GetLastTransactDate(lastTransactDate, 30);

        DataTable dtOri = DBHelper.GetDataTable(" select  * from limit_up where "
            + "  alert_date = '" + Util.GetLastTransactDate(currentDate, 1).ToShortDateString() + "' "
            //+ " and gid = 'sh600053' "
            );

        foreach (DataRow drOri in dtOri.Rows)
        {
            bool isOver3Line = false;
            DateTime alertDate = DateTime.Parse(drOri["alert_date"].ToString().Trim());
            DataRow[] drArrExists = dtOri.Select(" gid = '" + drOri["gid"].ToString() + "' and alert_date > '" + alertDate.ToShortDateString() + "'  ");
            if (drArrExists.Length > 0)
            {
                continue;
            }
            Stock stock = new Stock(drOri["gid"].ToString().Trim(), Util.rc);
            stock.LoadKLineDay(Util.rc);



            KLine.ComputeMACD(stock.kLineDay);
            KLine.ComputeRSV(stock.kLineDay);
            KLine.ComputeKDJ(stock.kLineDay);

            stock.LoadKLineWeek(Util.rc);
            KLine.ComputeRSV(stock.kLineWeek);
            KLine.ComputeKDJ(stock.kLineWeek);
            int klineWeekIndex = stock.GetItemIndex(currentDate.Date, "week");
            int kdjWeeks = stock.kdjWeeks(klineWeekIndex);




            int currentIndex = stock.GetItemIndex(currentDate);
            if (currentIndex < 1 || currentIndex >= stock.kLineDay.Length)
                continue;

            if (!stock.IsLimitUp(currentIndex - 1))
            {
                continue;
            }

            if (stock.kLineDay[currentIndex].startPrice >= stock.kLineDay[currentIndex].endPrice)
            {
                continue;
            }


            if (2 * (stock.kLineDay[currentIndex].highestPrice - stock.kLineDay[currentIndex].endPrice) > (stock.kLineDay[currentIndex].highestPrice - stock.kLineDay[currentIndex].lowestPrice))
            {
                continue;
            }

            double currentVolume = stock.kLineDay[currentIndex].volume;
            double prevVolume = stock.kLineDay[currentIndex - 1].volume;

            if (Math.Abs((currentVolume - prevVolume) / prevVolume) > 0.1)
            {
                //continue;
            }

            if (KLine.ComputeBBWidth(stock.kLineDay, currentIndex-1, 20) >= 0.3)
            {
                //continue;
            }


            int highIndex = 0;
            int lowestIndex = 0;
            double lowest = GetFirstLowestPrice(stock.kLineDay, currentIndex, out lowestIndex);
            double highest = 0;
            highest = Math.Max(stock.kLineDay[currentIndex].highestPrice, stock.kLineDay[currentIndex - 1].highestPrice);





            double avarageVolume = 0;
            for (int i = lowestIndex; i < highIndex; i++)
            {
                avarageVolume = avarageVolume + stock.kLineDay[i].volume;
            }
            avarageVolume = (int)Math.Round((double)avarageVolume / (double)(highIndex - lowestIndex), 0);


            double f3 = highest - (highest - lowest) * 0.382;
            double f5 = highest - (highest - lowest) * 0.618;
            double line3Price = KLine.GetAverageSettlePrice(stock.kLineDay, currentIndex, 3, 3);
            double currentPrice = stock.kLineDay[currentIndex].endPrice;

            string support = "";

            int f5Index = 0;
            int f3Index = 0;
            int over3LineIndex = 0;

            if (f5Index == currentIndex)
            {
                support = "F5";
            }
            if (f3Index == currentIndex)
            {
                support = "F3";
            }
            if (over3LineIndex == currentIndex)
            {
                isOver3Line = true;
            }
            else
            {
                isOver3Line = false;
            }


            double todayLowestPrice = 0;
            DateTime footTime = DateTime.Now;






            //double f3Distance = 0.382 - (highest - stock.kLineDay[currentIndex].lowestPrice) / (highest - lowest);


            double volumeReduce = (stock.kLineDay[currentIndex].volume -  stock.kLineDay[currentIndex - 1].volume) / stock.kLineDay[currentIndex - 1].volume;

            string memo = "";

            if (f3 >= line3Price)
            {
                memo = memo + "<br/>F3在3线之上";
            }

            if (stock.kLineDay[currentIndex].lowestPrice >= f3 * 0.995)
            {
                memo = memo + "<br/>折返在F3之上";
            }



            int limitUpNum = 0;

            DataRow dr = dt.NewRow();

            dr["代码"] = stock.gid.Trim();
            dr["名称"] = stock.Name.Trim();
            dr["KDJ日"] = stock.kdjDays(currentIndex);
            dr["MACD日"] = stock.macdDays(currentIndex);
            dr["今涨"] = (stock.kLineDay[currentIndex].endPrice - stock.kLineDay[currentIndex - 1].endPrice) / stock.kLineDay[currentIndex - 1].endPrice;


            /*
            if (isOver3Line)
            {
                dr["信号"] = "3线";
            }

            dr["信号"] = dr["信号"].ToString() + " " + support.Trim();

            */

            dr["板数"] = limitUpNum;

            double maxPrice = Math.Max(stock.kLineDay[currentIndex - 1].endPrice, stock.kLineDay[currentIndex - 2].endPrice);

            dr["红绿灯涨"] = (stock.kLineDay[currentIndex].endPrice - maxPrice) / maxPrice;



            double width = Math.Round(100 * (highest - lowest) / lowest, 2);




            KLine highKLine = stock.kLineDay[highIndex];






            dr["调整"] = 0;
            dr["缩量"] = volumeReduce;
            dr["现高"] = highest;
            dr["F3"] = f3;
            dr["F5"] = f5;
            dr["前低"] = lowest;
            dr["幅度"] = width.ToString() + "%";


            double f3ReverseRate = (stock.kLineDay[currentIndex].lowestPrice - f3) / f3;
            double f5ReverseRate = (stock.kLineDay[currentIndex].lowestPrice - f5) / f5;
            double supportPrice = 0;
            if (Math.Abs(f3ReverseRate) > Math.Abs(f5ReverseRate))
            {
                dr["价差"] = (stock.kLineDay[currentIndex].lowestPrice - f5);
                supportPrice = f5;
                dr["类型"] = "F5";

            }
            else
            {
                dr["价差"] = (stock.kLineDay[currentIndex].lowestPrice - f3);
                supportPrice = f3;
                dr["类型"] = "F3";


            }



            dr["价差abs"] = Math.Abs((double)dr["价差"]);



            dr["F3折返"] = (stock.kLineDay[currentIndex].lowestPrice - f3) / f3;

            dr["3线"] = line3Price;
            dr["现价"] = currentPrice;

            dr["评级"] = memo;
            //buyPrice = stock.kLineDay[currentIndex].endPrice;


            dr["KDJ日"] = stock.kdjDays(currentIndex);

            dr["MACD日"] = stock.macdDays(currentIndex);

            dr["无影时"] = footTime;
            dr["无影"] = todayLowestPrice;
            maxPrice = 0;
            //buyPrice = supportPrice;
            dr["买入"] = currentPrice;

            dr["涨幅"] = (currentPrice - stock.kLineDay[currentIndex - 1].endPrice) / stock.kLineDay[currentIndex - 1].endPrice;
            dr["红绿灯价"] = 0;


            dr["布林宽"] = Math.Round(KLine.ComputeBBWidth(stock.kLineDay, currentIndex - 1, 20), 2);


            int lastLimitUpInddex = currentIndex;
            for (int i = currentIndex-1; i >= 0 && stock.kLineDay[i].startDateTime.Date >= DateTime.Parse(drOri["alert_date"].ToString().Trim()).Date  ; i--)
            {
                if (stock.IsLimitUp(i))
                {
                    lastLimitUpInddex = i;
                    break;
                }
            }



            dr["0日"] = (stock.kLineDay[currentIndex].highestPrice - stock.kLineDay[currentIndex - 1].endPrice) / stock.kLineDay[currentIndex - 1].endPrice;
            for (int i = 1; i <= 10; i++)
            {

                if (currentIndex + i >= stock.kLineDay.Length)
                    break;
                if (i == 1
                    && stock.kLineDay[currentIndex].startPrice > stock.kLineDay[currentIndex].endPrice
                    && stock.kLineDay[currentIndex + i].startPrice < stock.kLineDay[currentIndex + i].endPrice
                    && stock.kLineDay[currentIndex + i].volume > Math.Max(stock.kLineDay[currentIndex].volume, stock.kLineDay[currentIndex - 1].volume))
                {
                    dr["信号"] = dr["信号"].ToString() + "<a title=\"红绿灯量反包\" >🚥</a>";
                }
                double highPrice = stock.kLineDay[currentIndex + i].highestPrice;
                maxPrice = Math.Max(maxPrice, highPrice);
                dr[i.ToString() + "日"] = (highPrice - stock.kLineDay[currentIndex].endPrice) / stock.kLineDay[currentIndex].endPrice;
            }
            dr["总计"] = (maxPrice - stock.kLineDay[currentIndex].endPrice) / stock.kLineDay[currentIndex].endPrice;

            if (stock.kLineDay[currentIndex].highestPrice == Math.Max(stock.kLineDay[currentIndex].startPrice, stock.kLineDay[currentIndex].endPrice))
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"光头\" >👨‍🦲</a>";
            }

            if (stock.kLineDay[currentIndex - 1].highestPrice < Math.Min(stock.kLineDay[currentIndex].startPrice, stock.kLineDay[currentIndex].endPrice))
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"剑鞘\" >🔪</a>";
            }

            /*
            if (kdjWeeks >= 0 && kdjWeeks <= 2)
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"周线KDJ金叉\" >📈</a>";
            }
            */

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


    protected void btnDownload_Click(object sender, EventArgs e)
    {
        DataTable dtDownload = GetData();
        string content = "";
        foreach (DataRow dr in dtDownload.Rows)
        {
            string gid = dr["代码"].ToString().Trim();
            try
            {
                gid = gid.Substring(gid.IndexOf(">"), gid.Length - gid.IndexOf(">"));
            }
            catch
            {

            }
            gid = gid.Replace("</a>", "").Replace(">", "").ToUpper();
            content += gid + "\r\n";
        }
        Response.Clear();
        Response.ContentType = "text/plain";
        Response.Headers.Add("Content-Disposition", "attachment; filename=traffic_light_"
            + currentDate.ToShortDateString() + ".txt");
        Response.Write(content.Trim());
        Response.End();
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>涨停布林线买入阳线</title>
</head>
<body>
    <form id="form2" runat="server">
    <div>
        <table width="100%" >
            <tr>
                <td><asp:Button runat="server" ID="btnDownload" Text=" 下 载 " OnClick="btnDownload_Click" /></td>
            </tr>
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
                    <asp:BoundColumn DataField="缩量" HeaderText="缩量"></asp:BoundColumn>
                    <asp:BoundColumn DataField="KDJ日" HeaderText="KDJ日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="布林宽" HeaderText="布林宽"></asp:BoundColumn>
                    <asp:BoundColumn DataField="信号" HeaderText="信号"></asp:BoundColumn>
                    <asp:BoundColumn DataField="3线" HeaderText="3线"></asp:BoundColumn>
                    <asp:BoundColumn DataField="现高" HeaderText="现高"></asp:BoundColumn>
                    <asp:BoundColumn DataField="F3" HeaderText="F3"></asp:BoundColumn>
                    <asp:BoundColumn DataField="F5" HeaderText="F5"></asp:BoundColumn>
                    <asp:BoundColumn DataField="前低" HeaderText="前低"></asp:BoundColumn>
                    <asp:BoundColumn DataField="幅度" HeaderText="幅度"></asp:BoundColumn>
                    <asp:BoundColumn DataField="现价" HeaderText="现价"></asp:BoundColumn>
                    <asp:BoundColumn DataField="买入" HeaderText="买入"  ></asp:BoundColumn>
                    
                    <asp:BoundColumn DataField="今涨" HeaderText="今涨"  ></asp:BoundColumn>
                    <asp:BoundColumn DataField="0日" HeaderText="0日"></asp:BoundColumn>
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
        </table>
    </div>
    </form>
</body>
</html>
