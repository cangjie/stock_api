<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Text" %>
<!DOCTYPE html>

<script runat="server">

    public string allGids = "";

    public static ThreadStart ts = new ThreadStart(PageWatcher);

    public static Thread t = new Thread(ts);

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
            calendar.SelectedDate = Util.GetDay(DateTime.Now);
            dg.DataSource = GetHtmlData(GetData().Select("", " 上涨空间 desc "));
            dg.DataBind();
        }
    }

    public static bool ValidKLine(KLine k)
    {
        bool ret = false;
        if (k.startPrice < k.endPrice && k.highestPrice - k.endPrice < (k.endPrice - k.startPrice) / 2)
            ret = true;
        return ret;
    }

    public  DataTable GetData()
    {
        DataTable dt = GetData(calendar.SelectedDate);
        if (Util.GetSafeRequestValue(Request, "filter", "1").Trim().Equals("1"))
        {
            for (int i = 0; i < dt.Rows.Count; i++)
            {
                try
                {
                    double volumePercent = double.Parse(dt.Rows[i]["放量"].ToString().Trim());
                    if (volumePercent < 1)
                    {
                        dt.Rows.RemoveAt(i);
                        i--;
                    }
                }
                catch
                {

                }
            }
        }
        return dt;
    }

    public static void PageWatcher()
    {
        for (; true;)
        {
            if (Util.IsTransacDay(DateTime.Parse(DateTime.Now.ToShortDateString())) && Util.IsTransacTime(DateTime.Now))
            {
                DataTable dt = GetData(DateTime.Parse(DateTime.Now.ToShortDateString()));
                foreach (DataRow dr in dt.Rows)
                {
                    string signal = dr["信号"].ToString().Trim();
                    if (signal.IndexOf("💩") < 0 && signal.IndexOf("📈") >= 0 && (signal.IndexOf("🔥") >= 0 || signal.IndexOf("🛍️") >= 0))
                    {
                        string gid = dr["代码"].ToString().Trim();
                        Stock s = new Stock(gid);
                        KLine.RefreshKLine(gid, DateTime.Parse(DateTime.Now.ToShortDateString()));
                        double volumeIncrease = Math.Round(100 * double.Parse(dr["放量"].ToString().Trim()), 2);
                        double upSpace = Math.Round(100 * double.Parse(dr["上涨空间"].ToString()), 2);
                        string message = (dr["信号"].ToString().Trim().IndexOf("📈")>=0?"📈":"")
                            + (dr["信号"].ToString().Trim().IndexOf("🔥")>=0?"🔥":"") + (dr["信号"].ToString().Trim().IndexOf("🛍️")>=0?"🛍️":"")
                            + " 放量：" + volumeIncrease.ToString() + "% 上涨空间：" + upSpace.ToString() + "% " + dr["3线势"].ToString() + ":" + dr["K线势"].ToString();
                        double price = Math.Round(double.Parse(dr["买入价"].ToString()), 2);

                        if (StockWatcher.AddAlert(DateTime.Parse(DateTime.Now.ToShortDateString()),
                            gid,
                            "bottom_break_cross_3_line",
                            s.Name.Trim(),
                            "买入价：" + price.ToString() + " " + message.Trim()) && volumeIncrease > 100)
                        {
                            StockWatcher.SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", s.gid.Trim(), s.Name + " " + message, price, "3_line");
                            //StockWatcher.SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", s.gid.Trim(), s.Name + " " + message, price, "3_line");
                        }
                    }
                }
            }
            Thread.Sleep(60000);
        }
    }

    public static DataTable GetData(DateTime date)
    {
        DataTable dtMacd = DBHelper.GetDataTable(" select gid, alert_price from alert_macd where alert_type in ('day', '1hr') and  alert_time >= '" + date.ToShortDateString() + "' and alert_time < '" + date.ToShortDateString() + " 23:00' ");
        DataTable dtKdj = DBHelper.GetDataTable(" select gid, alert_price from alert_kdj where alert_type in ('day', '1hr') and alert_time >= '" + date.ToShortDateString() + "' and alert_time < '" + date.ToShortDateString() + " 23:00' ");
        DataTable dtCci = DBHelper.GetDataTable(" select gid, alert_price  from alert_cci where alert_type in ('day', '1hr') and alert_time >= '" + date.ToShortDateString() + "' and alert_time < '" + date.ToShortDateString() + " 23:00' ");


        DataTable dt = new DataTable();
        dt.Columns.Add("代码", Type.GetType("System.String"));
        dt.Columns.Add("名称", Type.GetType("System.String"));
        dt.Columns.Add("信号", Type.GetType("System.String"));
        dt.Columns.Add("今开", Type.GetType("System.Double"));
        dt.Columns.Add("3线价", Type.GetType("System.Double"));
        dt.Columns.Add("买入价", Type.GetType("System.Double"));
        dt.Columns.Add("收盘价", Type.GetType("System.Double"));
        dt.Columns.Add("均线压力", Type.GetType("System.Double"));
        dt.Columns.Add("均线支撑", Type.GetType("System.Double"));
        dt.Columns.Add("上涨空间", Type.GetType("System.Double"));
        dt.Columns.Add("放量", Type.GetType("System.Double"));
        dt.Columns.Add("3线势", Type.GetType("System.Int32"));
        dt.Columns.Add("K线势", Type.GetType("System.Int32"));
        dt.Columns.Add("MACD", Type.GetType("System.Int32"));
        dt.Columns.Add("KDJ", Type.GetType("System.Int32"));
        dt.Columns.Add("1日", Type.GetType("System.Double"));
        dt.Columns.Add("2日", Type.GetType("System.Double"));
        dt.Columns.Add("3日", Type.GetType("System.Double"));
        dt.Columns.Add("4日", Type.GetType("System.Double"));
        dt.Columns.Add("5日", Type.GetType("System.Double"));
        dt.Columns.Add("总计", Type.GetType("System.Double"));

        DataTable dtOri = DBHelper.GetDataTable(" select * from dbo.bottom_break_cross_3_line where suggest_date = '"
            + date.ToShortDateString() + "' and ( going_down_3_line_days >= 4 and under_3_line_days >= 4 and (going_down_3_line_days >= 5 or  under_3_line_days >= 5  )  ) order by  going_down_3_line_days desc, under_3_line_days desc ");

        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock stock = new Stock(drOri["gid"].ToString().Trim());
            //allGids = allGids + "," + stock.gid.Trim();
            stock.LoadKLineDay();
            int currentIndex = stock.GetItemIndex(date);
            if (currentIndex < 6)
                continue;
            double startPrice = stock.kLineDay[currentIndex].startPrice;
            double today3LinePrice = stock.GetAverageSettlePrice(currentIndex, 3, 3);
            double buyPrice = Math.Max(startPrice, today3LinePrice);
            double currentPrice
                = stock.kLineDay[currentIndex].startDateTime.ToShortDateString().Equals(DateTime.Now.ToShortDateString()) ?
                stock.LastTrade: stock.kLineDay[currentIndex].endPrice ;
            KeyValuePair<string, double>[] quotaArr = stock.GetSortedQuota(currentIndex);
            //bool jumpEmpty3Line = startPrice > today3LinePrice;
            double newBuyPrice = 0;
            bool after3Line = false;
            bool afterLowest = false;
            for (int i = 0; i < quotaArr.Length ; i++)
            {
                if (quotaArr[i].Key.Trim().Equals("3_line_price"))
                    after3Line = true;
                if (quotaArr[i].Key.Trim().Equals("lowest_price"))
                    afterLowest = true;

                if (i < quotaArr.Length - 1)
                {
                    if (after3Line && afterLowest &&   quotaArr[i].Value * 1.03 < quotaArr[i + 1].Value)
                    {
                        newBuyPrice = quotaArr[i].Value;
                        break;
                    }
                }
                else
                {
                    if (quotaArr[i].Value < stock.kLineDay[currentIndex].highestPrice)
                        newBuyPrice = quotaArr[i].Value;
                }
            }

            if (newBuyPrice > stock.kLineDay[currentIndex].highestPrice)
                newBuyPrice = 0;
            DateTime currentDate = DateTime.Parse(stock.kLineDay[currentIndex].startDateTime.ToShortDateString());
            DateTime lastDate = DateTime.Parse(stock.kLineDay[currentIndex - 1].startDateTime.ToShortDateString());
            if (currentDate.ToShortDateString().Equals(DateTime.Now.ToShortDateString()))
            {
                currentDate = DateTime.Now;
                lastDate = DateTime.Parse(lastDate.ToShortDateString() + " " + DateTime.Now.ToShortTimeString());
            }
            else
            {
                currentDate = DateTime.Parse(currentDate.ToShortDateString() + " 16:00");
                lastDate = DateTime.Parse(lastDate.ToShortDateString() + " 16:00");
            }
            double lastDayVolume = Stock.GetVolumeAndAmount(stock.gid, lastDate)[0];
            double currentVolume = Stock.GetVolumeAndAmount(stock.gid, currentDate)[0];
            double pressure = stock.GetMaPressure(currentIndex, (newBuyPrice==0?buyPrice:newBuyPrice));
            double upSpacePercent = (pressure - currentPrice) / currentPrice;
            double volumeIncrease = (currentVolume - lastDayVolume) / lastDayVolume;


            double supportPrice = stock.GetMaSupport(currentIndex, (newBuyPrice==0?buyPrice:newBuyPrice));



            DataRow dr = dt.NewRow();

            int kdjDays = stock.kdjDays(currentIndex);

            double sigalPrice = 0;
            DataRow[] drSigArr = dtMacd.Select(" gid = '" + stock.gid.Trim() + "' ");
            if (drSigArr.Length > 0)
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"macd\" >🔥</a>";
                sigalPrice = double.Parse(drSigArr[0]["alert_price"].ToString().Trim());
            }
            drSigArr = dtKdj.Select(" gid = '" + stock.gid.Trim() + "' ");
            if (drSigArr.Length > 0 || kdjDays == 0)
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"kdj\" >🔥</a>";
                sigalPrice = sigalPrice == 0?  double.Parse(drSigArr[0]["alert_price"].ToString().Trim()) : sigalPrice;
            }
            drSigArr = dtCci.Select(" gid = '" + stock.gid.Trim() + "' ");
            if (drSigArr.Length > 0)
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"cci\" >🔥</a>";
                sigalPrice = sigalPrice == 0?  double.Parse(drSigArr[0]["alert_price"].ToString().Trim()) : sigalPrice;
            }

           



            dr["代码"] = stock.gid.Trim();
            dr["名称"] = drOri["name"].ToString().Trim();
            dr["信号"] =  "";
            dr["信号"] = dr["信号"].ToString() + (currentPrice <= today3LinePrice ? "💩": "");
            dr["今开"] = startPrice;
            dr["3线价"] = today3LinePrice;
            buyPrice = ((newBuyPrice != 0) ? newBuyPrice : buyPrice);
            buyPrice = Math.Max(today3LinePrice, stock.kLineDay[currentIndex].startPrice);
            buyPrice = sigalPrice == 0 ? buyPrice : sigalPrice;
            dr["买入价"] = buyPrice;
            dr["收盘价"] = currentPrice;
            dr["放量"] = currentVolume  / lastDayVolume;
            dr["3线势"] = int.Parse(drOri["going_down_3_line_days"].ToString());
            dr["K线势"] = int.Parse(drOri["under_3_line_days"].ToString());
            dr["MACD"] = stock.macdDays(currentIndex);
            //dr["KDJ"] = 0;
            dr["KDJ"] = kdjDays;
            //dr["MACD"] = 0;
            //dr["KDJ"] = 0;
            double minPrice = GetLowestPriceKlineForDays(stock, currentIndex, 20).lowestPrice;
            double maxPrice = GetHighestPriceKlineForDays(stock, currentIndex, 20).highestPrice;
            pressure = (maxPrice - minPrice) * 0.382 + minPrice;
            upSpacePercent = (pressure - buyPrice) / buyPrice;
            dr["均线压力"] = pressure;
            dr["上涨空间"] = upSpacePercent;
            if (upSpacePercent > 0 && (upSpacePercent * 100 +  (currentVolume - lastDayVolume) / lastDayVolume) > 4  )
                dr["信号"] = dr["信号"].ToString().Trim() +  "<a title=\"放量且有上涨空间\" >📈</a>";

            dr["信号"] = dr["信号"].ToString().Trim() + ((currentPrice > buyPrice && (currentPrice - buyPrice) / buyPrice <= 0.01 && dr["信号"].ToString().IndexOf("📈")>=0) ? "<a title=\"当前价格高于3线，但是在提示买入价的正负1%之内。\" >🛍️</a>" : "");

            /*
            if (currentIndex > 0
                && (buyPrice - stock.kLineDay[currentIndex - 1].endPrice)/stock.kLineDay[currentIndex-1].endPrice >= 0.03 )
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"买入价上涨超3%\" >🔥</a>";
            }
            */



            dr["均线支撑"] = supportPrice;
            double maxIncreaseRate = 0;
            for (int i = 1; i <= 5 && i + currentIndex < stock.kLineDay.Length ; i++)
            {
                maxIncreaseRate = Math.Max(maxIncreaseRate, (stock.kLineDay[i + currentIndex].highestPrice - buyPrice) / buyPrice);
                dr[i.ToString() + "日"] = (stock.kLineDay[i + currentIndex].highestPrice - buyPrice) / buyPrice;
            }
            dr["总计"] = maxIncreaseRate;
            dt.Rows.Add(dr);
        }

        return dt;
    }

    public DataTable GetHtmlData(DataRow[] drOriArr)
    {
        if (drOriArr.Length == 0)
            return null;
        DataTable dt = new DataTable();
        foreach (DataColumn c in drOriArr[0].Table.Columns)
        {
            dt.Columns.Add(c.Caption.Trim(), Type.GetType("System.String"));
        }
        foreach (DataRow drOri in drOriArr)
        {
            allGids = allGids + "," + drOri["代码"].ToString();
        }
        if (!allGids.Trim().Equals(""))
        {
            allGids = allGids.Remove(0, 1);
        }
        foreach (DataRow drOri in drOriArr)
        {
            DataRow dr = dt.NewRow();
            dr["代码"] = "<a href=\"show_k_line_day.aspx?gid=" + drOri["代码"].ToString().Trim() + "&name="
                + Server.UrlEncode(drOri["名称"].ToString().Trim()) + "&gids=" + Server.UrlEncode(allGids.Trim()) + "\" target=\"_blank\" >"
                +  drOri["代码"].ToString().Trim().Remove(0, 2) + "</a>";
            dr["名称"] = "<a href=\"https://touzi.sina.com.cn/public/xray/details/" + drOri["代码"].ToString().Trim()
                + "\" target=\"_blank\"  >" + drOri["名称"].ToString().Trim() + "</a>";
            dr["信号"] = drOri["信号"].ToString();
            dr["今开"] = Math.Round(((double)drOri["今开"]), 2).ToString();
            dr["3线价"] = Math.Round(((double)drOri["3线价"]), 2).ToString();
            dr["买入价"] = Math.Round(((double)drOri["买入价"]), 2).ToString();
            dr["收盘价"] = Math.Round(((double)drOri["收盘价"]), 2).ToString();
            dr["放量"] = Math.Round(((double)drOri["放量"]) * 100, 2).ToString() + "%";
            dr["3线势"] = drOri["3线势"].ToString().Trim();
            dr["K线势"] = drOri["K线势"].ToString().Trim();
            dr["均线压力"] = Math.Round((double)drOri["均线压力"], 2).ToString();
            dr["上涨空间"] = Math.Round(100 * (double)drOri["上涨空间"], 2).ToString() + "%";
            dr["均线支撑"] = Math.Round((double)drOri["均线支撑"], 2).ToString();
            dr["MACD"] = drOri["MACD"].ToString();
            dr["KDJ"] = drOri["KDJ"].ToString();
            for (int i = 1; i <= 5; i++)
            {
                if (drOri[i.ToString() + "日"].GetType().Name.Trim().Equals("DBNull"))
                    break;
                double rate = (double)drOri[i.ToString() + "日"];
                dr[i.ToString() + "日"] = "<font color=\"" + ((rate >= 0.01) ? "red" : "green") + "\" >"
                    + Math.Round((rate * 100), 2).ToString() + "%</font>";
            }
            double rateTotal = (double)drOri["总计"];
            dr["总计"] = "<font color=\"" + ((rateTotal >= 0.01) ? "red" : "green") + "\" >"
                    + Math.Round((rateTotal * 100), 2).ToString() + "%</font>";
            dt.Rows.Add(dr);

        }
        AddTotal(dt);
        return dt;
    }

    public void AddTotal(DataTable dt)
    {
        double totalCount = dt.Rows.Count;
        double shitCount = 0;
        double increaseLogoCount = 0;
        double withoutShitTotal = 0;
        double fireCount = 0;
        double[] increaseLogoRedCountArr = new double[6];
        double[] withoutShitRedCountArr = new double[6];
        double[] fireCountArr = new double[6];

        foreach (DataRow dr in dt.Rows)
        {
            if (dr["信号"].ToString().IndexOf("💩") >= 0)
            {
                shitCount++;
            }
            else
            {
                if (dr["信号"].ToString().IndexOf("📈") >= 0)
                {
                    increaseLogoCount++;
                    for (int i = 1; i <= 5; i++)
                    {
                        if (dr[i.ToString() + "日"].ToString().IndexOf("red") >= 0)
                        {
                            increaseLogoRedCountArr[i - 1]++;
                        }
                    }
                    if (dr["总计"].ToString().IndexOf("red") >= 0)
                    {
                        increaseLogoRedCountArr[5]++;
                    }
                }
                if (dr["信号"].ToString().Trim().IndexOf("🔥") >= 0)
                {
                    fireCount++;
                    for (int i = 1; i <= 5; i++)
                    {
                        if (dr[i.ToString() + "日"].ToString().IndexOf("red") >= 0)
                        {
                            fireCountArr[i - 1]++;
                        }
                    }
                    if (dr["总计"].ToString().IndexOf("red") >= 0)
                    {
                        fireCountArr[5]++;
                    }
                }
                withoutShitTotal++;
                for (int i = 1; i <= 5; i++)
                {
                    if (dr[i.ToString() + "日"].ToString().IndexOf("red") >= 0)
                    {
                        withoutShitRedCountArr[i - 1]++;
                    }
                }
                if (dr["总计"].ToString().IndexOf("red") >= 0)
                {
                    withoutShitRedCountArr[5]++;
                }
            }
        }

        DataRow drTotal = dt.NewRow();
        drTotal["代码"] = "总计";
        for (int i = 1; i <= 5; i++)
        {
            drTotal[i.ToString() + "日"] = Math.Round(withoutShitRedCountArr[i - 1]*100/withoutShitTotal, 2).ToString() + "%";
        }
        drTotal["总计"] = Math.Round(withoutShitRedCountArr[5] * 100 / withoutShitTotal, 2).ToString() + "%";
        dt.Rows.Add(drTotal);

        DataRow drIncreaseLogo = dt.NewRow();
        drIncreaseLogo["代码"] = "📈";
        for (int i = 1; i <= 5; i++)
        {
            drIncreaseLogo[i.ToString() + "日"] = Math.Round(increaseLogoRedCountArr[i - 1] * 100 / increaseLogoCount, 2).ToString() + "%";
        }
        drIncreaseLogo["总计"] = Math.Round(increaseLogoRedCountArr[5] * 100 / increaseLogoCount, 2).ToString() + "%";
        dt.Rows.Add(drIncreaseLogo);

        DataRow drFireLogo = dt.NewRow();
        drFireLogo["代码"] = "🔥";
        for (int i = 1; i <= 5; i++)
        {
            drFireLogo[i.ToString() + "日"] = Math.Round(fireCountArr[i - 1] * 100 / fireCount, 2).ToString() + "%";
        }
        drFireLogo["总计"] = Math.Round(fireCountArr[5] * 100 / fireCount, 2).ToString() + "%";
        dt.Rows.Add(drFireLogo);

        DataRow drShit = dt.NewRow();
        drShit["代码"] = "💩";
        drShit["名称"] = shitCount.ToString() + "/" + totalCount.ToString();
        drShit["信号"] = Math.Round(100 * shitCount / totalCount, 2).ToString() + "%";
        dt.Rows.Add(drShit);
    }

    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {
        dg.DataSource = GetHtmlData(GetData().Select("", " 上涨空间 desc "));
        dg.DataBind();
    }

    protected void dg_SortCommand(object source, DataGridSortCommandEventArgs e)
    {
        DataTable dt = GetData();
        DataRow[] drArr = dt.Select("", e.SortExpression.Replace("|", "  "));

        dg.DataSource = GetHtmlData(drArr);
        dg.DataBind();

        string columnName = e.SortExpression.Split('|')[0].Trim();

        for (int i = 0; i < dg.Columns.Count; i++)
        {
            if (dg.Columns[i].SortExpression.StartsWith(columnName))
            {
                dg.Columns[i].SortExpression = columnName.Trim() + "|" + (e.SortExpression.EndsWith("asc")? "desc":"asc");
            }
        }
    }

    public static KLine GetHighestPriceKlineForDays(Stock stock, int currentIndex, int days)
    {
        double maxPrice = 0;
        KLine kLine = new KLine();
        for (int i = 0; i < days; i++)
        {
            if (currentIndex - i - 1 >= 0)
            {
                maxPrice = Math.Max(stock.kLineDay[currentIndex - i - 1].highestPrice, maxPrice);
                if (maxPrice == stock.kLineDay[currentIndex - i - 1].highestPrice)
                {
                    kLine = stock.kLineDay[currentIndex - i - 1];
                }
            }
        }
        return kLine;
    }

    public static KLine GetLowestPriceKlineForDays(Stock stock, int currentIndex, int days)
    {
        double minPrice = double.MaxValue;
        KLine kLine = new KLine();
        for (int i = 0; i < days; i++)
        {
            if (currentIndex - i - 1 >= 0)
            {
                minPrice = Math.Min(stock.kLineDay[currentIndex - i - 1].highestPrice, minPrice);
                if (minPrice == stock.kLineDay[currentIndex - i - 1].highestPrice)
                {
                    kLine = stock.kLineDay[currentIndex - i - 1];
                }
            }
        }
        return kLine;
    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
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
                    <asp:BoundColumn DataField="今开" HeaderText="今开"></asp:BoundColumn>
                    <asp:BoundColumn DataField="3线价" HeaderText="3线价"></asp:BoundColumn>
                    <asp:BoundColumn DataField="买入价" HeaderText="买入价"></asp:BoundColumn>
                    <asp:BoundColumn DataField="收盘价" HeaderText="收盘价"></asp:BoundColumn>
                    <asp:BoundColumn DataField="放量" HeaderText="放量" SortExpression="放量|desc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="均线压力" HeaderText="均线压力"></asp:BoundColumn>
                    <asp:BoundColumn DataField="上涨空间" HeaderText="上涨空间" SortExpression="上涨空间|desc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="均线支撑" HeaderText="均线支撑"></asp:BoundColumn>
                    <asp:BoundColumn DataField="3线势" HeaderText="3线势"></asp:BoundColumn>
                    <asp:BoundColumn DataField="K线势" HeaderText="K线势"></asp:BoundColumn>
                    <asp:BoundColumn DataField="MACD" HeaderText="MACD"></asp:BoundColumn>
                    <asp:BoundColumn DataField="KDJ" HeaderText="KDJ"></asp:BoundColumn>
                    <asp:BoundColumn DataField="1日" HeaderText="1日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="2日" HeaderText="2日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="3日" HeaderText="3日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="4日" HeaderText="4日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="5日" HeaderText="5日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="总计" HeaderText="总计"></asp:BoundColumn>
                </Columns>
                <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
                <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
                <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
                <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
                <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
                </asp:DataGrid></td>
        </tr>
        <tr>
            <td><%=t.ThreadState.ToString() %></td>
        </tr>
    </table>
    </form>
</body>
</html>