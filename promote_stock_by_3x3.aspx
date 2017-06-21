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
            DataTable dt = GetData1();
            AddTotal(dt);
            dg.DataSource = dt;
            dg.DataBind();
        }

    }

    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {
        dg.DataSource = GetData1();
        dg.DataBind();
    }

    public DataTable GetData1()
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

        DataTable dt = new DataTable();
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("今开");
        dt.Columns.Add("跳空幅度");
        dt.Columns.Add("今日最高");
        dt.Columns.Add("1日最高");
        dt.Columns.Add("2日最高");
        dt.Columns.Add("3日最高");
        dt.Columns.Add("4日最高");
        dt.Columns.Add("5日最高");
        /*
        int total = 0;
        int red0 = 0;
        int red1 = 0;
        int red2 = 0;
        int red3 = 0;
        int red4 = 0;
        int red5 = 0;
        */
        foreach (DataRow drOri in dtOri.Rows)
        {
            //total++;
            DataRow dr = dt.NewRow();
            dr["代码"] = "<a href=\"show_k_line_day.aspx?gid=" + drOri["gid"].ToString().Trim() + "&name="
                + Server.UrlEncode(drOri["name"].ToString().Trim()) + "\" target=\"_blank\" >"
                +  drOri["gid"].ToString().Trim().Remove(0, 2) + "</a>";
            dr["名称"] = drOri["name"].ToString().Trim()
                + (drOri["double_cross_3_3"].ToString().Trim().Equals("1")? "<a title=\"20交易日内两次穿越3线\" >🐂</a>" : "")
                + (double.Parse(drOri["last_day_over_flow"].ToString().Trim()) >= 0.05 ? "<a title=\"昨日收阳，涨幅："
                + Math.Round(double.Parse(drOri["last_day_over_flow"].ToString().Trim()) * 100, 2).ToString() + "%\" >🔥</a>" :"");
            dr["今开"] = drOri["open"].ToString().Trim();
            double rate = 0;
            rate = Math.Round(((double.Parse(drOri["open"].ToString().Trim()) - double.Parse(drOri["settlement"].ToString().Trim()))
                / double.Parse(drOri["settlement"].ToString().Trim())) * 100, 2);

            if (rate == -100)
            {
                dr["跳空幅度"] = "-";
            }
            else
            {
                dr["跳空幅度"] =  "<font color=\"" + (rate >=1.5? "red": (rate < 0.75? "green" : "black")) + "\" >"
                + rate.ToString() + "%</font>";

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
            rate = Math.Round(((highestPrice - double.Parse(drOri["open"].ToString().Trim()))
                / double.Parse(drOri["open"].ToString().Trim())) * 100, 2);
            dr["今日最高"] = "<font color=\"" + (rate >=1? "red": (rate < 0? "green" : "black")) + "\" >" + rate.ToString() + "%</font>";

            if (drOri["highest_1_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(drOri["gid"].ToString().Trim(), currentDate, 1);
            }
            else
            {
                highestPrice = double.Parse(drOri["highest_1_day"].ToString().Trim());
            }
            rate = Math.Round(((highestPrice - double.Parse(drOri["open"].ToString().Trim()))
                / double.Parse(drOri["open"].ToString().Trim())) * 100, 2);
            if (rate == -100)
            {
                dr["1日最高"] = "-";
            }
            else
            {
                dr["1日最高"] =  "<font color=\"" + (rate >=1? "red": (rate < 0? "green" : "black")) + "\" >"
                + rate.ToString() + "%</font>";

            }
            if (drOri["highest_2_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(drOri["gid"].ToString().Trim(), currentDate, 2);
            }
            else
            {
                highestPrice = double.Parse(drOri["highest_2_day"].ToString().Trim());
            }
            rate = Math.Round(((highestPrice - double.Parse(drOri["open"].ToString().Trim()))
                / double.Parse(drOri["open"].ToString().Trim())) * 100, 2);
            if (rate == -100)
            {
                dr["2日最高"] = "-";
            }
            else
            {
                dr["2日最高"] =  "<font color=\"" + (rate >=1? "red": (rate < 0? "green" : "black")) + "\" >"
                + rate.ToString() + "%</font>";

            }
            if (drOri["highest_3_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(drOri["gid"].ToString().Trim(), currentDate, 3);
            }
            else
            {
                highestPrice = double.Parse(drOri["highest_3_day"].ToString().Trim());
            }
            rate = Math.Round(((highestPrice - double.Parse(drOri["open"].ToString().Trim()))
                / double.Parse(drOri["open"].ToString().Trim())) * 100, 2);
            if (rate == -100)
            {
                dr["3日最高"] = "-";
            }
            else
            {
                dr["3日最高"] =  "<font color=\"" + (rate >=1? "red": (rate < 0? "green" : "black")) + "\" >"
                + rate.ToString() + "%</font>";

            }
            if (drOri["highest_4_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(drOri["gid"].ToString().Trim(), currentDate, 4);
            }
            else
            {
                highestPrice = double.Parse(drOri["highest_4_day"].ToString().Trim());
            }
            rate = Math.Round(((highestPrice - double.Parse(drOri["open"].ToString().Trim()))
                / double.Parse(drOri["open"].ToString().Trim())) * 100, 2);
            if (rate == -100)
            {
                dr["4日最高"] = "-";
            }
            else
            {
                dr["4日最高"] =  "<font color=\"" + (rate >=1? "red": (rate < 0? "green" : "black")) + "\" >"
                + rate.ToString() + "%</font>";

            }
            if (drOri["highest_5_day"].ToString().Equals("0"))
            {
                highestPrice = GetNextNDayHighest(drOri["gid"].ToString().Trim(), currentDate, 5);
            }
            else
            {
                highestPrice = double.Parse(drOri["highest_5_day"].ToString().Trim());
            }
            rate = Math.Round(((highestPrice - double.Parse(drOri["open"].ToString().Trim()))
                / double.Parse(drOri["open"].ToString().Trim())) * 100, 2);
            if (rate == -100)
            {
                dr["5日最高"] = "-";
            }
            else
            {
                dr["5日最高"] =  "<font color=\"" + (rate >=1? "red": (rate < 0? "green" : "black")) + "\" >"
                + rate.ToString() + "%</font>";

            }

            dt.Rows.Add(dr);
        }
        /*
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
        dt.Rows.Add(drTotal);
        */
        return dt;
    }


    public static void AddTotal(DataTable dt)
    {
        int red0 = 0;
        int red1 = 0;
        int red2 = 0;
        int red3 = 0;
        int red4 = 0;
        int red5 = 0;
        int total = dt.Rows.Count;
        foreach (DataRow dr in dt.Rows)
        {
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
        dt.Rows.Add(drTotal);
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

        DataTable dt = GetData1();
        DataTable dtSort = dt.Clone();
        dtSort.Columns.Add("跳空幅度double", Type.GetType("System.Double"));
        dtSort.Columns.Add("今日最高double", Type.GetType("System.Double"));
        dtSort.Columns.Add("1日最高double", Type.GetType("System.Double"));
        dtSort.Columns.Add("2日最高double", Type.GetType("System.Double"));
        dtSort.Columns.Add("3日最高double", Type.GetType("System.Double"));
        dtSort.Columns.Add("4日最高double", Type.GetType("System.Double"));
        dtSort.Columns.Add("5日最高double", Type.GetType("System.Double"));
        for (int i = 0; i < dt.Rows.Count; i++)
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
            drSort["3日最高double"] = GetPercentValue(drSort["3日最高"].ToString());//double.Parse(drSort["3日最高"].ToString().Replace("%", ""));
            drSort["4日最高double"] = GetPercentValue(drSort["4日最高"].ToString());//double.Parse(drSort["4日最高"].ToString().Replace("%", ""));
            drSort["5日最高double"] = GetPercentValue(drSort["5日最高"].ToString());//double.Parse(drSort["5日最高"].ToString().Replace("%", ""));
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
        AddTotal(dtNew);
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
        Match m = Regex.Match(str, @">-*\d+.*\d*%<");
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
                        <asp:BoundColumn DataField="今开" HeaderText="今开"></asp:BoundColumn>
                        <asp:BoundColumn DataField="跳空幅度" HeaderText="跳空幅度" SortExpression="跳空幅度|A-Z"></asp:BoundColumn>
                        <asp:BoundColumn DataField="今日最高" HeaderText="今日最高" SortExpression="今日最高|A-Z"></asp:BoundColumn>
                        <asp:BoundColumn DataField="1日最高" HeaderText="1日最高" SortExpression="1日最高|A-Z"></asp:BoundColumn>
                        <asp:BoundColumn DataField="2日最高" HeaderText="2日最高" SortExpression="2日最高|A-Z"></asp:BoundColumn>
                        <asp:BoundColumn DataField="3日最高" HeaderText="3日最高" SortExpression="3日最高|A-Z"></asp:BoundColumn>
                        <asp:BoundColumn DataField="4日最高" HeaderText="4日最高" SortExpression="4日最高|A-Z"></asp:BoundColumn>
                        <asp:BoundColumn DataField="5日最高" HeaderText="5日最高" SortExpression="5日最高|A-Z"></asp:BoundColumn>
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
