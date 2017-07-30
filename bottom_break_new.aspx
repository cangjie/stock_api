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

        DataTable dtKdj = DBHelper.GetDataTable(" select * from kdj_alert where alert_time >= '" + currentDate.ToShortDateString() + "' and alert_time < '" + currentDate.AddDays(1).ToShortDateString() + "'   ");
        DataTable dtMacd = DBHelper.GetDataTable(" select * from macd_alert where alert_time >='" + currentDate.ToShortDateString() + "' and alert_time < '" + currentDate.AddDays(1).ToShortDateString() + "'   ");

        int[] starCount = new int[6] { 0, 0, 0, 0, 0, 0};
        int starTotal = 0;
        int[] kdjCount = new int[6] { 0, 0, 0, 0, 0, 0};
        int kdjTotal = 0;

        int[] starRocketCount = new int[6] { 0, 0, 0, 0, 0, 0 };
        int starRocketTotal = 0;

        int[] kdjRocketCount = new int[6] { 0, 0, 0, 0, 0, 0 };
        int kdjRocketTotal = 0;

        int[] starKdjRocketCount = new int[6] { 0, 0, 0, 0, 0, 0 };
        int starKdjRocketTotal = 0;

        int starKdjTotal = 0;
        int[] starKdjCount = new int[6] { 0, 0, 0, 0, 0, 0};

        //int[] oxStarKdjCount = new int[6] { 0, 0, 0, 0, 0, 0};
        //int oxStarKdjTotal = 0;

        int[] rocketCount = new int[6] { 0, 0, 0, 0, 0, 0 };
        int rocketTotal = 0;



        int[] allCount = new int[6] { 0, 0, 0, 0, 0, 0};

        DataTable dt = new DataTable();
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("信号");
        dt.Columns.Add("10日低价");
        dt.Columns.Add("支撑");
        dt.Columns.Add("现价");
        dt.Columns.Add("压力");
        dt.Columns.Add("10日高价");
        dt.Columns.Add("10日振幅");
        dt.Columns.Add("今开");
        dt.Columns.Add("KDJ买入价");
        dt.Columns.Add("MACD买入价");
        dt.Columns.Add("跳空幅度");
        dt.Columns.Add("今日最高");
        //dt.Columns.Add("重心");
        dt.Columns.Add("1日最高");
        dt.Columns.Add("2日最高");
        dt.Columns.Add("3日最高");
        dt.Columns.Add("4日最高");
        dt.Columns.Add("5日最高");
        dt.Columns.Add("总计");
        foreach (DataRow drOri in dtOri.Rows)
        {
            
            double jumpEmptyRate = Math.Round(((double.Parse(drOri["open"].ToString().Trim()) - double.Parse(drOri["settlement"].ToString().Trim()))
                / double.Parse(drOri["settlement"].ToString().Trim())) * 100, 2);
            Stock stock = new Stock(drOri["gid"].ToString().Trim());
            int currentIndex = stock.GetItemIndex(DateTime.Parse(currentDate.ToShortDateString() + " 9:30"));
            DataRow dr = dt.NewRow();
            dr["代码"] = "<a href=\"show_k_line_day.aspx?gid=" + drOri["gid"].ToString().Trim() + "&name="
                + Server.UrlEncode(drOri["name"].ToString().Trim()) + "\" target=\"_blank\" >"
                +  drOri["gid"].ToString().Trim().Remove(0, 2) + "</a>";

            dr["名称"] = "<a href=\"https://touzi.sina.com.cn/public/xray/details/" + drOri["gid"].ToString().Trim()
                + "\" target=\"_blank\"  >" + drOri["name"].ToString().Trim() + "</a>";
            dr["今开"] = drOri["open"].ToString().Trim();
            dr["信号"] = dr["信号"].ToString() + (IsOx(drOri) ? "<a title=\"20交易日内两次穿越3线\" >🐂</a>" : "");
            dr["信号"] = dr["信号"].ToString() + (IsStar(drOri, stock) ? "<a alt=\"" + drOri["gid"].ToString().Trim().Remove(0, 2) + "\"  title=\"两日连涨，跳空和涨幅在特定范围内，昨日收阳，并且最高价和收盘价差在1%以内\" >🌟</a>" : "");
            dr["信号"] = dr["信号"].ToString() + ((IsKdjAlert(drOri, dtKdj)  &&  IsMacdAlert(drOri, dtMacd) )? "<a alt=\"" + drOri["gid"].ToString().Trim().Remove(0, 2) + "\"  title=\"KDJ MACD双买入信号\" >📈</a>" : "");
            //dr["信号"] = dr["信号"].ToString() + (  (dr["信号"].ToString().IndexOf("📈") < 0 &&  IsMacdAlert(drOri, dtKdj)) ? "<a alt=\"" + drOri["gid"].ToString().Trim().Remove(0, 2) + "\"  title=\"MACD买入\" >📈</a>" : "");
            dr["信号"] = dr["信号"].ToString() + (( currentIndex > 0 && GetBottomDeep(stock.kArr, DateTime.Parse(currentDate.ToShortDateString() + " 9:30")) >= 5 ) ? "🚀" : "");


            dr["信号"] = dr["信号"].ToString() + ((currentIndex> 0 && (stock.kArr[currentIndex].startPrice >= stock.kArr[currentIndex].endPrice
                || stock.kArr[currentIndex].highestPrice - stock.kArr[currentIndex].endPrice >= stock.kArr[currentIndex].endPrice - stock.kArr[currentIndex].startPrice)) ? "💩" : "");


            if (dr["信号"].ToString().IndexOf("💩") < 0)
            {
                if (dr["信号"].ToString().IndexOf("🌟") >= 0)
                    starTotal++;
                if (dr["信号"].ToString().IndexOf("📈") >= 0)
                    kdjTotal++;
                if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                {
                    starKdjTotal++;
                }
                if (dr["信号"].ToString().IndexOf("🚀") >= 0)
                {
                    rocketTotal++;
                }
                if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("🌟") >= 0)
                    starRocketTotal++;
                if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                    starKdjRocketTotal++;
                if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                    kdjRocketTotal++;
            }



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
                highestPrice = GetNextNDayHighest(stock, currentDate, 0);
            }
            else
            {
                highestPrice = double.Parse(drOri["highest_0_day"].ToString().Trim());
            }

            double rateToday = Math.Round(((highestPrice - double.Parse(drOri["open"].ToString().Trim()))
                / double.Parse(drOri["open"].ToString().Trim())) * 100, 2);
            dr["今日最高"] = "<font color=\"" + (rateToday >=1? "red": (rateToday < 0? "green" : "black")) + "\" >" + rateToday.ToString() + "%</font>";



            double currentDayPrice = (currentDate == DateTime.Parse(DateTime.Now.ToShortDateString())) ? stock.LastTrade : double.Parse(drOri["open"].ToString().Trim()) * 1.01;
            double minPrice = stock.LowestPrice(DateTime.Now, 10);
            double maxPrice = stock.HighestPrice(DateTime.Now, 10);
            double pressure = Stock.GetPressure(currentDayPrice , minPrice, maxPrice);
            double support = Stock.GetSupport(currentDayPrice , minPrice, maxPrice);
            dr["10日低价"] = Math.Round(minPrice, 2).ToString();
            dr["支撑"] = Math.Round(support, 2).ToString();
            dr["现价"] = Math.Round(currentDayPrice, 2).ToString();
            dr["压力"] = Math.Round(pressure, 2).ToString();
            dr["10日高价"] = Math.Round(maxPrice, 2).ToString();
            dr["10日振幅"] = Math.Round((maxPrice - minPrice) * 100 / minPrice, 2).ToString() + "%";
            dr["今开"] = Math.Round(double.Parse(drOri["open"].ToString()), 2).ToString();
            double buyPrice = double.Parse(drOri["open"].ToString()) * 1.01;
            double buyKdjPrice = 0;
            double buyMacdPrice = 0;
            if (dr["信号"].ToString().IndexOf("📈") >= 0)
            {
                DataRow[] kdjArr = dtKdj.Select(" gid = '" + drOri["gid"].ToString() + "'  ");
                if (kdjArr.Length > 0)
                    buyKdjPrice = double.Parse(kdjArr[kdjArr.Length - 1]["price"].ToString());
                DataRow[] macdArr = dtMacd.Select(" gid = '" + drOri["gid"].ToString() + "'  ");
                if (macdArr.Length > 0)
                    buyMacdPrice = double.Parse(macdArr[macdArr.Length - 1]["price"].ToString());
            }
            dr["KDJ买入价"] = (buyKdjPrice!=0) ? Math.Round(buyKdjPrice, 2).ToString() : "-";
            dr["MACD买入价"] = (buyMacdPrice != 0) ? Math.Round(buyMacdPrice, 2).ToString() : "-";

            buyPrice = Math.Max(buyPrice, buyKdjPrice);
            buyPrice = Math.Max(buyPrice, buyMacdPrice);

            //dr["重心"] = Math.Round( 100* (currentDayPrice - minPrice) / (maxPrice - minPrice),2);

            double rate = 0;
            double rateMax = -100;
            int valve = 2;

            if (drOri["highest_1_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(stock, currentDate, 1);
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


                if (dr["1日最高"].ToString().IndexOf("red") >= 0 &&   dr["信号"].ToString().IndexOf("💩") < 0 )
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
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 )
                    {
                        rocketCount[0]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("🌟") >= 0)
                    {
                        starRocketCount[0]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                    {
                        kdjRocketCount[0]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0 )
                    {
                        starKdjRocketCount[0]++;
                    }

                }


            }

            if (drOri["highest_2_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(stock, currentDate, 2);
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
                if (dr["2日最高"].ToString().IndexOf("red") >= 0  && dr["信号"].ToString().IndexOf("💩") < 0)
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

                    if (dr["信号"].ToString().IndexOf("🚀") >= 0  )
                    {
                        rocketCount[1]++;

                    }
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("🌟") >= 0)
                    {
                        starRocketCount[1]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0 )
                    {
                        starKdjRocketCount[1]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                    {
                        kdjRocketCount[1]++;
                    }
                }
            }

            if (drOri["highest_3_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(stock, currentDate, 3);
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

                if (dr["3日最高"].ToString().IndexOf("red") >= 0  && dr["信号"].ToString().IndexOf("💩") < 0 )
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

                    if (dr["信号"].ToString().IndexOf("🚀") >= 0  )
                    {
                        rocketCount[2]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("🌟") >= 0)
                    {
                        starRocketCount[2]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0 )
                    {
                        starKdjRocketCount[2]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                    {
                        kdjRocketCount[2]++;
                    }
                }
            }

            if (drOri["highest_4_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(stock, currentDate, 4);
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
                if (dr["4日最高"].ToString().IndexOf("red") >= 0  && dr["信号"].ToString().IndexOf("💩") < 0)
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

                    if (dr["信号"].ToString().IndexOf("🚀") >= 0  )
                    {
                        rocketCount[3]++;

                    }
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("🌟") >= 0)
                    {
                        starRocketCount[3]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0 )
                    {
                        starKdjRocketCount[3]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                    {
                        kdjRocketCount[3]++;
                    }
                }
            }

            if (drOri["highest_5_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(stock, currentDate, 5);
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
                if (dr["5日最高"].ToString().IndexOf("red") >= 0 && dr["信号"].ToString().IndexOf("💩") < 0 )
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

                    if (dr["信号"].ToString().IndexOf("🚀") >= 0   )
                    {
                        rocketCount[4]++;

                    }
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("🌟") >= 0)
                    {
                        starRocketCount[4]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0 )
                    {
                        starKdjRocketCount[4]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                    {
                        kdjRocketCount[4]++;
                    }
                }
            }

            dr["总计"] = "<font color=\"" + (rateMax >=valve ? "red": (rateMax < 0? "green" : "black")) + "\" >"
                + rateMax.ToString() + "%</font>";
            if (dr["总计"].ToString().IndexOf("red") >= 0  && dr["信号"].ToString().IndexOf("💩") < 0 )
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

                if (dr["信号"].ToString().IndexOf("🚀") >= 0 )
                {
                    rocketCount[5]++;
                }
                if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("🌟") >= 0)
                {
                    starRocketCount[5]++;
                }
                if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0 )
                {
                    starKdjRocketCount[5]++;
                }
                if (dr["信号"].ToString().IndexOf("🚀") >= 0 && dr["信号"].ToString().IndexOf("📈") >= 0)
                {
                    kdjRocketCount[5]++;
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


        DataRow drRocket = dt.NewRow();
        drRocket["名称"] = "🚀";
        drRocket["1日最高"] = Math.Round(100 * (double)rocketCount[0] / (double)rocketTotal, 2).ToString() + "%";
        drRocket["2日最高"] = Math.Round(100 * (double)rocketCount[1] / (double)rocketTotal, 2).ToString() + "%";
        drRocket["3日最高"] = Math.Round(100 * (double)rocketCount[2] / (double)rocketTotal, 2).ToString() + "%";
        drRocket["4日最高"] = Math.Round(100 * (double)rocketCount[3] / (double)rocketTotal, 2).ToString() + "%";
        drRocket["5日最高"] = Math.Round(100 * (double)rocketCount[4] / (double)rocketTotal, 2).ToString() + "%";
        drRocket["总计"] = Math.Round(100 * (double)rocketCount[5] / (double)rocketTotal, 2).ToString() + "%";
        dt.Rows.Add(drRocket);


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

        DataRow drKdjRocket = dt.NewRow();
        drKdjRocket["名称"] = "📈🚀";
        drKdjRocket["1日最高"] = Math.Round(100 * (double)kdjRocketCount[0] / (double)kdjRocketTotal, 2).ToString() + "%";
        drKdjRocket["2日最高"] = Math.Round(100 * (double)kdjRocketCount[1] / (double)kdjRocketTotal, 2).ToString() + "%";
        drKdjRocket["3日最高"] = Math.Round(100 * (double)kdjRocketCount[2] / (double)kdjRocketTotal, 2).ToString() + "%";
        drKdjRocket["4日最高"] = Math.Round(100 * (double)kdjRocketCount[3] / (double)kdjRocketTotal, 2).ToString() + "%";
        drKdjRocket["5日最高"] = Math.Round(100 * (double)kdjRocketCount[4] / (double)kdjRocketTotal, 2).ToString() + "%";
        drKdjRocket["总计"] = Math.Round(100 * (double)kdjRocketCount[5] / (double)kdjRocketTotal, 2).ToString() + "%";
        dt.Rows.Add(drKdjRocket);

        DataRow drStartRocket = dt.NewRow();
        drStartRocket["名称"] = "🌟🚀";
        drStartRocket["1日最高"] = Math.Round(100 * (double)starRocketCount[0] / (double)starRocketTotal, 2).ToString() + "%";
        drStartRocket["2日最高"] = Math.Round(100 * (double)starRocketCount[1] / (double)starRocketTotal, 2).ToString() + "%";
        drStartRocket["3日最高"] = Math.Round(100 * (double)starRocketCount[2] / (double)starRocketTotal, 2).ToString() + "%";
        drStartRocket["4日最高"] = Math.Round(100 * (double)starRocketCount[3] / (double)starRocketTotal, 2).ToString() + "%";
        drStartRocket["5日最高"] = Math.Round(100 * (double)starRocketCount[4] / (double)starRocketTotal, 2).ToString() + "%";
        drStartRocket["总计"] = Math.Round(100 * (double)starRocketCount[5] / (double)starRocketTotal, 2).ToString() + "%";
        dt.Rows.Add(drStartRocket);

        DataRow drStarKdjRocket = dt.NewRow();
        drStarKdjRocket["名称"] = "🌟📈🚀";
        drStarKdjRocket["1日最高"] = Math.Round(100 * (double)starKdjRocketCount[0] / (double)starKdjRocketTotal, 2).ToString() + "%";
        drStarKdjRocket["2日最高"] = Math.Round(100 * (double)starKdjRocketCount[1] / (double)starKdjRocketTotal, 2).ToString() + "%";
        drStarKdjRocket["3日最高"] = Math.Round(100 * (double)starKdjRocketCount[2] / (double)starKdjRocketTotal, 2).ToString() + "%";
        drStarKdjRocket["4日最高"] = Math.Round(100 * (double)starKdjRocketCount[3] / (double)starKdjRocketTotal, 2).ToString() + "%";
        drStarKdjRocket["5日最高"] = Math.Round(100 * (double)starKdjRocketCount[4] / (double)starKdjRocketTotal, 2).ToString() + "%";
        drStarKdjRocket["总计"] = Math.Round(100 * (double)starKdjRocketCount[5] / (double)starKdjRocketTotal, 2).ToString() + "%";
        dt.Rows.Add(drStarKdjRocket);

        return dt;
    }

    public int GetBottomDeep(KLine[] kArr, DateTime currentDate)
    {
        Stock s = new Stock();
        s.kArr = kArr;
        int index = s.GetItemIndex(DateTime.Parse(currentDate.ToShortDateString() + " 9:30"));
        int deepMax = 0;
        for (int j = 1; j < 4; j++)
        {
            int currentIndex = index - j;

            //int deep = KLine.GetBottomDeep(kArr, currentIndex);
            int ret = 0;
            for (int i = 0;  currentIndex - i - 1 >= 0; i++)
            {
                double current3Line = s.GetAverageSettlePrice(currentIndex - i, 3, 3);
                double previous3Line = s.GetAverageSettlePrice(currentIndex - i - 1, 3, 3);
                if ( Math.Round(current3Line,2) <=  Math.Round(previous3Line,2) && kArr[currentIndex - i].endPrice <= current3Line && kArr[currentIndex - i -1].endPrice < previous3Line  )
                {
                    ret++;
                }
                else
                {
                    break;
                }
            }
            deepMax = Math.Max(deepMax, ret);
        }

        return deepMax;
    }



    public bool IsStar(DataRow dr, Stock stock)
    {
        DateTime currentDate = DateTime.Parse(calendar.SelectedDate.ToShortDateString());
        double  jumpRate = (double.Parse(dr["open"].ToString()) - double.Parse(dr["settlement"].ToString().Trim()))
            / double.Parse(dr["settlement"].ToString().Trim());
        double highestPrice = 0;
        if (dr["highest_0_day"].ToString().Equals("0"))
        {
            highestPrice = GetNextNDayHighest(stock, currentDate, 0);
        }
        else
        {
            highestPrice = double.Parse(dr["highest_0_day"].ToString().Trim());
        }
        double rate = Math.Round(((highestPrice - double.Parse(dr["open"].ToString().Trim()))
                / double.Parse(dr["open"].ToString().Trim())) * 100, 2);
        bool yesterdayBelow3Line = false;
        Stock s = stock;
        //s.kArr = KLine.GetLocalKLine(s.gid, "day");
        double yesterday3LinePrice = s.GetAverageSettlePrice(s.kArr.Length - 2, 3, 3);
        if (s.kArr.Length - 2 < 0)
            return false;
        if (s.kArr[s.kArr.Length - 2].endPrice < yesterday3LinePrice)
            yesterdayBelow3Line = true;
        if ( ( (jumpRate < 0.004 || (jumpRate > 0.01 && jumpRate < 0.07))
              && (rate > 1) && double.Parse(dr["last_day_over_flow"].ToString()) > 0)
              || (jumpRate < 0 &&  double.Parse(dr["last_day_over_flow"].ToString()) > 0  && yesterdayBelow3Line) )
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

    public bool IsMacdAlert(DataRow dr, DataTable dtMacd)
    {
        DataRow[] drKdjArr = dtMacd.Select(" gid = '" + dr["gid"].ToString().Trim() + "' and  (type = 'day'  ) ");
        if (drKdjArr.Length > 0)
            return true;
        else
            return false;
    }





    public static double GetNextNDayHighest(Stock stock, DateTime currentDate, int n)
    {
        string gid = stock.gid;
        if (currentDate.AddDays(n) > DateTime.Parse(DateTime.Now.ToShortDateString()))
            return 0;
        KLine[] kArr = stock.kArr;
        double ret = 0;
        int k = -1;
        for (int i = 0; i < kArr.Length; i++)
        {
            if (DateTime.Parse(kArr[i].startDateTime.ToShortDateString()) == DateTime.Parse(currentDate.ToShortDateString()))
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



    public static double Get3DayHighest(Stock stock, DateTime date)
    {
        double ret = 0;
        KLine[] kArr = stock.kArr;
        if (kArr.Length > 2)
        {
            ret = Math.Max(kArr[0].highestPrice, kArr[1].highestPrice);
            ret = Math.Max(ret, kArr[2].highestPrice);
            if (kArr[2].startDateTime < DateTime.Parse(DateTime.Now.ToShortDateString()))
                Update3DHighestPrice(stock.gid, date, ret);
        }

        return ret;
    }

    public static double Get5DayHighest(Stock stock, DateTime date)
    {
        double ret = 0;
        KLine[] kArr = stock.kArr;
        if (kArr.Length > 4)
        {
            ret = Math.Max(kArr[0].highestPrice, kArr[1].highestPrice);
            ret = Math.Max(ret, kArr[2].highestPrice);
            ret = Math.Max(ret, kArr[3].highestPrice);
            ret = Math.Max(ret, kArr[4].highestPrice);
            if (kArr[4].startDateTime < DateTime.Parse(DateTime.Now.ToShortDateString()))
                Update5DHighestPrice(stock.gid, date, ret);
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
        //dtSort.Columns.Add("重心double", Type.GetType("System.Double"));
        for (int i = 0; i < dt.Rows.Count - 8; i++)
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
            //try
            //{
            //    drSort["重心double"] = double.Parse(drSort["重心"].ToString());
            //}
            //catch
            //{
            //    drSort["重心double"] = 50;
            //}
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

        for (int i = 0; i < 6; i++)
        {
            DataRow dr = dt.Rows[dt.Rows.Count - 6 + i];
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
                        <asp:BoundColumn DataField="MACD买入价" HeaderText="MACD买入价" ></asp:BoundColumn>
                        <asp:BoundColumn DataField="10日低价" HeaderText="10日低价"></asp:BoundColumn>
                        <asp:BoundColumn DataField="支撑" HeaderText="支撑" ></asp:BoundColumn>
                        <asp:BoundColumn DataField="现价" HeaderText="现价"></asp:BoundColumn>
                        <asp:BoundColumn DataField="压力" HeaderText="压力"></asp:BoundColumn>
                        <asp:BoundColumn DataField="10日高价" HeaderText="10日高价"></asp:BoundColumn>
                        <asp:BoundColumn DataField="10日振幅" HeaderText="10日振幅" ></asp:BoundColumn>
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
