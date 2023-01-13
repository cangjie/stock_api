<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public string sort = "";

    protected void Page_Load(object sender, EventArgs e)
    {
        sort = Util.GetSafeRequestValue(Request, "sort", "MACD周");
        if (!IsPostBack)
        {
            DateTime nowDate = DateTime.Parse(DateTime.Now.Year.ToString() + "-" + DateTime.Now.Month.ToString() + "-1");
            for (DateTime i = nowDate; i >= DateTime.Parse("2020-1-1"); i = i.AddMonths(-1))
            {
                monthSelector.Items.Add(new ListItem(i.Year.ToString() + "-" + i.Month.ToString(), i.ToShortDateString()));
            }
            DataTable dt = RenderHtml(GetData(nowDate).Select("", sort));
            dg.DataSource = dt;
            dg.DataBind();
        }
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
            //double currentPrice = Math.Round((double)drOri["现价"], 2);
            //double lowPrice = Math.Round((double)drOri["前低"], 2);
            //double hightPrice =  Math.Round((double)drOri["现高"], 2);
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
                        case "风险":
                            dr[i] = Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2).ToString();
                            break;
                        case "买入":
                            double buyPrice = Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2);
                            dr[i] = Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2).ToString() ;
                            break;
                        case "F3":
                        case "F5":
                            double currentValuePrice2 = (double)drOri[i];


                            break;
                        case "今开":
                        case "现价":
                        case "前低":
                        case "F1":
                        case "现高":
                        case "3线":


                        case "价差":
                            double currentValuePrice1 = (double)drOri[i];
                            dr[i] = Math.Round(currentValuePrice1, 2).ToString();
                            break;

                        default:
                            if (System.Text.RegularExpressions.Regex.IsMatch(drArr[0].Table.Columns[i].Caption.Trim(), "\\d日")
                                || drArr[0].Table.Columns[i].Caption.Trim().Equals("总计") || drArr[0].Table.Columns[i].Caption.Trim().Equals("红绿灯涨")
                                || drArr[0].Table.Columns[i].Caption.Trim().Equals("涨幅"))
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


    public DataTable GetData(DateTime currentDate)
    {
        DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up where alert_date >= '" + currentDate.ToShortDateString()
            + "' and alert_date < '" + currentDate.AddMonths(1).ToShortDateString() + "' ");


        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.String"));
        dt.Columns.Add("代码", Type.GetType("System.String"));
        dt.Columns.Add("名称", Type.GetType("System.String"));
        dt.Columns.Add("信号", Type.GetType("System.String"));

        dt.Columns.Add("3线", Type.GetType("System.Double"));
        dt.Columns.Add("买入", Type.GetType("System.Double"));
        dt.Columns.Add("KDJ日", Type.GetType("System.Int32"));
        dt.Columns.Add("MACD日", Type.GetType("System.Int32"));
        dt.Columns.Add("KDJ周", Type.GetType("System.Int32"));
        dt.Columns.Add("MACD周", Type.GetType("System.Int32"));
        dt.Columns.Add("总计", Type.GetType("System.Double"));
        for (int i = 0; i <= 10; i++)
        {
            dt.Columns.Add(i.ToString() + "日", Type.GetType("System.Double"));
        }

        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock stock = new Stock(drOri["gid"].ToString().Trim());
            DateTime alertDate = DateTime.Parse(drOri["alert_date"].ToString().Trim());
            stock.LoadKLineDay(Util.rc);
            int currentIndex = stock.GetItemIndex(alertDate);
            if (currentIndex <= 0)
            {
                continue;
            }
            if (!stock.IsLimitUp(currentIndex))
            {
                continue;
            }
            if (stock.kLineDay[currentIndex].endPrice >= stock.GetAverageSettlePrice(currentIndex, 3, 3))
            {
                continue;
            }


            KLine.ComputeMACD(stock.kLineDay);
            KLine.ComputeRSV(stock.kLineDay);
            KLine.ComputeKDJ(stock.kLineDay);



            stock.LoadKLineWeek(Util.rc);
            stock.kArr = stock.kLineWeek;
            KLine.ComputeMACD(stock.kLineWeek);
            KLine.ComputeRSV(stock.kLineWeek);
            KLine.ComputeKDJ(stock.kLineWeek);
            int currentWeekIndex = stock.GetItemIndex(currentDate, "week");
            int macdWeek = stock.macdWeeks(currentWeekIndex);
            int kdjWeek =  stock.kdjWeeks(currentWeekIndex);
            stock.kArr = stock.kLineDay;


            double buyPrice = stock.kLineDay[currentIndex].endPrice;

            DataRow dr = dt.NewRow();
            dr["日期"] = alertDate.ToShortDateString();
            dr["代码"] = stock.gid.Trim();
            dr["名称"] = stock.Name.Trim();







            dr["3线"] = stock.GetAverageSettlePrice(currentIndex, 3, 3);
            dr["KDJ日"] = stock.kdjDays(currentIndex);

            dr["MACD日"] = stock.macdDays(currentIndex);
            dr["KDJ周"] = kdjWeek;

            dr["MACD周"] = macdWeek;



            dr["买入"] = buyPrice;

            double maxPrice = 0;




            for (int i = 1; i <= 10; i++)
            {
                if (currentIndex + i >= stock.kLineDay.Length)
                    break;
                double highPrice = stock.kLineDay[currentIndex + i].highestPrice;
                maxPrice = Math.Max(maxPrice, highPrice);
                dr[i.ToString() + "日"] = (highPrice - stock.kLineDay[currentIndex].endPrice) / stock.kLineDay[currentIndex].endPrice;
            }
            dr["总计"] = (maxPrice - stock.kLineDay[currentIndex].endPrice) / stock.kLineDay[currentIndex].endPrice;




            dt.Rows.Add(dr);
        }


        return dt;
    }

    protected void monthSelector_SelectedIndexChanged(object sender, EventArgs e)
    {
        DateTime nowDate = DateTime.Parse(monthSelector.SelectedValue);
        DataTable dt = RenderHtml(GetData(nowDate).Select("", sort));
        dg.DataSource = dt;
        dg.DataBind();
    }

    protected void btn_Click(object sender, EventArgs e)
    {
        DateTime nowDate = DateTime.Parse(monthSelector.SelectedValue);
        DataTable dtDownload = GetData(nowDate);
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
            if (gid.Trim().Length == 8)
            {
                content += gid.Substring(2, 6) + "\r\n";
            }
        }
        Response.Clear();
        Response.ContentType = "text/plain";
        Response.Headers.Add("Content-Disposition", "attachment; filename=traffic_light_"
            + nowDate.ToShortDateString() + ".txt");
        Response.Write(content.Trim());
        Response.End();
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>3线下涨停按月</title>
</head>
<body>
    <form id="form1" runat="server">
        <div>
            <asp:DropDownList runat="server" ID="monthSelector" AutoPostBack="True" OnSelectedIndexChanged="monthSelector_SelectedIndexChanged" >


            </asp:DropDownList>
            <asp:Button runat="server" ID="btn" Text=" 下 载 " OnClick="btn_Click" />
        </div>
        <div>
            <asp:DataGrid ID="dg" runat="server" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" Width="100%" AutoGenerateColumns="False"  AllowSorting="True" >
                <AlternatingItemStyle BackColor="#DCDCDC" />
                <Columns>
                    <asp:BoundColumn DataField="日期" HeaderText="日期"></asp:BoundColumn>
                    <asp:BoundColumn DataField="代码" HeaderText="代码"></asp:BoundColumn>
                    <asp:BoundColumn DataField="名称" HeaderText="名称"></asp:BoundColumn>
                   
					<asp:BoundColumn DataField="MACD日" HeaderText="MACD日" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="KDJ日" HeaderText="KDJ日" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="MACD周" HeaderText="MACD周" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="KDJ周" HeaderText="KDJ周" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="3线" HeaderText="3线"></asp:BoundColumn>
                    
                 
                    <asp:BoundColumn DataField="买入" HeaderText="买入"  ></asp:BoundColumn>
                    
                    
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
                </asp:DataGrid>

        </div>
    </form>
</body>
</html>
