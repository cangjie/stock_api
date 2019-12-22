<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();


    public static int count = 0;

    public static int over1Per = 0;

    public static int over5Per = 0;



    public  Stock GetStock(string gid)
    {
        Stock s = new Stock();
        bool found = false;
        foreach (object o in gidArr)
        {
            if (((Stock)o).gid.Trim().Equals(gid))
            {
                found = true;
                s = (Stock)o;
                break;
            }
        }
        if (!found)
        {
            s = new Stock(gid);
            s.LoadKLineDay(Util.rc);
            gidArr.Add(s);
        }
        return s;
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            DataTable dt = GetData();
            dg.DataSource = RenderHtml(dt.Select("", ""));
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
                            dr[i] = Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2).ToString();
                            break;
                        case "今开":
                        case "现价":
                        case "前低":
                        case "F1":
                        case "F3":
                        case "F5":
                        case "现高":

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
        //AddTotal(drArr, dt);
        return dt;
    }


    public DataTable GetData()
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.String"));
        dt.Columns.Add("信号", Type.GetType("System.String"));
        dt.Columns.Add("代码", Type.GetType("System.String"));
        dt.Columns.Add("名称", Type.GetType("System.String"));
        dt.Columns.Add("买入", Type.GetType("System.Double"));
        for (int i = 1; i <= 5; i++)
        {
            dt.Columns.Add(i.ToString() + "日", Type.GetType("System.Double"));
        }
        dt.Columns.Add("总计", Type.GetType("System.Double"));

        DataTable dtOri = DBHelper.GetDataTable("select  * from limit_up a where exists(select 'a' from limit_up b where a.gid = b.gid and b.alert_date = dbo.func_GetLastTransactDate(a.alert_date, 1)) "
            // + " and gid = 'sz300643' " 
            + " and alert_date <= '" + Util.GetLastTransactDate(DateTime.Now.Date, 7).ToShortDateString() + "' "
            + " order by a.alert_date desc"
            );
        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock stock = GetStock(drOri["gid"].ToString());
            int currentIndex = stock.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));

            if (currentIndex < 1)
            {
                continue;
            }
            if (currentIndex + 8 > stock.kLineDay.Length - 1)
            {
                continue;
            }
            if (!stock.IsLimitUpContinous(currentIndex, 2))
            {
                continue;
            }
            if (!stock.IsLimitUp(currentIndex + 1))
            {
                continue;
            }

            if (stock.kLineDay[currentIndex + 2].startPrice > stock.kLineDay[currentIndex + 1].endPrice)
            {
                continue;
            }
            if (!stock.IsLimitUp(currentIndex + 2))
            {
                continue;
            }
            if (stock.kLineDay[currentIndex + 3].startPrice <= stock.kLineDay[currentIndex + 2].endPrice)
            {
                continue;
            }

            double buyPrice = stock.kLineDay[currentIndex + 3].startPrice;
            double highPrice = stock.kLineDay[currentIndex + 1].highestPrice;
            double lowPrice = stock.kLineDay[currentIndex + 2].lowestPrice;
            double f5 = lowPrice + (highPrice - lowPrice) * 0.618;
            double f3 = lowPrice + (highPrice - lowPrice) * 0.382;
            DataRow dr = dt.NewRow();
            dr["日期"] = stock.kLineDay[currentIndex].startDateTime.ToShortDateString();
            dr["代码"] = stock.gid;
            dr["名称"] = stock.Name.Trim();
            dr["买入"] = buyPrice;
            double maxPrice = 0;
            for (int i = 1; i <= 5; i++)
            {
                maxPrice = Math.Max(maxPrice, stock.kLineDay[currentIndex + 3 + i].highestPrice);
                dr[i.ToString() + "日"] = (stock.kLineDay[currentIndex + 3 + i].highestPrice - buyPrice) / buyPrice;
            }
            double totalRate = (maxPrice - buyPrice) / buyPrice;
            dr["总计"] = totalRate;


            if (stock.kLineDay[currentIndex + 2].startPrice <= stock.kLineDay[currentIndex + 2].endPrice)
            {
                dr["信号"] = "<font color='green' >" + dr["信号"].ToString() + "</font>";
            }
            else
            {
                dr["信号"] = "<font color='red' >" + dr["信号"].ToString() + "</font>";
            }
            dt.Rows.Add(dr);
        }
        count = dt.Rows.Count;
        return dt;
    }

    public string ShowPercent(int num, int count)
    {
        return Math.Round(100 * (double)num / count, 2).ToString() + "%";
    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">

    <div>
        <div>总计：<%=count %></div>
        <div><asp:DataGrid ID="dg" runat="server" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" Width="100%">
            <AlternatingItemStyle BackColor="#DCDCDC" />
            <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
            <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
            <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
            <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
            <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
            </asp:DataGrid></div>
    </div>
    </form>
</body>
</html>
