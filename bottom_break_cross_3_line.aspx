<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Text" %>
<!DOCTYPE html>

<script runat="server">

    public string allGids = "";

    
    public static Core.RedisClient rc = new Core.RedisClient("52.82.51.144");

    protected void Page_Load(object sender, EventArgs e)
    {
        
        if (!IsPostBack)
        {
            calendar.SelectedDate = Util.GetDay(DateTime.Now);
            dg.DataSource = GetHtmlData(GetData().Select("", " 放量 desc "));
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

    public static DataTable GetData(DateTime date)
    {
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


        dt.Columns.Add("现价", Type.GetType("System.Double"));
        dt.Columns.Add("前低", Type.GetType("System.Double"));
        dt.Columns.Add("现高", Type.GetType("System.Double"));

        dt.Columns.Add("KDJ日", Type.GetType("System.Int32"));
        dt.Columns.Add("MACD日", Type.GetType("System.Int32"));

        dt.Columns.Add("1日", Type.GetType("System.Double"));
        dt.Columns.Add("2日", Type.GetType("System.Double"));
        dt.Columns.Add("3日", Type.GetType("System.Double"));
        dt.Columns.Add("4日", Type.GetType("System.Double"));
        dt.Columns.Add("5日", Type.GetType("System.Double"));
        dt.Columns.Add("总计", Type.GetType("System.Double"));

        DataTable dtOri = DBHelper.GetDataTable(" select * from dbo.bottom_break_cross_3_line where suggest_date = '"
            + date.ToShortDateString() + "' and  (going_down_3_line_days >= 5 or under_3_line_days >= 5)  order by  going_down_3_line_days desc, under_3_line_days desc ");

        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock stock = new Stock(drOri["gid"].ToString().Trim());
            //allGids = allGids + "," + stock.gid.Trim();
            stock.LoadKLineDay(rc);
            int currentIndex = stock.GetItemIndex(date);
            if (currentIndex < 6)
                continue;
            double startPrice = stock.kLineDay[currentIndex].startPrice;
            double today3LinePrice = stock.GetAverageSettlePrice(currentIndex, 3, 3);
            double buyPrice = Math.Max(startPrice, today3LinePrice);
            double currentPrice = stock.kLineDay[currentIndex].endPrice;
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
            dr["代码"] = stock.gid.Trim();
            dr["名称"] = drOri["name"].ToString().Trim();
            dr["信号"] =  "";
            dr["信号"] = dr["信号"].ToString() + (currentPrice <= today3LinePrice ? "💩": "");
            dr["信号"] = dr["信号"].ToString().Trim() + (( ValidKLine(stock.kLineDay[currentIndex]) && newBuyPrice != 0  && volumeIncrease > 0.33 && supportPrice > 0) ? "<a title=\"下有均线支撑，上均线压力在3%之外，放量超1/3。\" >📈</a>" : "");
            dr["信号"] = dr["信号"].ToString().Trim() + ((currentPrice > today3LinePrice && (currentPrice - buyPrice) / buyPrice <= 0.015 && dr["信号"].ToString().IndexOf("📈")>=0) ? "<a title=\"当前价格高于3线，但是在提示买入价的正负1%之内。\" >🛍️</a>" : "");
            if (currentIndex > 0
                && ((newBuyPrice==0?buyPrice:newBuyPrice) - stock.kLineDay[currentIndex - 1].endPrice)/stock.kLineDay[currentIndex-1].endPrice >= 0.03 )
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"买入价上涨超3%\" >🔥</a>";
            }

            if (stock.kLineDay[currentIndex].startPrice > stock.kLineDay[currentIndex - 1].highestPrice
                && stock.kLineDay[currentIndex].startPrice > today3LinePrice)
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"跳空3线\" >🌟</a>";
            }

            dr["现价"] = stock.kLineDay[currentIndex].endPrice;
            dr["前低"] = 0;
            dr["现高"] = 0;

            dr["今开"] = startPrice;
            dr["3线价"] = today3LinePrice;
            buyPrice = ((newBuyPrice != 0) ? newBuyPrice : buyPrice);
            dr["买入价"] = buyPrice;
            dr["收盘价"] = currentPrice;
            dr["放量"] = (currentVolume - lastDayVolume) / lastDayVolume;
            dr["3线势"] = int.Parse(drOri["going_down_3_line_days"].ToString());
            dr["K线势"] = int.Parse(drOri["under_3_line_days"].ToString());
            dr["均线压力"] = pressure;
            dr["上涨空间"] = upSpacePercent;
            dr["均线支撑"] = supportPrice;
            dr["KDJ日"] = stock.kdjDays(currentIndex);
            dr["MACD日"] = stock.macdDays(currentIndex);
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
                        case "MACD差":
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
                        /*
                    case "价差":
                        double currentValuePrice1 = (double)drOri[i];
                        dr[i] = Math.Round(currentValuePrice1, 2).ToString();
                        break;
                        */
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
                                try
                                {
                                    double currentValue = (double)drOri[i];
                                    dr[i] = Math.Round(currentValue * 100, 2).ToString() + "%";
                                }
                                catch
                                {

                                }
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
            dr["代码"] = "<a href=\"show_K_line_day.aspx?gid=" + gid.Trim() + "&maxprice=" + hightPrice.ToString() + "&minprice=" + lowPrice.ToString() + "\" target=\"_blank\" >" + dr["代码"].ToString() + "</a>";
            dr["名称"] = "<a href=\"io_volume_detail.aspx?gid=" + gid.Trim() + "&date=" + calendar.SelectedDate.ToShortDateString() + "\" target=\"_blank\" >" + dr["名称"].ToString() + "</a>";
            dt.Rows.Add(dr);
        }
        AddTotal(drArr, dt);
        return dt;
    }


    public DataTable GetHtmlData(DataRow[] drOriArr)
    {

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


    public void AddTotal1(DataTable dt)
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
        dg.DataSource = GetHtmlData(GetData().Select("", " 放量 desc "));
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

                    <asp:BoundColumn DataField="KDJ日" HeaderText="KDJ日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="MACD日" HeaderText="MACD日"></asp:BoundColumn>

                    <asp:BoundColumn DataField="今开" HeaderText="今开"></asp:BoundColumn>
                    <asp:BoundColumn DataField="3线价" HeaderText="3线价"></asp:BoundColumn>
                    <asp:BoundColumn DataField="买入价" HeaderText="买入价"></asp:BoundColumn>
                    <asp:BoundColumn DataField="收盘价" HeaderText="收盘价"></asp:BoundColumn>
                    <asp:BoundColumn DataField="放量" HeaderText="放量" SortExpression="放量|desc"></asp:BoundColumn>
                    
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

    </table>
    </form>
</body>
</html>
