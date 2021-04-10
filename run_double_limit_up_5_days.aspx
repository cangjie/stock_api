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
                if (((double)drOri["总计"]) > 0.05)
                {
                    successCount++;
                }
                DataRow dr = dt.NewRow();
                dr["日期"] = drOri["日期"].ToString();
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
            + Util.GetLastTransactDate(DateTime.Now.Date, 10) + "' order by alert_date desc ");
        foreach (DataRow drLimitUp in dtLimitUp.Rows)
        {
            Stock s = GetStock(drLimitUp["gid"].ToString().Trim());
            DateTime limitUpDate = DateTime.Parse(drLimitUp["alert_date"].ToString());
            int limitUpIndex = s.GetItemIndex(limitUpDate);
            if (!SearchLimitUp(s.kLineDay, limitUpIndex) || !SearchLimitUp(s.kLineDay, limitUpIndex - 1))
            {
                continue;
            }
            int highestIndex = 0;
            double highestPrice = 0;
            for (int i = limitUpIndex; i < s.kLineDay.Length && s.GetAverageSettlePrice(i, 3, 3) < s.kLineDay[i].endPrice ; i++)
            {
                highestPrice = Math.Max(highestPrice, s.kLineDay[i].highestPrice);
                if (highestPrice == s.kLineDay[i].highestPrice)
                {
                    highestIndex = i;
                }
            }

            int lowestPriceIndex = 0;
            double lowestPrice = double.MaxValue;

            for (int i = limitUpIndex; i >= 1; i--)
            {
                if (s.kLineDay[i].endPrice < s.GetAverageSettlePrice(i, 3, 3)
                    && s.kLineDay[i].lowestPrice < s.kLineDay[i - 1].lowestPrice
                    && s.kLineDay[i].lowestPrice < s.kLineDay[i + 1].lowestPrice)
                {
                    lowestPriceIndex = i;
                    lowestPrice = s.kLineDay[i].lowestPrice;
                    break;
                }
            }
            if (lowestPriceIndex == 0)
            {
                continue;
            }
            if ((highestPrice - lowestPrice) / lowestPrice >= 0.8)
            {
                continue;
            }
            if (highestIndex + 6 >= s.kLineDay.Length || highestIndex == 0)
            {
                continue;
            }
            bool foundNewHigh = false;
            for (int i = 1; i <= 5; i++)
            {
                if (s.kLineDay[highestIndex + i].highestPrice >= highestPrice)
                {
                    foundNewHigh = true;
                    break;
                }
            }
            if (foundNewHigh)
            {
                continue;
            }
            double buyPrice = s.kLineDay[highestIndex + 5].endPrice;


            if (highestIndex + 10 >= s.kLineDay.Length)
            {
                continue;
            }
            double newHighestPrice = 0;
            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[highestIndex + 5].startDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();

            if (dt.Select(" 日期 = '" + dr["日期"].ToString().Trim() + "' and 代码 = '" + dr["代码"].ToString().Trim() + "' ").Length > 0)
            {
                continue;
            }


            dr["名称"] = s.Name.Trim();

            dr["1日"] = (s.kLineDay[highestIndex + 6].highestPrice - buyPrice) / buyPrice;
            newHighestPrice = Math.Max(newHighestPrice, s.kLineDay[highestIndex + 6].highestPrice);
            dr["2日"] = (s.kLineDay[highestIndex + 7].highestPrice - buyPrice) / buyPrice;
            newHighestPrice = Math.Max(newHighestPrice, s.kLineDay[highestIndex + 7].highestPrice);
            dr["3日"] = (s.kLineDay[highestIndex + 8].highestPrice - buyPrice) / buyPrice;
            newHighestPrice = Math.Max(newHighestPrice, s.kLineDay[highestIndex + 8].highestPrice);
            dr["4日"] = (s.kLineDay[highestIndex + 9].highestPrice - buyPrice) / buyPrice;
            newHighestPrice = Math.Max(newHighestPrice, s.kLineDay[highestIndex + 9].highestPrice);
            dr["5日"] = (s.kLineDay[highestIndex + 10].highestPrice - buyPrice) / buyPrice;
            newHighestPrice = Math.Max(newHighestPrice, s.kLineDay[highestIndex + 10].highestPrice);
            dr["总计"] = (newHighestPrice - buyPrice) / buyPrice;
            dt.Rows.Add(dr);

        }

        return dt;
    }

    public static bool SearchLimitUp(KLine[] kArr, int currentIndex)
    {
        if (currentIndex <= 0)
        {
            return false;
        }
        if ((kArr[currentIndex].endPrice - kArr[currentIndex-1].endPrice) / kArr[currentIndex-1].endPrice > 0.095
            && kArr[currentIndex].endPrice == kArr[currentIndex].highestPrice)
        {
            return true;
        }
        else
        {
            return false;
        }
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
