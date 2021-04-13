<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Threading" %>
<!DOCTYPE html>
<script runat="server">

    public DateTime currentDate = Util.GetDay(DateTime.Now);

    public string sort = "MACD日,KDJ日,综指 desc";

    public static int rate = 10;

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    protected void Page_Load(object sender, EventArgs e)
    {

        sort = Util.GetSafeRequestValue(Request, "sort", "红绿灯日");
        if (!IsPostBack)
        {
            rate = int.Parse(Util.GetSafeRequestValue(Request, "rate", "100").Trim());
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
        return RenderHtml(dtOri.Select("", sort));
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
            double currentPrice = Math.Round((double)drOri["买入"], 2);
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
                        case "F3":
                        case "F5":
                            double supportPrice = (double)drOri[i];
                            dr[i] = "<font color=\"gray\"  >" + Math.Round(supportPrice, 2).ToString() + "</font>";
                            if (!drOri["支撑"].ToString().Trim().Equals(""))
                            {
                                dr[drOri["支撑"].ToString()] = "<font color=\"red\"  >" + Math.Round(supportPrice, 2).ToString() + "</font>";
                            }
                            break;
                        case "今开":
                        case "现价":
                        case "前低":
                        case "F1":
                        case "现高":
                        case "3线":
                            double currentValuePrice = (double)drOri[i];
                            dr[i] = "<font color=\"" + (currentValuePrice > currentPrice ? "red" : (currentValuePrice == currentPrice ? "gray" : "green")) + "\"  >"
                                + Math.Round(currentValuePrice, 2).ToString() + "</font>";
                            break;
                        case "价差":
                            double priceDiff = (double)drOri[i];
                            dr[i] = "<font color=\"gray\"  >"  + Math.Round(priceDiff, 2).ToString() + "</font>";
                            break;
                        case "今涨":
                        default:
                            if (System.Text.RegularExpressions.Regex.IsMatch(drArr[0].Table.Columns[i].Caption.Trim(), "\\d日")
                                || drArr[0].Table.Columns[i].Caption.Trim().Equals("总计") || drArr[0].Table.Columns[i].Caption.Trim().Equals("今涨"))
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

            if (drOri["信号"].ToString().IndexOf("💩") < 0)
            {

            }
            else
            {
                shitCount++;
            }
        }



        DataRow drTotal = dt.NewRow();
        drTotal["红绿灯日"] = "总计";
        drTotal["信号"] = totalCount.ToString();
        /*
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
        */
        for (int i = 1; i < 7; i++)
        {
            string columeCaption = ((i == 6) ? "总计" : i.ToString() + "日");
            drTotal[columeCaption] = Math.Round(100 * (double)totalSum[i - 1] / (double)totalCount, 2).ToString() + "%";
            /*
            drFire[columeCaption] = Math.Round(100 * (double)fireSum[i-1] / (double)fireCount, 2).ToString() + "%";
            drRaise[columeCaption] = Math.Round(100 * (double)raiseSum[i-1] / (double)raiseCount, 2).ToString() + "%";
            drStar[columeCaption] = Math.Round(100 * (double)starSum[i - 1] / (double)starCount, 2).ToString() + "%";
            */
        }

        dt.Rows.Add(drTotal);
        /*
        dt.Rows.Add(drShit);
        dt.Rows.Add(drRaise);
        dt.Rows.Add(drFire);
        dt.Rows.Add(drStar);
        */

    }

    public static DataTable GetData(DateTime currentDate)
    {
        currentDate = Util.GetDay(currentDate);
        DateTime limitUpDate = Util.GetLastTransactDate(currentDate, 1);
        DataTable dt = new DataTable();
        dt.Columns.Add("红绿灯日", Type.GetType("System.String"));
        dt.Columns.Add("代码", Type.GetType("System.String"));
        dt.Columns.Add("名称", Type.GetType("System.String"));
        dt.Columns.Add("信号", Type.GetType("System.String"));
        dt.Columns.Add("3线", Type.GetType("System.Double"));
        dt.Columns.Add("买入", Type.GetType("System.Double"));

        for (int i = 1; i <= 10; i++)
        {
            dt.Columns.Add(i.ToString() + "日", Type.GetType("System.Double"));
        }
        dt.Columns.Add("总计", Type.GetType("System.Double"));
        if (!Util.IsTransacDay(currentDate))
        {
            return dt;
        }



        DataTable dtOri = DBHelper.GetDataTable("select * from alert_traffic_light where alert_date > '"
            + Util.GetLastTransactDate(currentDate, 5).ToShortDateString() + "' and alert_date <= '"
            + currentDate.ToShortDateString() + "' "
            //+ "  and gid = 'sh603222' "
            );



        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock stock = new Stock(drOri["gid"].ToString().Trim());
            stock.LoadKLineDay(rc);
            int currentIndex = stock.GetItemIndex(currentDate);
            if (currentIndex < 1)
                continue;
            int trafficLightIndex = stock.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (trafficLightIndex < 1)
            {
                continue;
            }
            if (!stock.IsLimitUp(currentIndex))
            {
                continue;
            }
            bool haveLimitUp = false;
            for (int i = trafficLightIndex; i < currentIndex; i++)
            {
                if (stock.IsLimitUp(i))
                {
                    haveLimitUp = true;
                    break;
                }
            }
            if (haveLimitUp)
            {
                continue;
            }




            double buyPrice = stock.kLineDay[currentIndex].endPrice;



            DataRow dr = dt.NewRow();
            dr["红绿灯日"] = stock.kLineDay[trafficLightIndex].endDateTime.ToShortDateString();
            dr["代码"] = stock.gid.Trim();
            dr["名称"] = stock.Name.Trim();
            dr["3线"] = stock.GetAverageSettlePrice(currentIndex, 3, 3);
            dr["买入"] = buyPrice;
            double highPrice = 0;
            for (int i = 1; i <= 10 ; i++)
            {
                if (currentIndex + i < stock.kLineDay.Length)
                {
                    highPrice = Math.Max(stock.kLineDay[currentIndex + i].endPrice, highPrice);
                    dr[i.ToString() + "日"] = (stock.kLineDay[currentIndex + i].endPrice - buyPrice) / buyPrice;
                }
            }
            dr["总计"] = (highPrice - buyPrice) / buyPrice;
            dt.Rows.Add(dr);

        }
        return dt;
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
        Response.Headers.Add("Content-Disposition", "attachment; filename=volume_reduce_"
            + currentDate.ToShortDateString() + ".txt");
        Response.Write(content.Trim());
        Response.End();


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
                    <asp:BoundColumn DataField="红绿灯日" HeaderText="红绿灯日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="代码" HeaderText="代码"></asp:BoundColumn>
                    <asp:BoundColumn DataField="名称" HeaderText="名称"></asp:BoundColumn>
                    <asp:BoundColumn DataField="信号" HeaderText="信号" SortExpression="信号|desc" ></asp:BoundColumn>
                    
                    <asp:BoundColumn DataField="3线" HeaderText="3线"></asp:BoundColumn>
                   
                    <asp:BoundColumn DataField="买入" HeaderText="买入"  ></asp:BoundColumn>
                    <asp:BoundColumn DataField="1日" HeaderText="1日" SortExpression="1日|desc" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="2日" HeaderText="2日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="3日" HeaderText="3日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="4日" HeaderText="4日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="5日" HeaderText="5日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="6日" HeaderText="6日"></asp:BoundColumn>
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
