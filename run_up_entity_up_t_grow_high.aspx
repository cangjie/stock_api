<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>

<!DOCTYPE html>

<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    public static ArrayList gidArr = new ArrayList();

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            DataTable dtOri = GetData();
            int successCount = 0;
            DataTable dt = new DataTable();
            dt.Columns.Add("日期");
            dt.Columns.Add("代码");
            dt.Columns.Add("名称");
            dt.Columns.Add("1日");
            dt.Columns.Add("2日");
            dt.Columns.Add("3日");
            dt.Columns.Add("4日");
            dt.Columns.Add("5日");
            dt.Columns.Add("总计");

            foreach (DataRow drOri in dtOri.Rows)
            {
                if (((double)drOri["总计"]) > 0.01)
                {
                    successCount++;
                }
                DataRow dr = dt.NewRow();
                dr["日期"] = ((DateTime)drOri["日期"]).ToShortDateString();
                dr["代码"] = drOri["代码"].ToString();
                dr["名称"] = drOri["名称"].ToString();
                double v = 0;
                for (int i = 1; i <= 5; i++)
                {
                    v = (double)drOri[i.ToString() + "日"];
                    dr[i.ToString() + "日"] = "<font color='" + ((v > 0.01)? "red" : "green") + "' >" + Math.Round(v * 100, 2).ToString() + "%</font>";
                }
                v = (double)drOri["总计"];
                dr["总计"] = "<font color='" + ((v > 0.01)? "red" : "green") + "' >" + Math.Round(v * 100, 2).ToString() + "%</font>";
                dt.Rows.Add(dr);
            }
            LblCount.Text = Math.Round(100 * (double)successCount / (double)(dt.Rows.Count), 2).ToString();
            dg.DataSource = dt;
            dg.DataBind();
        }
    }

    public DataTable GetData()
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("1日", Type.GetType("System.Double"));
        dt.Columns.Add("2日", Type.GetType("System.Double"));
        dt.Columns.Add("3日", Type.GetType("System.Double"));
        dt.Columns.Add("4日", Type.GetType("System.Double"));
        dt.Columns.Add("5日", Type.GetType("System.Double"));
        dt.Columns.Add("总计", Type.GetType("System.Double"));

        DataTable dtLimitUp = DBHelper.GetDataTable(" select * from limit_up where alert_date <= '"
            + Util.GetLastTransactDate(DateTime.Now.Date, 8) + "' order by alert_date desc ");
        foreach (DataRow drLimitUp in dtLimitUp.Rows)
        {
            Stock s = GetStock(drLimitUp["gid"].ToString().Trim());
            DateTime limitUpEntityDate = DateTime.Parse(drLimitUp["alert_date"].ToString());
            int limitUpEntityIndex = s.GetItemIndex(limitUpEntityDate);
            if (limitUpEntityIndex < 1)
            {
                continue;
            }
            if (limitUpEntityIndex + 7 >= s.kLineDay.Length)
            {
                continue;
            }
            if (s.kLineDay[limitUpEntityIndex].endPrice != s.kLineDay[limitUpEntityIndex].highestPrice
                || s.kLineDay[limitUpEntityIndex].startPrice == s.kLineDay[limitUpEntityIndex].endPrice
                || ((s.kLineDay[limitUpEntityIndex].endPrice - s.kLineDay[limitUpEntityIndex - 1].endPrice) / s.kLineDay[limitUpEntityIndex - 1].endPrice) < 0.095)
            {
                continue;
            }
            if (s.kLineDay[limitUpEntityIndex + 1].startPrice != s.kLineDay[limitUpEntityIndex + 1].endPrice
                || s.kLineDay[limitUpEntityIndex + 1].endPrice != s.kLineDay[limitUpEntityIndex + 1].highestPrice
                || ((s.kLineDay[limitUpEntityIndex + 1].endPrice - s.kLineDay[limitUpEntityIndex].endPrice) / s.kLineDay[limitUpEntityIndex].endPrice) < 0.095)
            {
                continue;
            }
            if (s.kLineDay[limitUpEntityIndex + 2].startPrice < s.kLineDay[limitUpEntityIndex + 1].endPrice)
            {
                continue;
            }

            double buyPrice = s.kLineDay[limitUpEntityIndex + 2].startPrice;
            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[limitUpEntityIndex + 2].startDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.name.Trim();
            double highestPrice = 0;
            dr["1日"] = (s.kLineDay[limitUpEntityIndex + 3].highestPrice - buyPrice) / buyPrice;
            highestPrice = Math.Max(highestPrice, s.kLineDay[limitUpEntityIndex + 3].highestPrice);
            dr["2日"] = (s.kLineDay[limitUpEntityIndex + 4].highestPrice - buyPrice) / buyPrice;
            highestPrice = Math.Max(highestPrice, s.kLineDay[limitUpEntityIndex + 4].highestPrice);
            dr["3日"] = (s.kLineDay[limitUpEntityIndex + 5].highestPrice - buyPrice) / buyPrice;
            highestPrice = Math.Max(highestPrice, s.kLineDay[limitUpEntityIndex + 5].highestPrice);
            dr["4日"] = (s.kLineDay[limitUpEntityIndex + 6].highestPrice - buyPrice) / buyPrice;
            highestPrice = Math.Max(highestPrice, s.kLineDay[limitUpEntityIndex + 6].highestPrice);
            dr["5日"] = (s.kLineDay[limitUpEntityIndex + 7].highestPrice - buyPrice) / buyPrice;
            highestPrice = Math.Max(highestPrice, s.kLineDay[limitUpEntityIndex + 7].highestPrice);
            dr["总计"] = (highestPrice - buyPrice) / buyPrice;
            dt.Rows.Add(dr);

        }

        return dt;
    }

    public static Stock GetStock(string gid)
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
            s.LoadKLineDay(rc);
            gidArr.Add(s);
        }
        return s;
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <asp:Label runat="server" ID="LblCount" ></asp:Label>
    </div>
    <div>
        <asp:DataGrid ID="dg" runat="server" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
            <AlternatingItemStyle BackColor="#DCDCDC" />
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
