﻿<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Text" %>
<!DOCTYPE html>

<script runat="server">

    public DateTime currentDate = Util.GetDay(DateTime.Now);

    public static ThreadStart ts = new ThreadStart(PageWatcher);

    public static Thread t = new Thread(ts);

    public static long threadCount = 0;

    protected void Page_Load(object sender, EventArgs e)
    {
        try
        {
            if (t.ThreadState != ThreadState.Running && t.ThreadState != ThreadState.WaitSleepJoin)
            {
                t.Abort();
                ts = new ThreadStart(PageWatcher);
                t = new Thread(ts);
                t.Start();
            }
        }
        catch(Exception err)
        {
            Console.WriteLine(err.ToString());
        }
        if (!IsPostBack)
        {
            DataTable dt = AddTotal(GetData());
            RenderHTML(dt);
            dg.DataSource = dt;
            dg.DataBind();
        }
    }

    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {
        currentDate = Util.GetDay(calendar.SelectedDate);
        DataTable dt = AddTotal(GetData());
        RenderHTML(dt);
        dg.DataSource = dt;
        dg.DataBind();
    }

    public void RenderHTML(DataTable dt)
    {
        int totalCountNum = 5;
        for (int i = 0; i < dt.Rows.Count - totalCountNum; i++)
        {
            dt.Rows[i]["代码"] = "<a href=\"show_k_line_day.aspx?gid=" + dt.Rows[i]["代码"].ToString().Trim() + "\" target=\"_blank\" >" + dt.Rows[i]["代码"].ToString().Trim() + "</a>";
            dt.Rows[i]["涨停前收"] = Math.Round(double.Parse(dt.Rows[i]["涨停前收"].ToString()), 2);
            dt.Rows[i]["涨停收"] = Math.Round(double.Parse(dt.Rows[i]["涨停收"].ToString()), 2);
            dt.Rows[i]["缩量"] = Math.Round(double.Parse(dt.Rows[i]["缩量"].ToString())*100, 2).ToString()+"%";
            dt.Rows[i]["最低价"] = Math.Round(double.Parse(dt.Rows[i]["最低价"].ToString()), 2);
            dt.Rows[i]["现价"] = Math.Round(double.Parse(dt.Rows[i]["现价"].ToString()), 2);
            dt.Rows[i]["买入价"] = Math.Round(double.Parse(dt.Rows[i]["买入价"].ToString()), 2);
            for (int j = 1; j <= 6; j++)
            {
                double value = -1;
                string color = "green";
                try
                {
                    if (!dt.Rows[i][((j == 6) ? "总计" : j.ToString() + "日")].ToString().Equals("-"))
                        value = double.Parse(dt.Rows[i][((j == 6) ? "总计" : j.ToString() + "日")].ToString());
                    else
                        color = "black";
                }
                catch
                {
                    color = "black";
                }

                if (Math.Round(value*100, 2) >= 1)
                {
                    color = "red";
                }
                dt.Rows[i][((j == 6) ? "总计" : j.ToString() + "日")] = "<font color=\"" + color + "\" >" + ((value == -1) ? "-" : Math.Round(100 * value, 2).ToString()) + "%</font>";
            }
        }
    }

    public DataTable GetData()
    {
        return GetData(currentDate);
    }

    public DataTable AddTotal(DataTable dt)
    {
        DataTable dtNew = dt.Clone();
        DataRow[] drArr = dt.Select("", " 调整天数, 缩量, 缩量天数 desc , 下跌天数 desc  ");


        DataRow drNewTotal = dtNew.NewRow();

        int totalCount = 0;
        int[] totalRaiseCount = new int[6] { 0, 0, 0, 0, 0, 0 };

        DataRow drNewStar = dtNew.NewRow();
        int starCount = 0;
        int[] startRaiseCount = new int[6] { 0, 0, 0, 0, 0, 0 };

        DataRow drNewTarget = dtNew.NewRow();
        int targetCount = 0;
        int[] targetRaiseCount = new int[6] { 0, 0, 0, 0, 0, 0 };

        DataRow drNewStarTarget = dtNew.NewRow();
        int starTargetCount = 0;
        int[] starTargetRaiseCount = new int[6] { 0,0,0,0,0,0};

        DataRow drFire = dtNew.NewRow();
        int fireCount = 0;
        int fireRaiseCount = 0;

        foreach (DataRow dr in drArr)
        {
            totalCount++;
            if (dr["信号"].ToString().IndexOf("🎯") >= 0  && dr["信号"].ToString().IndexOf("🌟") < 0)
            {
                targetCount++;
            }
            if (dr["信号"].ToString().IndexOf("🌟") >= 0)
            {
                starCount++;
            }
            if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("🎯")>=0)
            {
                starTargetCount++;
            }
            int buyDay = 0;
            double buyPrice = 0;
            bool fireRaise = false;
            double valueFire = 0;
            double currentPrice = double.Parse(dr["现价"].ToString().Trim());
            if (dr["信号"].ToString().IndexOf("🔥") >= 0 )
            {
                fireCount++;
                buyDay = 0;
                buyPrice = double.Parse(dr["买入价"].ToString().Trim());
                valueFire = (buyPrice - currentPrice) / currentPrice;
            }
            for (int i = 1; i <= 6; i++)
            {
                double value = -1;
                try
                {
                    if (!dr[((i == 6) ? "总计" : i.ToString() + "日")].ToString().Equals("-"))
                        value = double.Parse(dr[((i == 6) ? "总计" : i.ToString() + "日")].ToString());
                }
                catch
                {

                }
                if (value > 0.01)
                {
                    totalRaiseCount[i - 1]++;
                    if (dr["信号"].ToString().IndexOf("🎯") >= 0 && dr["信号"].ToString().IndexOf("🌟") < 0)
                    {
                        targetRaiseCount[i-1]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0)
                    {
                        startRaiseCount[i-1]++;
                    }
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0 && dr["信号"].ToString().IndexOf("🎯")>=0)
                    {
                        starTargetRaiseCount[i-1]++;
                    }
                }
                if (buyDay > 0 && i > buyDay && i < 6)
                {
                    if (!dr[i.ToString() + "日"].ToString().Trim().Equals("-"))
                    {
                        value = double.Parse(dr[i.ToString() + "日"].ToString());
                        if (value - valueFire >= 0.01)
                            fireRaise = true;
                    }

                }
            }
            if (fireRaise)
                fireRaiseCount++;
            DataRow drNew = dtNew.NewRow();
            foreach (DataColumn dcNew in dtNew.Columns)
            {
                drNew[dcNew] = dr[dcNew.Caption.Trim()];
            }
            dtNew.Rows.Add(drNew);
        }

        drNewTotal["信号"] = "";
        drNewTotal["涨停前收"] = totalCount.ToString();
        drNewStar["信号"] = "🌟";
        drNewStar["涨停前收"] = starCount.ToString();
        drNewTarget["信号"] = "🎯";
        drNewTarget["涨停前收"] = targetCount.ToString();
        drNewStarTarget["信号"] = "🌟🎯";
        drNewStarTarget["涨停前收"] = starTargetCount.ToString();

        drFire["信号"] = "🔥";
        drFire["涨停前收"] = fireRaiseCount.ToString() + "/" + fireCount.ToString();
        drFire["涨停收"] = Math.Round((double)fireRaiseCount * 100 / (double)fireCount, 2).ToString() + "%";

        for (int i = 1; i <= 6; i++)
        {
            if (totalCount>0)
                drNewTotal[((i == 6) ? "总计" : i.ToString() + "日")] = Math.Round(100*(double)totalRaiseCount[i-1] / (double)totalCount, 2).ToString() + "%";
            if (starCount>0)
                drNewStar[((i == 6) ? "总计" : i.ToString() + "日")] = Math.Round(100*(double)startRaiseCount[i-1] / (double)starCount, 2).ToString() + "%";
            if (targetCount>0)
                drNewTarget[((i == 6) ? "总计" : i.ToString() + "日")] = Math.Round(100*(double)targetRaiseCount[i-1] / (double)targetCount, 2).ToString() + "%";
            if (starTargetCount>0)
                drNewStarTarget[((i == 6) ? "总计" : i.ToString() + "日")] = Math.Round(100*(double)starTargetRaiseCount[i-1] / (double)starTargetCount, 2).ToString() + "%";
        }
        dtNew.Rows.Add(drNewTotal);
        dtNew.Rows.Add(drNewStar);
        dtNew.Rows.Add(drNewTarget);
        dtNew.Rows.Add(drNewStarTarget);
        dtNew.Rows.Add(drFire);
        dt.Dispose();
        return dtNew;
    }

    public static DataTable GetData(DateTime date)
    {

        DataTable dt = new DataTable();
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("信号");
        dt.Columns.Add("涨停前收");
        dt.Columns.Add("涨停收");
        dt.Columns.Add("调整天数");
        dt.Columns.Add("缩量");
        dt.Columns.Add("缩量天数");
        dt.Columns.Add("下跌天数");
        dt.Columns.Add("最低价");
        dt.Columns.Add("现价");
        dt.Columns.Add("买入价");
        dt.Columns.Add("F5");
        for (int i = 1; i <= 5; i++)
        {
            dt.Columns.Add(i.ToString() + "日");
        }
        dt.Columns.Add("总计");
        if (!Util.IsTransacDay(date))
        {
            return dt;
        }


        DataTable dtTmp = DBHelper.GetDataTable(" select * from limit_up where alert_date < '" + date.ToShortDateString()
            + "'  and alert_date > '" + date.AddDays(-15).ToShortDateString() + "'  order by alert_date desc ");
        DataTable dtOri = dtTmp.Clone();
        foreach (DataRow drTmp in dtTmp.Rows)
        {
            if (dtOri.Select(" gid = '" + drTmp["gid"].ToString() + "' ").Length == 0)
            {
                DataRow drOri = dtOri.NewRow();
                foreach (DataColumn dcOri in dtOri.Columns)
                {
                    drOri[dcOri] = drTmp[dcOri.Caption.Trim()];
                }
                dtOri.Rows.Add(drOri);
            }
        }


        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock stock = new Stock(drOri["gid"].ToString());
            stock.LoadKLineDay();
            int limitUpIndex = stock.GetItemIndex(Util.GetDay(DateTime.Parse(drOri["alert_date"].ToString().Trim())));
            int currentIndex = stock.GetItemIndex(Util.GetDay(date));
            if (limitUpIndex <= 0 || currentIndex <= 1 || currentIndex - limitUpIndex > 7)
            {
                continue;
            }
            double beforeLimitUpSettlePrice = 0;
            double limitUpSettlePrice = 0;
            double limitUpVolume = 0;
            double currentPrice = stock.kLineDay[currentIndex].endPrice;
            if ((currentPrice - stock.kLineDay[currentIndex - 1].endPrice) / stock.kLineDay[currentIndex - 1].endPrice >= 0.095)
            {
                continue;
            }
            double boxLowestPrice = currentPrice;
            int continuesReduceVolumeDays = 0;
            int continuesFallingDownPriceDays = 0;
            bool continuesReduceVolume = true;
            bool continueFallingDownPrice = true;

            beforeLimitUpSettlePrice = stock.kLineDay[limitUpIndex - 1].endPrice;
            limitUpSettlePrice = stock.kLineDay[limitUpIndex].endPrice;
            limitUpVolume = stock.kLineDay[limitUpIndex].volume;

            for (int i = currentIndex ; i > limitUpIndex; i--)
            {
                boxLowestPrice = Math.Min(boxLowestPrice, stock.kLineDay[i].EntityLowPrice);
                if (i > limitUpIndex + 1)
                {
                    if (stock.kLineDay[i].EntityLowPrice > stock.kLineDay[i - 1].EntityLowPrice)
                    {
                        continueFallingDownPrice = false;
                    }
                    if (stock.kLineDay[i].volume > stock.kLineDay[i - 1].volume)
                    {
                        continuesReduceVolume = false;
                    }
                    if (continuesReduceVolume)
                    {
                        continuesReduceVolumeDays++;
                    }
                    if (continueFallingDownPrice)
                    {
                        continuesFallingDownPriceDays++;
                    }
                }
            }
            if (boxLowestPrice <= beforeLimitUpSettlePrice)
            {
                continue;
            }
            bool signal = false;
            KeyValuePair<string, double>[] qArr = stock.GetSortedQuota(currentIndex);

            switch (currentIndex - limitUpIndex)
            {
                case 1:
                    if (stock.kLineDay[currentIndex].volume / limitUpVolume <= 0.85)
                        signal = true;
                    break;
                case 2:
                    if (stock.kLineDay[currentIndex].volume / limitUpVolume <= 0.65 && continuesReduceVolumeDays >= 1 && continuesFallingDownPriceDays >= 1)
                        signal = true;
                    break;
                case 3:
                    if (stock.kLineDay[currentIndex].volume / limitUpVolume <= 0.65 && continuesReduceVolumeDays >= 1 && continuesFallingDownPriceDays >= 1 )
                        signal = true;
                    break;
                case 4:
                    if (stock.kLineDay[currentIndex].volume / limitUpVolume <= 0.40 && continuesReduceVolumeDays >= 2 && continuesFallingDownPriceDays >= 1 )
                        signal = true;
                    break;
                case 5:
                    if (stock.kLineDay[currentIndex].volume / limitUpVolume <= 0.40 && continuesReduceVolumeDays >= 2 && continuesFallingDownPriceDays >= 1 )
                        signal = true;
                    break;
                case 6:
                    if (stock.kLineDay[currentIndex].volume / limitUpVolume <= 0.20 && continuesReduceVolumeDays >= 3 && continuesFallingDownPriceDays >= 2)
                        signal = true;
                    break;
                case 7:
                    if (stock.kLineDay[currentIndex].volume / limitUpVolume <= 0.20 && continuesReduceVolumeDays >= 3 && continuesFallingDownPriceDays >= 2 )
                        signal = true;
                    break;
                default:
                    break;
            }


            if (!stock.kLineDay[currentIndex].IsCrossStar || stock.kLineDay[currentIndex].HaveMast)
                signal = false;
            DataRow dr = dt.NewRow();
            dr["代码"] = drOri["gid"].ToString();
            dr["名称"] = stock.Name.Trim();
            dr["信号"] = "";
            if (boxLowestPrice >= limitUpSettlePrice && stock.kLineDay[currentIndex].volume / limitUpVolume <= 0.3 && currentPrice > stock.GetAverageSettlePrice(currentIndex, 3, 3))
            {
                dr["信号"] = "🌟";
            }
            if (signal)
                dr["信号"] = dr["信号"] + "🎯";

            dr["涨停前收"] = beforeLimitUpSettlePrice;
            dr["涨停收"] = limitUpSettlePrice;
            dr["调整天数"] = currentIndex - limitUpIndex;
            dr["缩量"] = stock.kLineDay[currentIndex].volume / limitUpVolume;
            dr["缩量天数"] = continuesReduceVolumeDays;
            dr["下跌天数"] = continuesFallingDownPriceDays;
            dr["最低价"] = boxLowestPrice;
            dr["现价"] = currentPrice;
            double f5Price = Math.Round(Util.GetRaiseGoldLine(stock.kLineDay[limitUpIndex].lowestPrice, stock.kLineDay[limitUpIndex].highestPrice)[4], 2);
            double f3Price = Math.Round(Util.GetRaiseGoldLine(stock.kLineDay[limitUpIndex].lowestPrice, stock.kLineDay[limitUpIndex].highestPrice)[2], 2);
            double buyPrice = f5Price*1.005;
            if (stock.kLineDay[currentIndex].lowestPrice >= buyPrice)
                buyPrice = stock.kLineDay[currentIndex].endPrice;
            dr["买入价"] = buyPrice;
            dr["F5"] = f5Price;
            if (stock.kLineDay[currentIndex].endPrice < f3Price)
                dr["信号"] = dr["信号"].ToString() + "💩";
            if (stock.kLineDay[currentIndex].endPrice > f5Price
                && Math.Abs(stock.kLineDay[currentIndex].lowestPrice - f5Price) / f5Price <= 0.005
                && stock.kLineDay[currentIndex].endPrice > stock.kLineDay[currentIndex].lowestPrice)
            {
                dr["信号"] = dr["信号"].ToString() + "🛍️";
            }
            double maxPercent = -1;
            for (int i = 1; i <= 5 ; i++)
            {
                if (i + currentIndex < stock.kLineDay.Length)
                {
                    dr[i.ToString() + "日"] = (stock.kLineDay[currentIndex + i].highestPrice - buyPrice) / buyPrice;
                    maxPercent = Math.Max(maxPercent, (stock.kLineDay[currentIndex + i].highestPrice - buyPrice) / buyPrice);
                    if ((stock.kLineDay[currentIndex + i].highestPrice - stock.kLineDay[currentIndex + i - 1].endPrice) / stock.kLineDay[currentIndex + i - 1].endPrice >= 0.03
                        && i < 5 && currentIndex + i < stock.kLineDay.Length
                        && dr["信号"].ToString().IndexOf("🔥") < 0 && stock.kLineDay[currentIndex].IsCrossStar )
                    {
                        if ((currentIndex + i < stock.kLineDay.Length - 1)
                            || (currentIndex + i == stock.kLineDay.Length - 1 && Util.GetDay(stock.kLineDay[currentIndex + i].startDateTime) < Util.GetDay(DateTime.Now)))
                            dr["信号"] = dr["信号"].ToString().Trim() + "🔥";
                        else
                            dr["信号"] = dr["信号"].ToString().Trim() + "🔺";
                        //dr["买入价"] = stock.kLineDay[currentIndex + i - 1].endPrice * 1.03;
                        //dr["买入日"] = i;
                    }
                }
                else
                {
                    dr[i.ToString() + "日"] = "-";
                }
            }
            dr["总计"] = maxPercent;
            dt.Rows.Add(dr);
        }
        return dt;
    }

    public static void PageWatcher()
    {
        for (; true;)
        {
            DateTime currentDate = Util.GetDay(DateTime.Now);
            for (int i = 1; i <= 4; i++)
            {
                currentDate = currentDate.AddDays(-1);
                if (Util.IsTransacDay(currentDate))
                {
                    if (Util.IsTransacTime(DateTime.Now))
                    {
                        DataTable dt = GetData(currentDate);
                        foreach (DataRow dr in dt.Rows)
                        {
                            KLine.RefreshKLine(dr["代码"].ToString().Trim(), DateTime.Parse(DateTime.Now.ToShortDateString()));
                            if (dr["信号"].ToString().IndexOf("🔺") >= 0)
                            {
                                string message = dr["信号"].ToString().Trim() + " " + currentDate.ToShortDateString() + "十字星缩量" + Math.Round(100 * double.Parse(dr["缩量"].ToString().Trim()), 2).ToString() + "% 已调整" + dr["调整天数"].ToString().Trim() + "日";
                                double price = Math.Round(double.Parse(dr["买入价"].ToString()), 2);

                                if (StockWatcher.AddAlert(DateTime.Parse(DateTime.Now.ToShortDateString()),
                                    dr["代码"].ToString().Trim(),
                                    "limit_up_box",
                                    dr["名称"].ToString().Trim(),
                                    "买入价：" + price.ToString() + " " + message.Trim()))
                                {
                                    StockWatcher.SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", dr["代码"].ToString().Trim(), dr["名称"].ToString() + " " + message, price, "volumedecrease");
                                    StockWatcher.SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", dr["代码"].ToString().Trim(), dr["名称"].ToString() + " " + message, price, "volumedecrease");
                                }
                            }

                        }
                    }
                }
                else
                {
                    i--;
                }
            }
            Thread.Sleep(60000);
            threadCount++;
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
                <td>
        <asp:Calendar ID="calendar" runat="server" Width="100%" BackColor="White" BorderColor="Black" BorderStyle="Solid"  CellSpacing="1" Font-Names="Verdana" Font-Size="9pt" ForeColor="Black" Height="250px" NextPrevFormat="ShortMonth" OnSelectionChanged="calendar_SelectionChanged" >
            <DayHeaderStyle Font-Bold="True" Font-Size="8pt" ForeColor="#333333" Height="8pt" />
            <DayStyle BackColor="#CCCCCC" />
            <NextPrevStyle Font-Bold="True" Font-Size="8pt" ForeColor="White" />
            <OtherMonthDayStyle ForeColor="#999999" />
            <SelectedDayStyle BackColor="#333399" ForeColor="White" />
            <TitleStyle BackColor="#333399" BorderStyle="Solid" Font-Bold="True" Font-Size="12pt" ForeColor="White" Height="12pt" />
            <TodayDayStyle BackColor="#999999" ForeColor="White" />
        </asp:Calendar>
                </td>
            </tr>
            <tr>
                <td><asp:DataGrid ID="dg" runat="server" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" Width="100%" >
                    <AlternatingItemStyle BackColor="#DCDCDC" />
                    <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
                    <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
                    <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
                    <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
                    <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
                    </asp:DataGrid></td>
            </tr>
            <tr>
                <td><%=t.ThreadState.ToString() %>|<%=threadCount.ToString() %></td>
            </tr>
        </table>
    </div>
    </form>
</body>
</html>
