<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Threading" %>
<!DOCTYPE html>

<script runat="server">

    public string sort = "放量 desc";

    public static ThreadStart ts = new ThreadStart(PageWatcher);

    public static Thread t = new Thread(ts);

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
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
            dg.DataSource = GetData();
            dg.DataBind();
        }
    }

    public DataTable GetData()
    {
        DateTime currentDate = calendar.SelectedDate;
        if (currentDate.Year < 2000)
            currentDate = DateTime.Now;
        DataTable dtOri = GetData(currentDate);
        DataRow[] drOriArr = dtOri.Select(Util.GetSafeRequestValue(Request, "whereclause", "").Trim(), sort + ", 总计 desc");
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

        int shitCount = 0;

        foreach (DataRow drOri in drOriArr)
        {
            if (drOri["信号"].ToString().IndexOf("💩") < 0)
            {
                totalCount++;
                if (drOri["信号"].ToString().IndexOf("📈") > 0)
                {
                    raiseCount++;
                }
                if (drOri["信号"].ToString().IndexOf("🔥") > 0)
                {
                    fireCount++;
                }
                for (int i = 1; i < 7; i++)
                {
                    string colName = ((i == 6) ? "总计" : i.ToString() + "日");
                    if (!drOri[colName].ToString().Equals("") && (double)(drOri[colName]) >= 0.01)
                    {
                        totalSum[i - 1]++;
                        if (drOri["信号"].ToString().IndexOf("📈") > 0)
                        {
                            raiseSum[i - 1]++;
                        }
                        if (drOri["信号"].ToString().IndexOf("🔥") > 0)
                        {
                            fireSum[i - 1]++;
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
        drFire["信号"] = "🔥";
        drFire["昨收"] = fireCount.ToString();
        for (int i = 1; i < 7; i++)
        {
            string columeCaption = ((i == 6) ? "总计" : i.ToString() + "日");
            drTotal[columeCaption] = Math.Round(100 * (double)totalSum[i - 1] / (double)totalCount, 2).ToString() + "%";
            drFire[columeCaption] = Math.Round(100 * (double)fireSum[i-1] / (double)fireCount, 2).ToString() + "%";
            drRaise[columeCaption] = Math.Round(100 * (double)raiseSum[i-1] / (double)raiseCount, 2).ToString() + "%";
        }

        dt.Rows.Add(drTotal);
        dt.Rows.Add(drShit);
        dt.Rows.Add(drRaise);
        dt.Rows.Add(drFire);
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
                        case "昨收":
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

    public static DataTable GetData(DateTime currentDate)
    {
        currentDate = Util.GetDay(currentDate);
        DataTable dtOri = new DataTable();
        SqlDataAdapter da = new SqlDataAdapter(" select * from macd_alert where alert_time = '" + currentDate.ToShortDateString() + " 15:00' ", Util.conStr);
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
        dt.Columns.Add("3线", Type.GetType("System.Double"));
        dt.Columns.Add("低点", Type.GetType("System.Double"));
        dt.Columns.Add("F3", Type.GetType("System.Double"));
        dt.Columns.Add("F5", Type.GetType("System.Double"));
        dt.Columns.Add("高点", Type.GetType("System.Double"));
        dt.Columns.Add("买入", Type.GetType("System.Double"));
        for (int i = 1; i <= 5; i++)
        {
            dt.Columns.Add(i.ToString() + "日", Type.GetType("System.Double"));
        }
        dt.Columns.Add("总计", Type.GetType("System.Double"));
        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock stock = new Stock(drOri["gid"].ToString().Trim());
            stock.LoadKLineDay();
            int currentIndex = stock.GetItemIndex(currentDate);
            if (currentIndex < 1)
                continue;
            DataRow dr = dt.NewRow();
            dr["代码"] = stock.gid.Trim();
            dr["名称"] = stock.Name.Trim();
            dr["信号"] = "";
            double settlePrice = stock.kLineDay[currentIndex - 1].endPrice;
            double openPrice = stock.kLineDay[currentIndex].startPrice;
            double currentPrice = stock.kLineDay[currentIndex].endPrice;
            dr["昨收"] = settlePrice;
            dr["今开"] = openPrice;
            dr["今收"] = currentPrice;

            dr["今涨"] = (stock.kLineDay[currentIndex].highestPrice - settlePrice) / settlePrice;
            DateTime lastDate = DateTime.Parse(stock.kLineDay[currentIndex - 1].startDateTime.ToShortDateString());
            double lastDayVolume = Stock.GetVolumeAndAmount(stock.gid, lastDate)[0];
            double currentVolume = Stock.GetVolumeAndAmount(stock.gid, currentDate)[0];
            double volumeIncrease = (currentVolume - lastDayVolume) / lastDayVolume;
            dr["放量"] = currentVolume / lastDayVolume;
            int kdjDays = stock.kdjDays(currentIndex);
            dr["kdj"] = kdjDays.ToString();
            dr["3线"] = stock.GetAverageSettlePrice(currentIndex, 3, 3);
            double lowestPrice = stock.LowestPrice(currentDate, 20);
            double highestPrice = stock.HighestPrice(currentDate, 40);
            double f3 = lowestPrice + (highestPrice - lowestPrice) * 0.382;
            double f5 = lowestPrice + (highestPrice - lowestPrice) * 0.618;
            double buyPrice = stock.kLineDay[currentIndex].startPrice;
            double todayHigh = stock.kLineDay[currentIndex].highestPrice;
            if (todayHigh < lowestPrice * 0.985)
            {
                buyPrice = todayHigh;
            }
            else if (openPrice < lowestPrice * 0.985 && todayHigh >= lowestPrice * 0.985)
            {
                buyPrice = lowestPrice * 0.985;
            }
            else if (openPrice < f3 * 0.985 && todayHigh >= f3 * 0.985)
            {
                buyPrice = f3 * 0.985;
            }
            else if (openPrice < f5 && todayHigh >= f5 * 0.985)
            {
                buyPrice = f5 * 0.985;
            }
            else if (openPrice < highestPrice * 0.985 && todayHigh >= highestPrice * 0.985)
            {
                buyPrice = highestPrice * 0.985;
            }
            else
            {
                buyPrice = openPrice;
            }

            buyPrice = Math.Max(buyPrice, double.Parse(drOri["price"].ToString()));
            buyPrice = Math.Round(buyPrice, 2);
            /*
            if (openPrice < lowestPrice * 0.985 && todayHigh >= lowestPrice * 0.985)
            {
                buyPrice = lowestPrice * 0.985;
            }
            else if (openPrice < f3 * 0.985 && todayHigh >= f3 * 0.985)
            {
                buyPrice = f3 * 0.985;
            }
            else if (openPrice < f5 * 0.985 && todayHigh >= f5 * 0.985)
            {
                buyPrice = f5 * 0.985;
            }
            else if (openPrice < highestPrice * 0.985 && todayHigh >= highestPrice * 0.985)
            {
                buyPrice = highestPrice * 0.985;
            }
            else
            {
                buyPrice = openPrice;
            }
            */
            /*

            if (buyPrice > highestPrice * 1.005)
                buyPrice = Math.Max(highestPrice * 1.005, openPrice);
            else if (buyPrice > f5 * 1.005 )
                buyPrice = Math.Max(openPrice, f5 * 1.005);
            else if (buyPrice > f3 * 1.005)
                buyPrice = Math.Max(openPrice, f3 * 1.005 );
            else if (buyPrice > lowestPrice * 1.005 )
                buyPrice = Math.Max(openPrice, lowestPrice * 1.005);
            else
            {
                buyPrice = currentPrice;
            }
            */
            dr["低点"] = lowestPrice;
            dr["F3"] = f3;
            dr["F5"] = f5;
            dr["高点"] = highestPrice;
            dr["买入"] = buyPrice;
            if (kdjDays > -1 && kdjDays < 2 &&   buyPrice > lowestPrice && buyPrice < f3 * 0.985 && (double)dr["今涨"] <= 0.09)
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"开盘价距离F3有1.5%的上涨空间\" >📈</a>";
            }
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

            if (kdjDays > -1 && kdjDays < 2 &&  currentPrice < f3 &&  currentVolume < lastDayVolume )
            {
                //dr["信号"] = dr["信号"].ToString() + "<a title=\"价格低于F3，KDJ金叉1日内，缩量\" >🔥</a>";
            }
            if (Math.Abs(currentPrice - buyPrice) / currentPrice <= 0.005)
            {
                dr["信号"] = dr["信号"].ToString() + "🛍️";
            }
            KLine.ComputeMACD(stock.kLineDay);
            if (currentPrice <= double.Parse(dr["3线"].ToString().Trim()) )
            {
                dr["信号"] = dr["信号"].ToString() + "💩";
            }
            KLine.ComputeMACD(stock.kLineDay);
            if (Math.Abs(stock.kLineDay[currentIndex].dea - 0) < 0.05 && Math.Abs(stock.kLineDay[currentIndex].dif - 0) < 0.05)
            {
                dr["信号"] = dr["信号"].ToString() + "🔥";
            }

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

    public static void SearchMacdKdjAlert()
    {
        for(; Util.IsTransacDay(Util.GetDay(DateTime.Now)) && Util.IsTransacTime(DateTime.Now); )
        {
            string[] gidArr = Util.GetAllGids();
            for (int i = 0; i < gidArr.Length; i++)
            {
                Stock stock = new Stock(gidArr[i].Trim());
                stock.LoadKLineDay();
                KLine.ComputeRSV(stock.kLineDay);
                KLine.ComputeKDJ(stock.kLineDay);
                KLine.ComputeMACD(stock.kLineDay);
                KLine.SearchMACDAlert(stock.kLineDay, stock.kLineDay.Length - 1);
                KLine.SearchKDJAlert(stock.kLineDay, stock.kLineDay.Length - 1);
            }
            System.Threading.Thread.Sleep(60000);
        }

    }

    public static void PageWatcher()
    {
        for (; true;)
        {
            if (Util.IsTransacDay(DateTime.Parse(DateTime.Now.ToShortDateString())) && Util.IsTransacTime(DateTime.Now))
            {
                DataTable dt = GetData(Util.GetDay(DateTime.Now));
                foreach (DataRow dr in dt.Rows)
                {
                    if ((double)dr["放量"] >= 1 && dr["信号"].ToString().IndexOf("📈") >= 0 && dr["信号"].ToString().IndexOf("🛍️") >= 0 && dr["信号"].ToString().IndexOf("💩") < 0)
                    {
                        string gid = dr["代码"].ToString().Trim();
                        Stock s = new Stock(gid);
                        KLine.RefreshKLine(gid, DateTime.Parse(DateTime.Now.ToShortDateString()));
                        double volumeIncrease = Math.Round(100 * double.Parse(dr["放量"].ToString().Trim()), 2);
                        string message = "放量：" + volumeIncrease.ToString() + "%，KDJ：" + dr["KDJ"].ToString().Trim() + "，买入："
                            + Math.Round((double)dr["买入"], 2).ToString() + "，现价：" + Math.Round((double)dr["今收"], 2)
                            + "，F3：" + Math.Round((double)dr["F3"], 2).ToString() + "，F5：" + Math.Round((double)dr["F5"], 2).ToString();
                        if (StockWatcher.AddAlert(Util.GetDay(DateTime.Now), gid, "macd", s.Name.Trim(), message))
                        {
                            StockWatcher.SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", s.gid.Trim(), s.Name + " " + message, Math.Round((double)dr["今收"], 2), "macd");
                        }
                    }
                }
            }
            Thread.Sleep(60000);
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
                    <asp:BoundColumn DataField="昨收" HeaderText="昨收"></asp:BoundColumn>
                    <asp:BoundColumn DataField="今开" HeaderText="今开"></asp:BoundColumn>
                    <asp:BoundColumn DataField="今收" HeaderText="今收"></asp:BoundColumn>
                    <asp:BoundColumn DataField="今涨" HeaderText="今涨" SortExpression="今涨|desc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="放量" HeaderText="放量" SortExpression="放量|desc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="KDJ" HeaderText="KDJ" SortExpression="KDJ|asc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="3线" HeaderText="3线"></asp:BoundColumn>
                    <asp:BoundColumn DataField="低点" HeaderText="低点"></asp:BoundColumn>
                    <asp:BoundColumn DataField="F3" HeaderText="F3"></asp:BoundColumn>
                    <asp:BoundColumn DataField="F5" HeaderText="F5"></asp:BoundColumn>
                    <asp:BoundColumn DataField="高点" HeaderText="高点"></asp:BoundColumn>
                    <asp:BoundColumn DataField="买入" HeaderText="买入"  ></asp:BoundColumn>
                    <asp:BoundColumn DataField="1日" HeaderText="1日"></asp:BoundColumn>
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
            <tr>
                <td><%=t.ThreadState.ToString() %></td>
            </tr>
        </table>
    </div>
    </form>
</body>
</html>
