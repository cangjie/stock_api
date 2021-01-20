<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<!DOCTYPE html>

<script runat="server">

    public string sort = "";



    protected void Page_Load(object sender, EventArgs e)
    {

        sort = Util.GetSafeRequestValue(Request, "sort", "幅度 desc");
        if (!IsPostBack)
        {
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
        DataRow[] drOriArr = dtOri.Select(Util.GetSafeRequestValue(Request, "whereclause", "   ").Trim(), sort);
        return RenderHtml(drOriArr);
    }

    public void AddTotal(DataRow[] drOriArr, DataTable dt)
    {
        int totalCount = 0;
        int[] totalSum = new int[] { 0, 0, 0, 0, 0, 0,0,0,0,0,0 };

        int raiseCount = 0;
        int[] raiseSum = new int[] { 0, 0, 0, 0, 0, 0,0,0,0,0,0 };

        int fireCount = 0;
        int[] fireSum = new int[] { 0, 0, 0, 0, 0, 0,0,0,0,0,0 };

        int starCount = 0;
        int[] starSum = new int[] { 0, 0, 0, 0, 0, 0,0,0,0,0,0 };

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
                for (int i = 1; i < 12; i++)
                {
                    string colName = ((i == 11) ? "总计" : i.ToString() + "日");
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
        drTotal["名称"] = "总计";
        drTotal["买入"] = totalCount.ToString();



        for (int i = 1; i < 12; i++)
        {
            string columeCaption = ((i == 11) ? "总计" : i.ToString() + "日");
            drTotal[columeCaption] = Math.Round(100 * (double)totalSum[i - 1] / (double)totalCount, 2).ToString() + "%";

        }

        dt.Rows.Add(drTotal);

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

                        case "低点":
                        case "F1":
                        case "F3":
                        case "F5":
                        case "高点":
                        case "3线":
                            double currentValuePrice = (double)drOri[i];
                            dr[i] = "<font color=\"" + (currentValuePrice > currentPrice ? "red" : (currentValuePrice == currentPrice ? "gray" : "green")) + "\"  >"
                                + Math.Round(currentValuePrice, 2).ToString() + "</font>";
                            break;
                        case "今开":
                        default:
                            if (System.Text.RegularExpressions.Regex.IsMatch(drArr[0].Table.Columns[i].Caption.Trim(), "\\d日")
                                || drArr[0].Table.Columns[i].Caption.Trim().Equals("总计")  || drArr[0].Table.Columns[i].Caption.Trim().Equals("今开") )
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
            string gid = dr["代码"].ToString();
            dr["代码"] = "<a href=\"show_K_line_day.aspx?gid=" + dr["代码"].ToString() + "\" target=\"_blank\" >" + dr["代码"].ToString() + "</a>";
            dr["名称"] = "<a href=\"io_volume_detail.aspx?gid=" + gid.Trim() + "&date=" + calendar.SelectedDate.ToShortDateString() + "\" target=\"_blank\" >" + dr["名称"].ToString() + "</a>";
            dt.Rows.Add(dr);
        }
        AddTotal(drArr, dt);
        return dt;
    }

    public static DataTable GetData(DateTime currentDate)
    {

        DataTable dtOri = DBHelper.GetDataTable(" select  alert_date, gid from limit_up where alert_date = '"
            + Util.GetLastTransactDate(currentDate, 2).ToShortDateString() + "'  "
            //+ " and gid = 'sz300124' "
            );

        /*
        SqlDataAdapter da = new SqlDataAdapter(" select *  from alert_line35_gold_cross where alert_date = '" + currentDate.ToShortDateString() + "'  ", Util.conStr);
        da.Fill(dtOri);
        
        */
        DataTable dt = new DataTable();
        dt.Columns.Add("代码", Type.GetType("System.String"));
        dt.Columns.Add("名称", Type.GetType("System.String"));
        dt.Columns.Add("信号", Type.GetType("System.String"));
        dt.Columns.Add("放量", Type.GetType("System.Double"));
        dt.Columns.Add("KDJ", Type.GetType("System.Int32"));
        dt.Columns.Add("MACD", Type.GetType("System.Int32"));
        dt.Columns.Add("3线", Type.GetType("System.Double"));
        dt.Columns.Add("3线日", Type.GetType("System.Int32"));
        dt.Columns.Add("日差", Type.GetType("System.Int32"));
        dt.Columns.Add("幅度", Type.GetType("System.Double"));
        dt.Columns.Add("买入", Type.GetType("System.Double"));
        for (int i = 0; i <= 10; i++)
        {
            dt.Columns.Add(i.ToString() + "日", Type.GetType("System.Double"));
        }
        dt.Columns.Add("总计", Type.GetType("System.Double"));

        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock stock = new Stock(drOri["gid"].ToString().Trim());

            stock.LoadKLineDay(Util.rc);
            int currentIndex = stock.GetItemIndex(currentDate) - 2;
            if (currentIndex <= 10 || currentIndex >= stock.kLineDay.Length - 1)
            {
                continue;
            }
            if (!stock.IsLimitUp(currentIndex))
            {
                continue;
            }
            int buyIndex = currentIndex + 2;

            if (stock.kLineDay[currentIndex - 1].endPrice >= stock.GetAverageSettlePrice(currentIndex - 1, 3, 3)
                || stock.kLineDay[currentIndex].endPrice <= stock.GetAverageSettlePrice(currentIndex, 3, 3))
            {
                continue;
            }

            if (stock.kLineDay[currentIndex + 1].highestPrice <= stock.kLineDay[currentIndex].highestPrice
                || stock.kLineDay[currentIndex + 1].startPrice <= stock.kLineDay[currentIndex + 1].endPrice)
            {
                continue;
            }

            if (stock.kLineDay[currentIndex].volume * 1.1 <= stock.kLineDay[currentIndex + 1].volume)
            {
                continue;
            }

            double highestPrice = stock.kLineDay[currentIndex + 1].highestPrice;
            double lowestPrice = double.MaxValue;
            bool up3Line = false;
            double last3Line = stock.GetAverageSettlePrice(currentIndex - 1, 3, 3);
            for (int i = currentIndex - 1; i >= 0 && !up3Line; i--)
            {
                lowestPrice = Math.Min(stock.kLineDay[i].lowestPrice, lowestPrice);
                if (stock.GetAverageSettlePrice(i, 3, 3) < stock.kLineDay[i].endPrice )
                {
                    up3Line = true;
                    break;
                }
            }
            double f3 = lowestPrice + (highestPrice - lowestPrice) * 0.382;
            double f5 = lowestPrice + (highestPrice - lowestPrice) * 0.618;

            if (stock.kLineDay[buyIndex].endPrice >= f5 || stock.kLineDay[buyIndex].endPrice <= f3
                || stock.kLineDay[buyIndex].endPrice <= stock.kLineDay[buyIndex].startPrice)
            {
                continue;
            }

            KLine.ComputeMACD(stock.kLineDay);
            KLine.ComputeKDJ(stock.kLineDay);

            double buyPrice = stock.kLineDay[buyIndex].endPrice;

            double currentPrice = stock.kLineDay[buyIndex - 1].endPrice;

            DataRow dr = dt.NewRow();
            dr["代码"] = stock.gid.Trim();
            dr["名称"] = stock.Name.Trim();
            dr["信号"] = "";
            dr["KDJ"] = stock.kdjDays(currentIndex);
            int macdDays = stock.macdDays(currentIndex);
            dr["MACD"] = macdDays;
            dr["3线"] = 0;
            dr["3线日"] = 0;
            dr["买入"] = buyPrice;
            dr["放量"] = 0;
            dr["日差"] = 0;
            dr["幅度"] = 0;
            double maxPrice = 0;
            dr["0日"] = (buyPrice - currentPrice) / currentPrice;
            for (int i = 1; i <= 10; i++)
            {
                if (buyIndex + i >= stock.kLineDay.Length)
                    break;
                double highPrice = stock.kLineDay[buyIndex + i].highestPrice;
                maxPrice = Math.Max(maxPrice, highPrice);
                dr[i.ToString() + "日"] = (highPrice - buyPrice) / buyPrice;
            }
            dr["总计"] = (maxPrice - buyPrice) / buyPrice;
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
        Response.Write(e.SortExpression);
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
                    <asp:BoundColumn DataField="信号" HeaderText="信号"  ></asp:BoundColumn>
                    <asp:BoundColumn DataField="放量" HeaderText="放量" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="KDJ" HeaderText="KDJ" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="MACD" HeaderText="MACD" ></asp:BoundColumn>
                    

                    
                    <asp:BoundColumn DataField="幅度" HeaderText="幅度" ></asp:BoundColumn>
                   			
                    <asp:BoundColumn DataField="买入" HeaderText="买入"  ></asp:BoundColumn>
			        
                    <asp:BoundColumn DataField="0日" HeaderText="0日" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="1日" HeaderText="1日"  ></asp:BoundColumn>
                    <asp:BoundColumn DataField="2日" HeaderText="2日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="3日" HeaderText="3日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="4日" HeaderText="4日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="5日" HeaderText="5日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="6日" HeaderText="6日" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="7日" HeaderText="7日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="8日" HeaderText="8日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="9日" HeaderText="9日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="10日" HeaderText="10日"></asp:BoundColumn>
                    <asp:BoundColumn DataField="总计" HeaderText="总计"  ></asp:BoundColumn>
                </Columns>
                <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
                <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
                <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
                <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
                <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
                </asp:DataGrid></td>
            </tr>
            <tr>
                <td><%=sort %></td>
            </tr>
        </table>
    </div>
    </form>
</body>
</html>
