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

        sort = Util.GetSafeRequestValue(Request, "sort", "今涨");
        if (!IsPostBack)
        {
            rate = int.Parse(Util.GetSafeRequestValue(Request, "rate", "10").Trim());
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
            double currentPrice = Math.Round((double)drOri["现价"], 2);
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
                        case "价差":
                            dr[i] = Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2).ToString();
                            break;
                        case "买入":

                            double buyPrice = Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2);
                            dr[i] = "<font color=\"" + ((buyPrice > currentPrice) ? "red" : ((buyPrice==currentPrice)? "gray" : "green")) + "\" >" + Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2).ToString() + "</font>";
                            break;
                        case "今开":
                        case "现价":
                        case "前低":
                        case "F1":
                        case "F3":
                        case "F5":
                        case "现高":
                        case "3线":
                            double currentValuePrice = (double)drOri[i];
                            dr[i] = "<font color=\"" + (currentValuePrice > currentPrice ? "red" : (currentValuePrice == currentPrice ? "gray" : "green")) + "\"  >"
                                + Math.Round(currentValuePrice, 2).ToString() + "</font>";
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

    public static DataTable GetData(DateTime currentDate)
    {
        currentDate = Util.GetDay(currentDate);
        DateTime limitUpDate = Util.GetLastTransactDate(currentDate, 5);
        DataTable dt = new DataTable();
        dt.Columns.Add("代码", Type.GetType("System.String"));
        dt.Columns.Add("名称", Type.GetType("System.String"));
        dt.Columns.Add("信号", Type.GetType("System.String"));
        dt.Columns.Add("缩量", Type.GetType("System.Double"));
        dt.Columns.Add("板数", Type.GetType("System.Int32"));
        dt.Columns.Add("现高", Type.GetType("System.Double"));
        dt.Columns.Add("F3", Type.GetType("System.Double"));
        dt.Columns.Add("F5", Type.GetType("System.Double"));
        dt.Columns.Add("前低", Type.GetType("System.Double"));
        dt.Columns.Add("幅度", Type.GetType("System.String"));
        dt.Columns.Add("3线", Type.GetType("System.Double"));
        dt.Columns.Add("今涨", Type.GetType("System.Double"));
        dt.Columns.Add("现价", Type.GetType("System.Double"));
        dt.Columns.Add("距F3", Type.GetType("System.Double"));
        dt.Columns.Add("买入", Type.GetType("System.Double"));
        dt.Columns.Add("价差", Type.GetType("System.Double"));
        dt.Columns.Add("KDJ日", Type.GetType("System.Int32"));
        dt.Columns.Add("MACD日", Type.GetType("System.Int32"));

        for (int i = 1; i <= 5; i++)
        {
            dt.Columns.Add(i.ToString() + "日", Type.GetType("System.Double"));
        }
        dt.Columns.Add("总计", Type.GetType("System.Double"));
        if (!Util.IsTransacDay(currentDate))
        {
            return dt;
        }

        //DateTime lastTransactDate = Util.GetLastTransactDate(currentDate, 1);
        //DateTime limitUpStartDate = Util.GetLastTransactDate(lastTransactDate, 4);

        DataTable dtGragonTigerList = DBHelper.GetDataTable(" select * from dragon_tiger_list where alert_date >= '" + Util.GetLastTransactDate(currentDate, 5)
            + "' and alert_date <= '" + currentDate.ToShortDateString() + "' ");


        DataTable dtOri = DBHelper.GetDataTable("select distinct gid from limit_up where alert_date >= '" + limitUpDate.ToShortDateString()
            + "' and alert_date  < '" + currentDate.ToShortDateString() + "'   ");

        DataTable dtFoot = DBHelper.GetDataTable(" select * from alert_foot_new where valid = 1 and alert_date = '" + currentDate.ToShortDateString() + "' ");



        /*
        DataTable dtOri = DBHelper.GetDataTable(" select  * from limit_up a where exists(select 'a' from limit_up b where a.gid = b.gid and b.alert_date = dbo.func_GetLastTransactDate(a.alert_date, 1))  "
            + " and a.alert_date = '" + lastTransactDate.ToShortDateString() + "' ");
        */

        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock stock = new Stock(drOri["gid"].ToString().Trim());



            stock.LoadKLineDay(rc);
            KLine.ComputeMACD(stock.kLineDay);
            KLine.ComputeRSV(stock.kLineDay);
            KLine.ComputeKDJ(stock.kLineDay);

            int currentIndex = stock.GetItemIndex(currentDate);
            if (currentIndex < 1)
                continue;


            int limitUpIndex = -1;

            for (int j = currentIndex; j >= 0 ; j--)
            {
                if (stock.IsLimitUp(j))
                {
                    limitUpIndex = j;
                    break;
                }
            }

            if (limitUpIndex == -1)
            {
                continue;
            }



            double limitUpMaxVolume = 0;

            for (int j = currentIndex - 1; j >= 0 && stock.IsLimitUp(j); j--)
            {
                limitUpMaxVolume = Math.Max(limitUpMaxVolume, stock.kLineDay[j].volume);
            }




            int limitUpNum = 0;

            for (int i = currentIndex - 1; i > 0 && stock.kLineDay[i].endPrice >= stock.GetAverageSettlePrice(i, 3, 3); i--)
            {
                if (stock.IsLimitUp(i))
                {
                    limitUpNum++;
                }
            }

            double supportSettle = stock.kLineDay[currentIndex - 1].endPrice;





            int highIndex = 0;
            int lowestIndex = 0;
            double lowest = GetFirstLowestPrice(stock.kLineDay, limitUpIndex, out lowestIndex);
            double highest = 0;
            for (int i = limitUpIndex; i < currentIndex; i++)
            {
                if (highest < stock.kLineDay[i].highestPrice)
                {
                    highest = stock.kLineDay[i].highestPrice;
                    highIndex = i;
                }
            }
            double f3 = highest - (highest - lowest) * 0.382;

            double f5 = highest - (highest - lowest) * 0.618;
            double line3Price = KLine.GetAverageSettlePrice(stock.kLineDay, currentIndex, 3, 3);
            double currentPrice = stock.kLineDay[currentIndex].endPrice;

            if ((highest - lowest) / lowest < 0.2)
            {
                continue;
            }

            bool line3Reverse = false;
            bool dmpReverse = false;
            double diff = 0;
            if (Math.Abs(stock.kLineDay[currentIndex].lowestPrice - line3Price) / line3Price < 0.005)
            {
                line3Reverse = true;
                diff = stock.kLineDay[currentIndex].lowestPrice - line3Price;
            }
            else
            {
                if (stock.macdDays(currentIndex) <= 3)
                {
                    continue;
                }
                double dmp = stock.dmp(currentIndex);
                if (stock.kLineDay[currentIndex].endPrice <= dmp || stock.kLineDay[currentIndex].lowestPrice >= dmp)
                {
                    continue;
                }

                dmpReverse = true;
                diff = stock.kLineDay[currentIndex].lowestPrice - dmp;
            }

            if (!dmpReverse && !line3Reverse)
            {
                continue;
            }

            double buyPrice = 0;
            double f3Distance = 0.382 - (highest - stock.kLineDay[currentIndex].lowestPrice) / (highest - lowest);

            double volumeToday = stock.kLineDay[currentIndex].volume;  //Stock.GetVolumeAndAmount(stock.gid, DateTime.Parse(currentDate.ToShortDateString() + " " + DateTime.Now.Hour.ToString() + ":" + DateTime.Now.Minute.ToString()))[0];

            double volumeYesterday = stock.kLineDay[currentIndex - 1].volume;// Stock.GetVolumeAndAmount(stock.gid, DateTime.Parse(stock.kLineDay[limitUpIndex].startDateTime.ToShortDateString() + " " + DateTime.Now.Hour.ToString() + ":" + DateTime.Now.Minute.ToString()))[0];


            double volumeReduce = stock.kLineDay[currentIndex].volume / limitUpMaxVolume;

            buyPrice = stock.kLineDay[currentIndex].endPrice;

            /*
            if (stock.kLineDay[currentIndex].startPrice > f3 * 0.99 && stock.kLineDay[currentIndex].lowestPrice < f3 * 1.01 )
            {
                buyPrice = f3 * 1.01 ;
            }
            if (buyPrice == 0)
            {
                buyPrice = stock.kLineDay[currentIndex].endPrice;
            }
            */

            DataRow dr = dt.NewRow();
            dr["代码"] = stock.gid.Trim();
            dr["名称"] = stock.Name.Trim();
            dr["信号"] = "";




            dr["板数"] = limitUpNum.ToString();
            dr["缩量"] = volumeReduce;
            dr["现高"] = highest;
            dr["F3"] = f3;
            dr["F5"] = f5;
            dr["前低"] = lowest;
            dr["幅度"] = Math.Round(100 * (highest - lowest) / lowest, 2).ToString() + "%";
            dr["3线"] = line3Price;
            dr["现价"] = currentPrice;
            dr["距F3"] = f3Distance;
            dr["买入"] = buyPrice;
            dr["KDJ日"] = stock.kdjDays(currentIndex);
            dr["MACD日"] = stock.macdDays(currentIndex);
            dr["价差"] = diff;
            //dr["今涨"] = (stock.kLineDay[currentIndex].endPrice - stock.kLineDay[currentIndex - 1].endPrice) / stock.kLineDay[currentIndex - 1].endPrice;
            dr["今涨"] = 0;
            double maxPrice = Math.Max(highest, stock.kLineDay[currentIndex].highestPrice);
            bool lowThanF5 = false;
            bool lowThanF3 = false;
            bool haveLimitUp = false;
            double computeMaxPrice = 0;
            for (int i = 1; i <= 5; i++)
            {

                if (currentIndex + i >= stock.kLineDay.Length)
                    break;

                double highPrice = stock.kLineDay[currentIndex + i].highestPrice;
                if (i >= 1)
                {
                    computeMaxPrice = Math.Max(computeMaxPrice, highPrice);
                }
                dr[i.ToString() + "日"] = (highPrice - buyPrice) / buyPrice;


                if (i == 1)
                {
                    if ((stock.kLineDay[currentIndex + 1].startPrice - stock.kLineDay[currentIndex].endPrice) / stock.kLineDay[currentIndex].endPrice < 0.095
                        && stock.kLineDay[currentIndex + 1].startPrice > stock.kLineDay[currentIndex].endPrice)
                    {
                        dr["信号"] = dr["信号"].ToString() + "<a title=\"高开未涨停\" >🌟</a>";
                    }
                    dr["今涨"] = (stock.kLineDay[currentIndex+1].startPrice - stock.kLineDay[currentIndex].endPrice) / stock.kLineDay[currentIndex].endPrice;
                }




                if (stock.kLineDay[currentIndex + i].startPrice > maxPrice && !stock.IsLimitUp(currentIndex) && !haveLimitUp)
                {
                    dr["信号"] = dr["信号"].ToString() + "<a title=\"次5日高开过前高\" >🔺</a>";
                }

                if (stock.IsLimitUp(currentIndex + i))
                {
                    haveLimitUp = true;
                }
                maxPrice = Math.Max(maxPrice, highPrice);
                f3 = maxPrice - (maxPrice - lowest) * 0.382;
                f5 = maxPrice - (maxPrice - lowest) * 0.618;
                if (stock.kLineDay[currentIndex + i].lowestPrice < f3 && !lowThanF3)
                {
                    dr["信号"] = dr["信号"].ToString() + "🟢";
                    lowThanF3 = true;
                }
                if (stock.kLineDay[currentIndex + i].lowestPrice < f5 && !lowThanF5)
                {
                    dr["信号"] = dr["信号"].ToString() + "🟢";
                    lowThanF5 = true;
                }

            }



            if (dtGragonTigerList.Select(" gid = '" + stock.gid.Trim() + "' ").Length > 0)
            {
                if (dtGragonTigerList.Select(" gid = '" + stock.gid.Trim() + "' and alert_date = '" + currentDate.ToShortDateString() + "' ").Length > 0)
                {
                    dr["信号"] = dr["信号"].ToString() + "<a title=\"昨日龙虎榜\" >🐲🐯</a>";
                }
                else
                {
                    dr["信号"] = dr["信号"].ToString() + "<a title=\"龙虎榜\" >🐲</a>";
                }

            }

            if (stock.kLineDay[currentIndex].volume / stock.TotalStockCount(currentDate) <= 0.1)
            {
                dr["信号"] = dr["信号"].ToString() + "<a title=\"换手小于10%\" >📈</a>";
            }

            if (dmpReverse)
            {
                dr["信号"] = "DMP" + dr["信号"].ToString().Trim();
            }
            if (line3Reverse)
            {
                dr["信号"] = "3线" + dr["信号"].ToString().Trim();
            }
            if (dtFoot.Select(" gid = '" + stock.gid.Trim() + "' ").Length > 0)
            {
                dr["信号"] = dr["信号"].ToString() + "🦶";
            }
            dr["总计"] = (computeMaxPrice - buyPrice) / buyPrice;
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
                    <asp:BoundColumn DataField="信号" HeaderText="信号" ></asp:BoundColumn>
					<asp:BoundColumn DataField="MACD日" HeaderText="MACD日" SortExpression="MACD日|asc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="KDJ日" HeaderText="KDJ日" SortExpression="KDJ率|asc"></asp:BoundColumn>
                    <asp:BoundColumn DataField="板数" HeaderText="板数" ></asp:BoundColumn>
                    <asp:BoundColumn DataField="3线" HeaderText="3线"></asp:BoundColumn>
                    <asp:BoundColumn DataField="现高" HeaderText="现高"></asp:BoundColumn>
                    <asp:BoundColumn DataField="F3" HeaderText="F3"></asp:BoundColumn>
                    <asp:BoundColumn DataField="F5" HeaderText="F5"></asp:BoundColumn>
                    <asp:BoundColumn DataField="前低" HeaderText="前低"></asp:BoundColumn>
                    <asp:BoundColumn DataField="幅度" HeaderText="幅度"></asp:BoundColumn>
                    <asp:BoundColumn DataField="现价" HeaderText="现价"></asp:BoundColumn>
                    <asp:BoundColumn DataField="价差" HeaderText="价差"></asp:BoundColumn>
                    <asp:BoundColumn DataField="距F3" HeaderText="距F3"></asp:BoundColumn>
                    <asp:BoundColumn DataField="买入" HeaderText="买入"  ></asp:BoundColumn>
                    <asp:BoundColumn DataField="1日" HeaderText="1日" SortExpression="1日|desc" ></asp:BoundColumn>
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
        </table>
    </div>
    </form>
</body>
</html>
