<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Threading" %>
<!DOCTYPE html>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            calendar.SelectedDate = DateTime.Now;
            dg.DataSource = GetData();
            dg.DataBind();
        }

    }

    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {
        dg.DataSource = GetData();
        dg.DataBind();
    }

    public DataTable GetData()
    {
        DateTime currentDate = DateTime.Parse(calendar.SelectedDate.ToShortDateString());
        DataTable dtOri = DBHelper.GetDataTable(" select * from suggest_stock where suggest_date = '" + currentDate.ToShortDateString() + "'");
        if (dtOri.Rows.Count == 0)
        {
            if (currentDate == DateTime.Parse(DateTime.Now.ToShortDateString()))
            {
                ThreadStart ts = new ThreadStart(Util.RefreshSuggestStockForToday);
                //Util.RefreshSuggestStockForToday();
                Thread t = new Thread(ts);
                t.Start();
            }
            else
            {
                Util.RefreshSuggestStock(currentDate);
            }
            dtOri = DBHelper.GetDataTable(" select * from suggest_stock where suggest_date = '" + currentDate.ToShortDateString() 
                + "'  order by  ((highest_5_day - [open]) / [open]) desc, ((highest_3_day - [open]) / [open]) desc, (([open] - settlement) / settlement) desc ");
        }
        DataTable dt = new DataTable();
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("昨收");
        dt.Columns.Add("昨3线");
        dt.Columns.Add("今开");
        dt.Columns.Add("今3线");
        dt.Columns.Add("今涨幅");
        dt.Columns.Add("3日最高");
        dt.Columns.Add("3日涨幅");
        dt.Columns.Add("5日最高");
        dt.Columns.Add("5日涨幅");


        foreach (DataRow drOri in dtOri.Rows)
        {
            DataRow dr = dt.NewRow();
            dr["代码"] = drOri["gid"].ToString().Trim().Remove(0, 2);
            dr["名称"] = drOri["name"].ToString().Trim();
            dr["昨收"] = drOri["settlement"].ToString().Trim();
            dr["昨3线"] = drOri["avg_3_3_yesterday"].ToString().Trim();
            dr["今开"] = drOri["open"].ToString().Trim();
            dr["今3线"] = drOri["avg_3_3_today"].ToString().Trim();
            dr["今涨幅"] =
                (double.Parse(drOri["open"].ToString().Trim()) - double.Parse(drOri["settlement"].ToString().Trim()))
                / double.Parse(drOri["settlement"].ToString().Trim());
            if (drOri["highest_3_day"].ToString().Trim().Equals("0") && currentDate.AddDays(3) <= DateTime.Now)
            {
                double highest_3_d = Get3DayHighest(drOri["gid"].ToString().Trim(), currentDate);
                if (highest_3_d > 0)
                {
                    //Update3DHighestPrice(drOri["gid"].ToString().Trim(), currentDate, highest_3_d);
                    dr["3日最高"] = highest_3_d.ToString();
                }
                else
                {
                    dr["3日最高"] = "0";
                }
            }
            else
            {
                dr["3日最高"] = drOri["highest_3_day"];
            }
            if (drOri["highest_5_day"].ToString().Trim().Equals("0") && currentDate.AddDays(5) <= DateTime.Now)
            {
                double highest_5_d = Get5DayHighest(drOri["gid"].ToString().Trim(), currentDate);
                if (highest_5_d > 0)
                {
                    //Update3DHighestPrice(drOri["gid"].ToString().Trim(), currentDate, highest_5_d);
                    dr["5日最高"] = highest_5_d.ToString();
                }
                else
                {
                    dr["5日最高"] = "0";
                }
            }
            else
            {
                dr["5日最高"] = drOri["highest_5_day"];
            }
            dr["3日涨幅"] = (double.Parse(dr["3日最高"].ToString()) - double.Parse(dr["今开"].ToString())) / double.Parse(dr["今开"].ToString());
            dr["5日涨幅"] = (double.Parse(dr["5日最高"].ToString()) - double.Parse(dr["今开"].ToString())) / double.Parse(dr["今开"].ToString());
            dt.Rows.Add(dr);
        }

        DataTable dtNew = dt.Clone();

        //DataRow[] drSortArr =  dt.Select("", " 今涨幅 desc ");
        /*
        if (drSortArr.Length > 0)
        {
            if (!drSortArr[0]["5日最高"].ToString().Equals("0"))
                drSortArr =  dt.Select("", " 5日涨幅 desc ");
            if (!drSortArr[0]["3日最高"].ToString().Equals("0"))
                drSortArr =  dt.Select("", " 3日涨幅 desc ");

        }
        */
        foreach (DataRow drSort in dt.Rows)
        {
            DataRow drNew = dtNew.NewRow();
            foreach (DataColumn dc in dtNew.Columns)
            {
                drNew[dc.Caption] = drSort[dc.Caption];
            }
            drNew["今涨幅"] = Math.Round(double.Parse(drNew["今涨幅"].ToString()) * 100, 2).ToString() + "%";
            drNew["3日涨幅"] = Math.Round(double.Parse(drNew["3日涨幅"].ToString()) * 100, 2).ToString() + "%";
            drNew["5日涨幅"] = Math.Round(double.Parse(drNew["5日涨幅"].ToString()) * 100, 2).ToString() + "%";
            drNew["昨3线"] = Math.Round(double.Parse(drNew["昨3线"].ToString()), 3);
            drNew["今3线"] =  Math.Round(double.Parse(drNew["今3线"].ToString()), 3);
            dtNew.Rows.Add(drNew);
        }
        return dtNew;
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
                <td><asp:DataGrid runat="server" id="dg" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
                    <AlternatingItemStyle BackColor="#DCDCDC" />
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
