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
            calendar.SelectedDate = DateTime.Now;
            /*
            DataTable dt = GetData1();
            AddTotal(dt);
            dg.DataSource = dt;
            dg.DataBind();
            */
            dg.DataSource = GetDataFull();
            dg.DataBind();
        }

    }

    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {
        DataTable dt = GetDataFull();
        //AddTotal(dt);
        dg.DataSource = dt;
        dg.DataBind();
    }

    public DataTable GetDataFull()
    {
        DateTime currentDate = DateTime.Parse(calendar.SelectedDate.ToShortDateString());
        DataTable dtOri = DBHelper.GetDataTable(" select * from suggest_stock where suggest_date = '" + currentDate.ToShortDateString()
                + "'  order by  ((highest_5_day - [open]) / [open]) desc, ((highest_4_day - [open]) / [open]) desc, "
                + " ((highest_3_day - [open]) / [open]) desc, ((highest_2_day - [open]) / [open]) desc , "
                + " ((highest_1_day - [open]) / [open]) desc , ((highest_0_day - [open]) / [open]) desc , (([open] - settlement) / settlement) desc ");
        if (dtOri.Rows.Count == 0)
        {
            if (currentDate == DateTime.Parse(DateTime.Now.ToShortDateString()))
            {
                ThreadStart ts = new ThreadStart(Util.RefreshSuggestStockForToday);
                ////Util.RefreshSuggestStockForToday();
                Thread t = new Thread(ts);
                t.Start();
            }
            else
            {
                Util.RefreshSuggestStock(currentDate);
            }
            dtOri = DBHelper.GetDataTable(" select * from suggest_stock where suggest_date = '" + currentDate.ToShortDateString()
                + "'  order by  ((highest_5_day - [open]) / [open]) desc, ((highest_4_day - [open]) / [open]) desc, "
                + " ((highest_3_day - [open]) / [open]) desc, ((highest_2_day - [open]) / [open]) desc , "
                + " ((highest_1_day - [open]) / [open]) desc , ((highest_0_day - [open]) / [open]) desc , (([open] - settlement) / settlement) desc ");
        }

        DataTable dtKdj = DBHelper.GetDataTable(" select * from kdj_alert where alert_time > '" + currentDate.ToShortDateString() + "' and alert_time < '" + currentDate.AddDays(1).ToShortDateString() + "'   ");


        int[] starCount = new int[6] { 0, 0, 0, 0, 0, 0};
        int starTotal = 0;
        int[] kdjCount = new int[6] { 0, 0, 0, 0, 0, 0};
        int kdjTotal = 0;

        int starKdjTotal = 0;
        int[] starKdjCount = new int[6] { 0, 0, 0, 0, 0, 0};

        int[] oxStarKdjCount = new int[6] { 0, 0, 0, 0, 0, 0};
        int oxStarKdjTotal = 0;

        int[] allCount = new int[6] { 0, 0, 0, 0, 0, 0};

        DataTable dt = new DataTable();
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("信号");
        dt.Columns.Add("9日低价");
        dt.Columns.Add("支撑");
        dt.Columns.Add("现价");
        dt.Columns.Add("压力");
        dt.Columns.Add("9日高价");
        dt.Columns.Add("9日振幅");
        dt.Columns.Add("今开");
        dt.Columns.Add("KDJ买入价");
        dt.Columns.Add("跳空幅度");
        dt.Columns.Add("今日最高");
        dt.Columns.Add("重心");
        dt.Columns.Add("1日最高");
        dt.Columns.Add("2日最高");
        dt.Columns.Add("3日最高");
        dt.Columns.Add("4日最高");
        dt.Columns.Add("5日最高");
        dt.Columns.Add("总计");
        foreach (DataRow drOri in dtOri.Rows)
        {
            if (drOri["gid"].ToString().Trim().Equals("sz002758"))
            {
                string aa = "aa";
            }
            DataRow dr = dt.NewRow();
            dr["代码"] = "<a href=\"show_k_line_day.aspx?gid=" + drOri["gid"].ToString().Trim() + "&name="
                + Server.UrlEncode(drOri["name"].ToString().Trim()) + "\" target=\"_blank\" >"
                +  drOri["gid"].ToString().Trim().Remove(0, 2) + "</a>";
            dr["名称"] = drOri["name"].ToString().Trim();
            dr["今开"] = drOri["open"].ToString().Trim();
            dr["信号"] = dr["信号"].ToString() + (IsOx(drOri) ? "<a title=\"20交易日内两次穿越3线\" >🐂</a>" : "");
            dr["信号"] = dr["信号"].ToString() + (IsStar(drOri) ? "<a alt=\"" + drOri["gid"].ToString().Trim().Remove(0, 2) + "\"  title=\"两日连涨，跳空和涨幅在特定范围内，昨日收阳，并且最高价和收盘价差在1%以内\" >🌟</a>" : "");
            dr["信号"] = dr["信号"].ToString() + (IsKdjAlert(drOri, dtKdj) ? "<a alt=\"" + drOri["gid"].ToString().Trim().Remove(0, 2) + "\"  title=\"KDJ买入\" >📈</a>" : "");

            if (dr["信号"].ToString().IndexOf("🌟") >= 0)
                starTotal++;
            if (dr["信号"].ToString().IndexOf("📈") >= 0)
                kdjTotal++;
            if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
            {
                starKdjTotal++;
            }
            if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0 && dr["信号"].ToString().IndexOf("🐂") >= 0)
            {
                oxStarKdjTotal++;
            }


            double jumpEmptyRate = Math.Round(((double.Parse(drOri["open"].ToString().Trim()) - double.Parse(drOri["settlement"].ToString().Trim()))
                / double.Parse(drOri["settlement"].ToString().Trim())) * 100, 2);

            if (jumpEmptyRate == -100)
            {
                dr["跳空幅度"] = "-";
            }
            else
            {
                dr["跳空幅度"] =  "<font color=\"" + (jumpEmptyRate >=1.5? "red": (jumpEmptyRate < 0.75? "green" : "black")) + "\" >"
                + jumpEmptyRate.ToString() + "%</font>";

            }

            double highestPrice = 0;

            if (drOri["highest_0_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(drOri["gid"].ToString().Trim(), currentDate, 0);
            }
            else
            {
                highestPrice = double.Parse(drOri["highest_0_day"].ToString().Trim());
            }

            double rateToday = Math.Round(((highestPrice - double.Parse(drOri["open"].ToString().Trim()))
                / double.Parse(drOri["open"].ToString().Trim())) * 100, 2);
            dr["今日最高"] = "<font color=\"" + (rateToday >=1? "red": (rateToday < 0? "green" : "black")) + "\" >" + rateToday.ToString() + "%</font>";


            Stock stock = new Stock(drOri["gid"].ToString().Trim());
            stock.kArr = KLine.GetLocalKLine(stock.gid, "day");
            double currentDayPrice = (currentDate == DateTime.Parse(DateTime.Now.ToShortDateString())) ? stock.LastTrade : double.Parse(drOri["open"].ToString().Trim()) * 1.01;
            double minPrice = stock.LowestPrice(DateTime.Now, 9);
            double maxPrice = stock.HighestPrice(DateTime.Now, 9);
            double pressure = Stock.GetPressure(currentDayPrice , minPrice, maxPrice);
            double support = Stock.GetSupport(currentDayPrice , minPrice, maxPrice);
            dr["9日低价"] = Math.Round(minPrice, 2).ToString();
            dr["支撑"] = Math.Round(support, 2).ToString();
            dr["现价"] = Math.Round(currentDayPrice, 2).ToString();
            dr["压力"] = Math.Round(pressure, 2).ToString();
            dr["9日高价"] = Math.Round(maxPrice, 2).ToString();
            dr["9日振幅"] = Math.Round((maxPrice - minPrice) * 100 / minPrice, 2).ToString() + "%";
            dr["今开"] = Math.Round(double.Parse(drOri["open"].ToString()), 2).ToString();
            double buyPrice = double.Parse(drOri["open"].ToString()) * 1.01;
            if (dr["信号"].ToString().IndexOf("📈") >= 0)
            {
                DataRow[] kdjArr = dtKdj.Select(" gid = '" + drOri["gid"].ToString() + "'  ");
                if (kdjArr.Length > 0)
                    buyPrice = double.Parse(kdjArr[kdjArr.Length - 1]["price"].ToString());
            }
            dr["kdj买入价"] = (buyPrice != (double.Parse(drOri["open"].ToString().Trim()) * 1.01 )) ? Math.Round(buyPrice, 2).ToString() : "-";
            dr["重心"] = Math.Round( 100* (currentDayPrice - minPrice) / (maxPrice - minPrice),2);

            double rate = 0;
            double rateMax = -100;
            int valve = 2;

            if (drOri["highest_1_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(drOri["gid"].ToString().Trim(), currentDate, 1);
            }
            else
            {
                highestPrice = double.Parse(drOri["highest_1_day"].ToString().Trim());
            }

            rate = Math.Round(((highestPrice - buyPrice) / buyPrice) * 100, 2);
            rateMax = Math.Max(rate, rateMax);
            if (rate == -100)
            {
                dr["1日最高"] = "-";
            }
            else
            {
                dr["1日最高"] =  "<font color=\"" + (rate >=valve ? "red": (rate < 0? "green" : "black")) + "\" >"
                + rate.ToString() + "%</font>";


                if (dr["1日最高"].ToString().IndexOf("red") >= 0)
                {
                    allCount[0]++;
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0)
                        starCount[0]++;
                    if (dr["信号"].ToString().IndexOf("📈") >= 0)
                        kdjCount[0]++;
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                    {
                        starKdjCount[0]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0 && dr["信号"].ToString().IndexOf("🐂") >= 0)
                    {
                        oxStarKdjCount[0]++;
                    }
                }


            }

            if (drOri["highest_2_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(drOri["gid"].ToString().Trim(), currentDate, 2);
            }
            else
            {
                highestPrice = double.Parse(drOri["highest_2_day"].ToString().Trim());
            }

            rate = Math.Round(((highestPrice - buyPrice) / buyPrice) * 100, 2);
            rateMax = Math.Max(rate, rateMax);
            if (rate == -100)
            {
                dr["2日最高"] = "-";
            }
            else
            {
                dr["2日最高"] =  "<font color=\"" + (rate >=valve ? "red": (rate < 0? "green" : "black")) + "\" >"
                + rate.ToString() + "%</font>";
                if (dr["2日最高"].ToString().IndexOf("red") >= 0)
                {
                    allCount[1]++;
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0)
                        starCount[1]++;
                    if (dr["信号"].ToString().IndexOf("📈") >= 0)
                        kdjCount[1]++;
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                    {
                        starKdjCount[1]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0 && dr["信号"].ToString().IndexOf("🐂") >= 0)
                    {
                        oxStarKdjCount[1]++;
                    }
                }
            }

            if (drOri["highest_3_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(drOri["gid"].ToString().Trim(), currentDate, 3);
            }
            else
            {
                highestPrice = double.Parse(drOri["highest_3_day"].ToString().Trim());
            }

            rate = Math.Round(((highestPrice - buyPrice) / buyPrice) * 100, 2);
            rateMax = Math.Max(rate, rateMax);
            if (rate == -100)
            {
                dr["3日最高"] = "-";
            }
            else
            {
                dr["3日最高"] =  "<font color=\"" + (rate >=valve ? "red": (rate < 0? "green" : "black")) + "\" >"
                + rate.ToString() + "%</font>";

                if (dr["3日最高"].ToString().IndexOf("red") >= 0)
                {
                    allCount[2]++;
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0)
                        starCount[2]++;
                    if (dr["信号"].ToString().IndexOf("📈") >= 0)
                        kdjCount[2]++;
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                    {
                        starKdjCount[2]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0 && dr["信号"].ToString().IndexOf("🐂") >= 0)
                    {
                        oxStarKdjCount[2]++;
                    }
                }
            }

            if (drOri["highest_4_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(drOri["gid"].ToString().Trim(), currentDate, 4);
            }
            else
            {
                highestPrice = double.Parse(drOri["highest_4_day"].ToString().Trim());
            }

            rate = Math.Round(((highestPrice - buyPrice) / buyPrice) * 100, 2);
            rateMax = Math.Max(rate, rateMax);
            if (rate == -100)
            {
                dr["4日最高"] = "-";
            }
            else
            {
                dr["4日最高"] =  "<font color=\"" + (rate >=valve ? "red": (rate < 0? "green" : "black")) + "\" >"
                + rate.ToString() + "%</font>";
                if (dr["4日最高"].ToString().IndexOf("red") >= 0)
                {
                    allCount[3]++;
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0)
                        starCount[3]++;
                    if (dr["信号"].ToString().IndexOf("📈") >= 0)
                        kdjCount[3]++;
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                    {
                        starKdjCount[3]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0 && dr["信号"].ToString().IndexOf("🐂") >= 0)
                    {
                        oxStarKdjCount[3]++;
                    }
                }
            }

            if (drOri["highest_5_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(drOri["gid"].ToString().Trim(), currentDate, 5);
            }
            else
            {
                highestPrice = double.Parse(drOri["highest_5_day"].ToString().Trim());
            }

            rate = Math.Round(((highestPrice - buyPrice) / buyPrice) * 100, 2);
            rateMax = Math.Max(rate, rateMax);
            if (rate == -100)
            {
                dr["5日最高"] = "-";
            }
            else
            {
                dr["5日最高"] =  "<font color=\"" + (rate >=valve ? "red": (rate < 0? "green" : "black")) + "\" >"
                + rate.ToString() + "%</font>";
                if (dr["5日最高"].ToString().IndexOf("red") >= 0)
                {
                    allCount[4]++;
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0)
                        starCount[4]++;
                    if (dr["信号"].ToString().IndexOf("📈") >= 0)
                        kdjCount[4]++;
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                    {
                        starKdjCount[4]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0 && dr["信号"].ToString().IndexOf("🐂") >= 0)
                    {
                        oxStarKdjCount[4]++;
                    }
                }
            }

            dr["总计"] = "<font color=\"" + (rateMax >=valve ? "red": (rateMax < 0? "green" : "black")) + "\" >"
                + rateMax.ToString() + "%</font>";
            if (dr["总计"].ToString().IndexOf("red") >= 0)
            {
                allCount[5]++;
                if (dr["信号"].ToString().IndexOf("🌟") >= 0)
                    starCount[5]++;
                if (dr["信号"].ToString().IndexOf("📈") >= 0)
                    kdjCount[5]++;
                if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                {
                    starKdjCount[5]++;
                }
                if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0 && dr["信号"].ToString().IndexOf("🐂") >= 0)
                {
                    oxStarKdjCount[5]++;
                }
            }
            dt.Rows.Add(dr);
        }

        DataRow drTotal = dt.NewRow();
        drTotal["名称"] = "总计：";
        drTotal["1日最高"] = Math.Round(100 * (double)allCount[0] / (double)dt.Rows.Count, 2).ToString() + "%";
        drTotal["2日最高"] = Math.Round(100 * (double)allCount[1] / (double)dt.Rows.Count, 2).ToString() + "%";
        drTotal["3日最高"] = Math.Round(100 * (double)allCount[2] / (double)dt.Rows.Count, 2).ToString() + "%";
        drTotal["4日最高"] = Math.Round(100 * (double)allCount[3] / (double)dt.Rows.Count, 2).ToString() + "%";
        drTotal["5日最高"] = Math.Round(100 * (double)allCount[4] / (double)dt.Rows.Count, 2).ToString() + "%";
        drTotal["总计"] = Math.Round(100 * (double)allCount[5] / (double)dt.Rows.Count, 2).ToString() + "%";
        dt.Rows.Add(drTotal);
        DataRow drStar = dt.NewRow();
        drStar["名称"] = "🌟";
        drStar["1日最高"] = Math.Round(100 * (double)starCount[0] / (double)starTotal, 2).ToString() + "%";
        drStar["2日最高"] = Math.Round(100 * (double)starCount[1] / (double)starTotal, 2).ToString() + "%";
        drStar["3日最高"] = Math.Round(100 * (double)starCount[2] / (double)starTotal, 2).ToString() + "%";
        drStar["4日最高"] = Math.Round(100 * (double)starCount[3] / (double)starTotal, 2).ToString() + "%";
        drStar["5日最高"] = Math.Round(100 * (double)starCount[4] / (double)starTotal, 2).ToString() + "%";
        drStar["总计"] = Math.Round(100 * (double)starCount[5] / (double)starTotal, 2).ToString() + "%";
        dt.Rows.Add(drStar);

        DataRow drKdj = dt.NewRow();
        drKdj["名称"] = "📈";
        drKdj["1日最高"] = Math.Round(100 * (double)kdjCount[0] / (double)kdjTotal, 2).ToString() + "%";
        drKdj["2日最高"] = Math.Round(100 * (double)kdjCount[1] / (double)kdjTotal, 2).ToString() + "%";
        drKdj["3日最高"] = Math.Round(100 * (double)kdjCount[2] / (double)kdjTotal, 2).ToString() + "%";
        drKdj["4日最高"] = Math.Round(100 * (double)kdjCount[3] / (double)kdjTotal, 2).ToString() + "%";
        drKdj["5日最高"] = Math.Round(100 * (double)kdjCount[4] / (double)kdjTotal, 2).ToString() + "%";
        drKdj["总计"] = Math.Round(100 * (double)kdjCount[5] / (double)kdjTotal, 2).ToString() + "%";
        dt.Rows.Add(drKdj);

        DataRow drStarKdj = dt.NewRow();
        drStarKdj["名称"] = "🌟📈";
        drStarKdj["1日最高"] = Math.Round(100 * (double)starKdjCount[0] / (double)starKdjTotal, 2).ToString() + "%";
        drStarKdj["2日最高"] = Math.Round(100 * (double)starKdjCount[1] / (double)starKdjTotal, 2).ToString() + "%";
        drStarKdj["3日最高"] = Math.Round(100 * (double)starKdjCount[2] / (double)starKdjTotal, 2).ToString() + "%";
        drStarKdj["4日最高"] = Math.Round(100 * (double)starKdjCount[3] / (double)starKdjTotal, 2).ToString() + "%";
        drStarKdj["5日最高"] = Math.Round(100 * (double)starKdjCount[4] / (double)starKdjTotal, 2).ToString() + "%";
        drStarKdj["总计"] = Math.Round(100 * (double)starKdjCount[5] / (double)starKdjTotal, 2).ToString() + "%";
        dt.Rows.Add(drStarKdj);

        DataRow drOxStarKdj = dt.NewRow();
        drOxStarKdj["名称"] = "🐂🌟📈";
        drOxStarKdj["1日最高"] = Math.Round(100 * (double)oxStarKdjCount[0] / (double)oxStarKdjTotal, 2).ToString() + "%";
        drOxStarKdj["2日最高"] = Math.Round(100 * (double)oxStarKdjCount[1] / (double)oxStarKdjTotal, 2).ToString() + "%";
        drOxStarKdj["3日最高"] = Math.Round(100 * (double)oxStarKdjCount[2] / (double)oxStarKdjTotal, 2).ToString() + "%";
        drOxStarKdj["4日最高"] = Math.Round(100 * (double)oxStarKdjCount[3] / (double)oxStarKdjTotal, 2).ToString() + "%";
        drOxStarKdj["5日最高"] = Math.Round(100 * (double)oxStarKdjCount[4] / (double)oxStarKdjTotal, 2).ToString() + "%";
        drOxStarKdj["总计"] = Math.Round(100 * (double)oxStarKdjCount[5] / (double)oxStarKdjTotal, 2).ToString() + "%";
        dt.Rows.Add(drOxStarKdj);

        return dt;
    }



    public bool IsStar(DataRow dr)
    {
        DateTime currentDate = DateTime.Parse(calendar.SelectedDate.ToShortDateString());
        double  jumpRate = (double.Parse(dr["open"].ToString()) - double.Parse(dr["settlement"].ToString().Trim()))
            / double.Parse(dr["settlement"].ToString().Trim());
        double highestPrice = 0;
        if (dr["highest_0_day"].ToString().Equals("0"))
        {
            highestPrice = GetNextNDayHighest(dr["gid"].ToString().Trim(), currentDate, 0);
        }
        else
        {
            highestPrice = double.Parse(dr["highest_0_day"].ToString().Trim());
        }
        double rate = Math.Round(((highestPrice - double.Parse(dr["open"].ToString().Trim()))
                / double.Parse(dr["open"].ToString().Trim())) * 100, 2);
        if ( ( (jumpRate < 0.004 || (jumpRate > 0.01 && jumpRate < 0.07))
              && (rate > 1) && double.Parse(dr["last_day_over_flow"].ToString()) > 0)
              || (jumpRate < 0 &&  double.Parse(dr["last_day_over_flow"].ToString()) > 0 && rate > 3) )
            return true;
        else
            return false;
    }

    public bool IsOx(DataRow dr)
    {
        if (dr["double_cross_3_3"].ToString().Equals("1"))
            return true;
        else
            return false;
    }


    public bool IsKdjAlert(DataRow dr, DataTable dtKdj)
    {
        DataRow[] drKdjArr = dtKdj.Select(" gid = '" + dr["gid"].ToString().Trim() + "' and  (type = 'day'  ) ");
        if (drKdjArr.Length > 0)
            return true;
        else
            return false;
    }



    public static void AddTotal(DataTable dt)
    {

        Regex reg = new Regex(@"\d+\.*\d*");

        int red0 = 0;
        int red1 = 0;
        int red2 = 0;
        int red3 = 0;
        int red4 = 0;
        int red5 = 0;
        int total = dt.Rows.Count;
        int subTotalCount = 0;


        int countOxCandlePoly = 0;
        int d1OxCandlePoly = 0;
        int d2OxCandlePoly = 0;
        int d3OxCandlePoly = 0;
        int d4OxCandlePoly = 0;
        int d5OxCandlePoly = 0;

        int starCount = 0;
        int starD1 = 0;
        int starD2 = 0;
        int starD3 = 0;
        int starD4 = 0;
        int starD5 = 0;

        int candlePolyCount = 0;
        int candlePolyD1 = 0;
        int candlePolyD2 = 0;
        int candlePolyD3 = 0;
        int candlePolyD4 = 0;
        int candlePolyD5 = 0;

        int oxStarCount = 0;
        int oxStarD1 = 0;
        int oxStarD2 = 0;
        int oxStarD3 = 0;
        int oxStarD4 = 0;
        int oxStarD5 = 0;

        int sunCount = 0;
        int sunD3 = 0;
        int sunD4 = 0;
        int sunD5 = 0;

        int sunOxCount = 0;
        int sunOxD3 = 0;
        int sunOxD4 = 0;
        int sunOxD5 = 0;

        int oxStarDT = 0;
        int starDT = 0;
        int sunDT = 0;
        int oxSunDT = 0;

        foreach (DataRow dr in dt.Rows)
        {

            if (dr["总计"].ToString().IndexOf("red") >= 0)
            {
                if (dr["名称"].ToString().Trim().IndexOf("🌟") >= 0)
                {
                    starDT++;
                    if (dr["名称"].ToString().Trim().IndexOf("🐂") >= 0)
                    {
                        oxStarDT++;
                    }
                }
                if (dr["名称"].ToString().Trim().IndexOf("🌞") >= 0)
                {
                    sunDT++;
                    if (dr["名称"].ToString().Trim().IndexOf("🐂") >= 0)
                    {
                        oxSunDT++;
                    }
                }
            }

            if (dr["今日最高"].ToString().IndexOf("red") > 0)
                red0++;
            if (dr["1日最高"].ToString().IndexOf("red") > 0)
                red1++;
            if (dr["2日最高"].ToString().IndexOf("red") > 0)
                red2++;
            if (dr["3日最高"].ToString().IndexOf("red") > 0)
                red3++;
            if (dr["4日最高"].ToString().IndexOf("red") > 0)
                red4++;
            if (dr["5日最高"].ToString().IndexOf("red") > 0)
                red5++;
            if (dr["总计"].ToString().IndexOf("red") >= 0)
                subTotalCount++;
            /*
            if ((dr["跳空幅度"].ToString().IndexOf("green") >= 0 && dr["今日最高"].ToString().IndexOf("black") >= 0)
                || (dr["跳空幅度"].ToString().IndexOf("black") >= 0 && dr["今日最高"].ToString().IndexOf("red") >= 0))
                dr["名称"] = dr["名称"].ToString() + "📈";
                */
            if (dr["名称"].ToString().IndexOf("🌟") >= 0)
            {
                starCount++;
                if (dr["1日最高"].ToString().IndexOf("red") > 0)
                    starD1++;
                if (dr["2日最高"].ToString().IndexOf("red") > 0)
                    starD2++;
                if (dr["3日最高"].ToString().IndexOf("red") > 0)
                    starD3++;
                if (dr["4日最高"].ToString().IndexOf("red") > 0)
                    starD4++;
                if (dr["5日最高"].ToString().IndexOf("red") > 0)
                    starD5++;
            }

            if (dr["名称"].ToString().IndexOf("🕯️") >= 0 && dr["名称"].ToString().IndexOf("📈") >= 0)
            {
                candlePolyCount++;
                if (dr["1日最高"].ToString().IndexOf("red") > 0)
                    candlePolyD1++;
                if (dr["2日最高"].ToString().IndexOf("red") > 0)
                    candlePolyD2++;
                if (dr["3日最高"].ToString().IndexOf("red") > 0)
                    candlePolyD3++;
                if (dr["4日最高"].ToString().IndexOf("red") > 0)
                    candlePolyD4++;
                if (dr["5日最高"].ToString().IndexOf("red") > 0)
                    candlePolyD5++;
            }

            if (dr["名称"].ToString().IndexOf("🐂") >= 0 && dr["名称"].ToString().IndexOf("🕯️") >= 0 && dr["名称"].ToString().IndexOf("📈") >= 0)
            {
                countOxCandlePoly++;

                if (dr["1日最高"].ToString().IndexOf("red") > 0)
                    d1OxCandlePoly++;
                if (dr["2日最高"].ToString().IndexOf("red") > 0)
                    d2OxCandlePoly++;
                if (dr["3日最高"].ToString().IndexOf("red") > 0)
                    d3OxCandlePoly++;
                if (dr["4日最高"].ToString().IndexOf("red") > 0)
                    d4OxCandlePoly++;
                if (dr["5日最高"].ToString().IndexOf("red") > 0)
                    d5OxCandlePoly++;
            }

            if (dr["名称"].ToString().IndexOf("🐂") >= 0  && dr["名称"].ToString().IndexOf("🌟") >= 0 )
            {
                oxStarCount++;
                if (dr["1日最高"].ToString().IndexOf("red") > 0)
                    oxStarD1++;
                if (dr["2日最高"].ToString().IndexOf("red") > 0)
                    oxStarD2++;
                if (dr["3日最高"].ToString().IndexOf("red") > 0)
                    oxStarD3++;
                if (dr["4日最高"].ToString().IndexOf("red") > 0)
                    oxStarD4++;
                if (dr["5日最高"].ToString().IndexOf("red") > 0)
                    oxStarD5++;
            }

            if (dr["名称"].ToString().IndexOf("🌞") >= 0)
            {

                sunCount++;
                double settlement = GetPercentValue(dr["2日收盘"].ToString()); //double.Parse(Getdr["2日收盘"].ToString()));
                if (!dr["3日最高"].ToString().Trim().Equals("-"))
                {
                    double d3Highest = GetPercentValue(dr["3日最高"].ToString());
                    if (d3Highest >= settlement + 1)
                        sunD3++;
                }

                if (!dr["4日最高"].ToString().Trim().Equals("-"))
                {
                    double d4Highest = GetPercentValue(dr["4日最高"].ToString());
                    if (d4Highest >= settlement + 1)
                        sunD4++;
                }

                if (!dr["5日最高"].ToString().Trim().Equals("-"))
                {
                    double d5Highest = GetPercentValue(dr["5日最高"].ToString());
                    if (d5Highest >= settlement + 1)
                        sunD5++;
                }
            }

            if (dr["名称"].ToString().Trim().IndexOf("🐂") >= 0 && dr["名称"].ToString().Trim().IndexOf("🌞") >= 0)
            {
                sunOxCount++;
                double settlement = GetPercentValue(dr["2日收盘"].ToString());
                if (!dr["3日最高"].ToString().Trim().Equals("-"))
                {
                    double d3Highest = GetPercentValue(dr["3日最高"].ToString());
                    if (d3Highest >= settlement + 1)
                        sunOxD3++;
                }

                if (!dr["4日最高"].ToString().Trim().Equals("-"))
                {
                    double d4Highest = GetPercentValue(dr["4日最高"].ToString());
                    if (d4Highest >= settlement + 1)
                        sunOxD4++;
                }

                if (!dr["5日最高"].ToString().Trim().Equals("-"))
                {
                    double d5Highest = GetPercentValue(dr["5日最高"].ToString());
                    if (d5Highest >= settlement + 1)
                        sunOxD5++;
                }
            }
        }
        DataRow drTotal = dt.NewRow();
        drTotal["代码"] = "";
        drTotal["名称"] = "";
        drTotal["今开"] = "";
        drTotal["跳空幅度"] = "";
        drTotal["今日最高"] = (Math.Round(10000 * (double)red0 / (double)total) / 100).ToString() + "%";
        drTotal["1日最高"] = (Math.Round(10000 * (double)red1 / (double)total) / 100).ToString() + "%";
        drTotal["2日最高"] = (Math.Round(10000 * (double)red2 / (double)total) / 100).ToString() + "%";
        drTotal["3日最高"] = (Math.Round(10000 * (double)red3 / (double)total) / 100).ToString() + "%";
        drTotal["4日最高"] = (Math.Round(10000 * (double)red4 / (double)total) / 100).ToString() + "%";
        drTotal["5日最高"] = (Math.Round(10000 * (double)red5 / (double)total) / 100).ToString() + "%";
        drTotal["总计"] = (Math.Round(10000 * (double)subTotalCount / (double)total) / 100).ToString() + "%";
        dt.Rows.Add(drTotal);

        /*
        DataRow drCandlePoly = dt.NewRow();
        drCandlePoly["代码"] = "🕯️📈";
        drCandlePoly["名称"] = "";
        drCandlePoly["今开"] = "";
        drCandlePoly["跳空幅度"] = "";
        drCandlePoly["今日最高"] = "";
        drCandlePoly["1日最高"] = (Math.Round(10000 * (double)candlePolyD1 / (double)candlePolyCount) / 100).ToString() + "%";
        drCandlePoly["2日最高"] = (Math.Round(10000 * (double)candlePolyD2 / (double)candlePolyCount) / 100).ToString() + "%";
        drCandlePoly["3日最高"] = (Math.Round(10000 * (double)candlePolyD3 / (double)candlePolyCount) / 100).ToString() + "%";
        drCandlePoly["4日最高"] = (Math.Round(10000 * (double)candlePolyD4 / (double)candlePolyCount) / 100).ToString() + "%";
        drCandlePoly["5日最高"] = (Math.Round(10000 * (double)candlePolyD5 / (double)candlePolyCount) / 100).ToString() + "%";
        dt.Rows.Add(drCandlePoly);
        */
        DataRow drStar = dt.NewRow();

        drStar["代码"] = "🌟";
        drStar["名称"] = "";
        drStar["今开"] = "";
        drStar["跳空幅度"] = "";
        drStar["今日最高"] = "";
        drStar["1日最高"] = (Math.Round(10000 * (double)starD1 / (double)starCount) / 100).ToString() + "%";
        drStar["2日最高"] = (Math.Round(10000 * (double)starD2 / (double)starCount) / 100).ToString() + "%";
        drStar["3日最高"] = (Math.Round(10000 * (double)starD3 / (double)starCount) / 100).ToString() + "%";
        drStar["4日最高"] = (Math.Round(10000 * (double)starD4 / (double)starCount) / 100).ToString() + "%";
        drStar["5日最高"] = (Math.Round(10000 * (double)starD5 / (double)starCount) / 100).ToString() + "%";
        drStar["总计"] = (Math.Round(10000 * (double)starDT / (double)starCount) / 100).ToString() + "%";
        dt.Rows.Add(drStar);
        /*
        DataRow drOxCandlePoly = dt.NewRow();
        drOxCandlePoly["代码"] = "🐂🕯️📈";
        drOxCandlePoly["名称"] = "";
        drOxCandlePoly["今开"] = "";
        drOxCandlePoly["跳空幅度"] = "";
        drOxCandlePoly["今日最高"] = "";
        drOxCandlePoly["1日最高"] = (Math.Round(10000 * (double)d1OxCandlePoly / (double)countOxCandlePoly) / 100).ToString() + "%";
        drOxCandlePoly["2日最高"] = (Math.Round(10000 * (double)d2OxCandlePoly / (double)countOxCandlePoly) / 100).ToString() + "%";
        drOxCandlePoly["3日最高"] = (Math.Round(10000 * (double)d3OxCandlePoly / (double)countOxCandlePoly) / 100).ToString() + "%";
        drOxCandlePoly["4日最高"] = (Math.Round(10000 * (double)d4OxCandlePoly / (double)countOxCandlePoly) / 100).ToString() + "%";
        drOxCandlePoly["5日最高"] = (Math.Round(10000 * (double)d5OxCandlePoly / (double)countOxCandlePoly) / 100).ToString() + "%";
        dt.Rows.Add(drOxCandlePoly);
        */

        DataRow drOxStar = dt.NewRow();
        drOxStar["代码"] = "🐂🌟";
        drOxStar["今开"] = "";
        drOxStar["跳空幅度"] = "";
        drOxStar["今日最高"] = "";
        drOxStar["1日最高"] = (Math.Round(10000 * (double)oxStarD1 / (double)oxStarCount) / 100).ToString() + "%";
        drOxStar["2日最高"] = (Math.Round(10000 * (double)oxStarD2 / (double)oxStarCount) / 100).ToString() + "%";
        drOxStar["3日最高"] = (Math.Round(10000 * (double)oxStarD3 / (double)oxStarCount) / 100).ToString() + "%";
        drOxStar["4日最高"] = (Math.Round(10000 * (double)oxStarD4 / (double)oxStarCount) / 100).ToString() + "%";
        drOxStar["5日最高"] = (Math.Round(10000 * (double)oxStarD5 / (double)oxStarCount) / 100).ToString() + "%";
        drOxStar["总计"] = (Math.Round(10000 * (double)oxStarDT / (double)oxStarCount) / 100).ToString() + "%";
        dt.Rows.Add(drOxStar);

        DataRow drSun = dt.NewRow();
        drSun["代码"] = "🌞";
        drSun["今开"] = "";
        drSun["跳空幅度"] = "";
        drSun["今日最高"] = "";
        drSun["1日最高"] = "";
        drSun["2日最高"] = "";
        //drSun["2日收盘"] = "";
        drSun["3日最高"] = (Math.Round(10000 * (double)sunD3 / (double)sunCount) / 100).ToString() + "%";
        drSun["4日最高"] = (Math.Round(10000 * (double)sunD4 / (double)sunCount) / 100).ToString() + "%";
        drSun["5日最高"] = (Math.Round(10000 * (double)sunD5 / (double)sunCount) / 100).ToString() + "%";
        drSun["总计"] = (Math.Round(10000 * (double)sunDT / (double)sunCount) / 100).ToString() + "%";
        dt.Rows.Add(drSun);

        DataRow drSunOx = dt.NewRow();
        drSunOx["代码"] = "🐂🌞";
        drSunOx["今开"] = "";
        drSunOx["跳空幅度"] = "";
        drSunOx["今日最高"] = "";
        drSunOx["1日最高"] = "";
        drSunOx["2日最高"] = "";
        drSunOx["2日收盘"] = "";
        drSunOx["3日最高"] = (Math.Round(10000 * (double)sunOxD3 / (double)sunOxCount) / 100).ToString() + "%";
        drSunOx["4日最高"] = (Math.Round(10000 * (double)sunOxD4 / (double)sunOxCount) / 100).ToString() + "%";
        drSunOx["5日最高"] = (Math.Round(10000 * (double)sunOxD5 / (double)sunOxCount) / 100).ToString() + "%";
        drSunOx["总计"] = (Math.Round(10000 * (double)oxSunDT / (double)sunOxCount) / 100).ToString() + "%";
        dt.Rows.Add(drSunOx);


    }

    public static double GetNextNDayHighest(string gid, DateTime currentDate, int n)
    {
        if (currentDate.AddDays(n) > DateTime.Parse(DateTime.Now.ToShortDateString()))
            return 0;
        KLine[] kArr = KLine.GetKLineDayFromSohu(gid, currentDate.AddDays(-20), DateTime.Parse(DateTime.Now.ToShortDateString()));
        double ret = 0;
        int k = -1;
        for (int i = 0; i < kArr.Length; i++)
        {
            if (kArr[i].startDateTime == currentDate)
            {
                k = i;
            }
            if (k != -1 && i == k + n)
            {
                ret = kArr[i].highestPrice;
                if (kArr[i].startDateTime < DateTime.Parse(DateTime.Now.ToShortDateString())
                    || (kArr[i].startDateTime == DateTime.Parse(DateTime.Now.ToShortDateString()) && (DateTime.Now.Hour > 15 || (DateTime.Now.Hour == 15 && DateTime.Now.Minute > 15) )))
                {
                    UpdateNextNDayHighest(gid, currentDate, n, ret);
                }
                break;
            }
        }
        return ret;
    }


    public static void UpdateNextNDayHighest(string gid, DateTime currentDate, int n, double highestPrice)
    {
        string sqlStr = " update suggest_stock set highest_" + n.ToString() +  "_day =  " + highestPrice.ToString() + "  where "
            + "  suggest_date = '" + currentDate.ToShortDateString() + "'  and gid = '" + gid.Trim().Replace("'", "") + "' ";
        SqlConnection conn = new SqlConnection(Util.conStr);
        SqlCommand cmd = new SqlCommand(sqlStr, conn);
        conn.Open();
        cmd.ExecuteNonQuery();
        conn.Close();
        cmd.Dispose();
        conn.Dispose();

    }

    public static void UpdateD2SettlementPrice(string gid, DateTime currentDate, double price)
    {
        string sqlStr = " update suggest_stock set settlement_2_day =  " + price.ToString() + "  where "
            + "  suggest_date = '" + currentDate.ToShortDateString() + "'  and gid = '" + gid.Trim().Replace("'", "") + "' ";
        SqlConnection conn = new SqlConnection(Util.conStr);
        SqlCommand cmd = new SqlCommand(sqlStr, conn);
        conn.Open();
        cmd.ExecuteNonQuery();
        conn.Close();
        cmd.Dispose();
        conn.Dispose();
    }



    public static double Get3DayHighest(string gid, DateTime date)
    {
        double ret = 0;
        KLine[] kArr = KLine.GetKLineDayFromSohu(gid, date.AddDays(1), date.AddMonths(1));
        if (kArr.Length > 2)
        {
            ret = Math.Max(kArr[0].highestPrice, kArr[1].highestPrice);
            ret = Math.Max(ret, kArr[2].highestPrice);
            if (kArr[2].startDateTime < DateTime.Parse(DateTime.Now.ToShortDateString()))
                Update3DHighestPrice(gid, date, ret);
        }

        return ret;
    }

    public static double Get5DayHighest(string gid, DateTime date)
    {
        double ret = 0;
        KLine[] kArr = KLine.GetKLineDayFromSohu(gid, date.AddDays(1), date.AddMonths(1));
        if (kArr.Length > 4)
        {
            ret = Math.Max(kArr[0].highestPrice, kArr[1].highestPrice);
            ret = Math.Max(ret, kArr[2].highestPrice);
            ret = Math.Max(ret, kArr[3].highestPrice);
            ret = Math.Max(ret, kArr[4].highestPrice);
            if (kArr[4].startDateTime < DateTime.Parse(DateTime.Now.ToShortDateString()))
                Update5DHighestPrice(gid, date, ret);
        }

        return ret;
    }

    public static void Update3DHighestPrice(string gid, DateTime date, double price)
    {
        string sqlStr = " update suggest_stock set highest_3_day =  " + price.ToString() + "  where "
            + "  suggest_date = '" + date.ToShortDateString() + "'  and gid = '" + gid.Trim().Replace("'", "") + "' ";
        SqlConnection conn = new SqlConnection(Util.conStr);
        SqlCommand cmd = new SqlCommand(sqlStr, conn);
        conn.Open();
        cmd.ExecuteNonQuery();
        conn.Close();
        cmd.Dispose();
        conn.Dispose();
    }
    public static void Update5DHighestPrice(string gid, DateTime date, double price)
    {
        string sqlStr = " update suggest_stock set highest_5_day =  " + price.ToString() + "  where "
            + "  suggest_date = '" + date.ToShortDateString() + "'  and gid = '" + gid.Trim().Replace("'", "") + "' ";
        SqlConnection conn = new SqlConnection(Util.conStr);
        SqlCommand cmd = new SqlCommand(sqlStr, conn);
        conn.Open();
        cmd.ExecuteNonQuery();
        conn.Close();
        cmd.Dispose();
        conn.Dispose();
    }


    protected void dg_SortCommand(object source, DataGridSortCommandEventArgs e)
    {
        string sortCommand = e.SortExpression;
        string colmunName = sortCommand.Split('|')[0].Trim();
        string command = sortCommand.Split('|')[1].Trim();

        DataTable dt = GetDataFull();
        DataTable dtSort = dt.Clone();
        dtSort.Columns.Add("跳空幅度double", Type.GetType("System.Double"));
        dtSort.Columns.Add("今日最高double", Type.GetType("System.Double"));
        dtSort.Columns.Add("1日最高double", Type.GetType("System.Double"));
        dtSort.Columns.Add("2日最高double", Type.GetType("System.Double"));
        dtSort.Columns.Add("2日收盘double", Type.GetType("System.Double"));
        dtSort.Columns.Add("3日最高double", Type.GetType("System.Double"));
        dtSort.Columns.Add("4日最高double", Type.GetType("System.Double"));
        dtSort.Columns.Add("5日最高double", Type.GetType("System.Double"));
        dtSort.Columns.Add("重心double", Type.GetType("System.Double"));
        for (int i = 0; i < dt.Rows.Count - 5; i++)
        {
            DataRow drSort = dtSort.NewRow();
            foreach (DataColumn dc in dt.Columns)
            {
                drSort[dc.Caption] = dt.Rows[i][dc];
            }
            drSort["跳空幅度double"] = GetPercentValue(drSort["跳空幅度"].ToString()); //double.Parse(drSort["跳空幅度"].ToString().Replace("%", ""));
            drSort["今日最高double"] = GetPercentValue(drSort["今日最高"].ToString());//double.Parse(drSort["今日最高"].ToString().Replace("%", ""));
            drSort["1日最高double"] = GetPercentValue(drSort["1日最高"].ToString());//double.Parse(drSort["1日最高"].ToString().Replace("%", ""));
            drSort["2日最高double"] = GetPercentValue(drSort["2日最高"].ToString());//double.Parse(drSort["2日最高"].ToString().Replace("%", ""));
            //drSort["2日收盘double"] = GetPercentValue(drSort["2日收盘"].ToString());
            drSort["3日最高double"] = GetPercentValue(drSort["3日最高"].ToString());//double.Parse(drSort["3日最高"].ToString().Replace("%", ""));
            drSort["4日最高double"] = GetPercentValue(drSort["4日最高"].ToString());//double.Parse(drSort["4日最高"].ToString().Replace("%", ""));
            drSort["5日最高double"] = GetPercentValue(drSort["5日最高"].ToString());//double.Parse(drSort["5日最高"].ToString().Replace("%", ""));
            drSort["重心double"] = double.Parse(drSort["重心"].ToString());
            dtSort.Rows.Add(drSort);
        }

        DataRow[] drSortArr = dtSort.Select("", colmunName.Trim() + "double " + (command.Trim().Equals("A-Z") ? " asc" : " desc"));

        DataTable dtNew = dt.Clone();



        foreach (DataRow drSort in drSortArr)
        {
            DataRow drNew = dtNew.NewRow();
            foreach (DataColumn dc in dtNew.Columns)
            {
                drNew[dc] = drSort[dc.Caption.Trim()];
            }
            dtNew.Rows.Add(drNew);
        }

        for (int i = 0; i < 5; i++)
        {
            DataRow dr = dt.Rows[dt.Rows.Count - 5 + i];
            DataRow drNewTotal = dtNew.NewRow();
            foreach (DataColumn c in dt.Columns)
            {
                drNewTotal[c.Caption] = dr[c];
            }
            dtNew.Rows.Add(drNewTotal);
        }

        //AddTotal(dtNew);
        dg.DataSource = dtNew;
        dg.DataBind();

        for (int i = 0; i < dg.Columns.Count; i++)
        {
            if (dg.Columns[i].SortExpression.StartsWith(colmunName))
            {
                dg.Columns[i].SortExpression = colmunName.Trim() + "|" + (command.Trim().Equals("Z-A")? "A-Z":"Z-A");
            }
        }

    }

    public static double GetPercentValue(string str)
    {
        if (str.Trim().Equals("-"))
            return 0;
        Match m = Regex.Match(str, @"-*\d+.*\d*%");
        return double.Parse(m.Value.Replace(">", "").Replace("<", "").Replace("%", ""));
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
            <tr><td>&nbsp;</td></tr>
            <tr>
                <td><asp:DataGrid runat="server" id="dg" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" OnSortCommand="dg_SortCommand" AllowSorting="True" AutoGenerateColumns="False" ShowFooter="True" >
                    <AlternatingItemStyle BackColor="#DCDCDC" />
                    <Columns>
                        <asp:BoundColumn DataField="代码" HeaderText="代码"></asp:BoundColumn>
                        <asp:BoundColumn DataField="名称" HeaderText="名称"></asp:BoundColumn>
                        <asp:BoundColumn DataField="信号" HeaderText="信号"></asp:BoundColumn>
                        <asp:BoundColumn DataField="今开" HeaderText="今开"></asp:BoundColumn>
                        <asp:BoundColumn DataField="KDJ买入价" HeaderText="KDJ买入价" ></asp:BoundColumn>
                        <asp:BoundColumn DataField="9日低价" HeaderText="9日低价"></asp:BoundColumn>
                        <asp:BoundColumn DataField="支撑" HeaderText="支撑" ></asp:BoundColumn>
                        <asp:BoundColumn DataField="现价" HeaderText="现价"></asp:BoundColumn>
                        <asp:BoundColumn DataField="压力" HeaderText="压力"></asp:BoundColumn>
                        <asp:BoundColumn DataField="9日高价" HeaderText="9日高价"></asp:BoundColumn>
                        <asp:BoundColumn DataField="9日振幅" HeaderText="9日振幅" ></asp:BoundColumn>
                        <asp:BoundColumn DataField="重心" HeaderText="重心" SortExpression="重心|A-Z" ></asp:BoundColumn>

                        <asp:BoundColumn DataField="跳空幅度" HeaderText="跳空幅度" SortExpression="跳空幅度|A-Z"></asp:BoundColumn>
                        <asp:BoundColumn DataField="今日最高" HeaderText="今日最高" SortExpression="今日最高|A-Z"></asp:BoundColumn>
                        <asp:BoundColumn DataField="1日最高" HeaderText="1日最高" SortExpression="1日最高|A-Z"></asp:BoundColumn>
                        <asp:BoundColumn DataField="2日最高" HeaderText="2日最高" SortExpression="2日最高|A-Z"></asp:BoundColumn>
                        <asp:BoundColumn DataField="3日最高" HeaderText="3日最高" SortExpression="3日最高|A-Z"></asp:BoundColumn>
                        <asp:BoundColumn DataField="4日最高" HeaderText="4日最高" SortExpression="4日最高|A-Z"></asp:BoundColumn>
                        <asp:BoundColumn DataField="5日最高" HeaderText="5日最高" SortExpression="5日最高|A-Z"></asp:BoundColumn>
                        <asp:BoundColumn DataField="总计" HeaderText="总计" ></asp:BoundColumn>
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
