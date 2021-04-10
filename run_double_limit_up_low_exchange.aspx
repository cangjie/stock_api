<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>

<!DOCTYPE html>

<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    public static ArrayList gidArr = new ArrayList();

    public static int suc = 0;



    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            int[] exchangeArr = new int[] { 0, 0, 0, 0, 0 };

            DataTable dtOri = GetData();
            int successCount = 0;
            DataTable dt = new DataTable();
            dt.Columns.Add("日期");
            dt.Columns.Add("代码");
            dt.Columns.Add("名称");
            dt.Columns.Add("换手");
            dt.Columns.Add("1日");
            dt.Columns.Add("2日");
            dt.Columns.Add("3日");
            dt.Columns.Add("4日");
            dt.Columns.Add("5日");
            dt.Columns.Add("总计");

            foreach (DataRow drOri in dtOri.Rows)
            {
                try
                {
                    if (((double)drOri["总计"]) > 0.05)
                    {
                        successCount++;
                    }
                    DataRow dr = dt.NewRow();
                    dr["日期"] = drOri["日期"].ToString();
                    dr["代码"] = drOri["代码"].ToString();
                    dr["名称"] = drOri["名称"].ToString();
                    dr["换手"] = drOri["换手"].ToString();
                    int exchangeBand = int.Parse(drOri["换手"].ToString()) / 10;
                    if (exchangeBand > 4)
                    {
                        exchangeBand = 4;
                    }
                    exchangeArr[exchangeBand]++;
                    double v = 0;
                    for (int i = 1; i <= 5; i++)
                    {
                        v = (double)drOri[i.ToString() + "日"];
                        dr[i.ToString() + "日"] = "<font color='" + ((v > 0.01) ? "red" : "green") + "' >" + Math.Round(v * 100, 2).ToString() + "%</font>";
                    }
                    v = (double)drOri["总计"];
                    dr["总计"] = "<font color='" + ((v > 0.01) ? "red" : "green") + "' >" + Math.Round(v * 100, 2).ToString() + "%</font>";
                    dt.Rows.Add(dr);
                }
                catch
                {

                }
            }
            LblCount.Text = Math.Round(100 * (double)successCount / (double)(dt.Rows.Count), 2).ToString() + "  ";
            LblCount.Text = LblCount.Text + Math.Round(100 * (double)suc / (double)(dt.Rows.Count), 2).ToString();
            for (int i = 0; i < exchangeArr.Length; i++)
            {
                LblCount.Text = LblCount.Text + " " + Math.Round(100 * (double)exchangeArr[i] / (double)dt.Rows.Count, 2).ToString();
            }
            dg.DataSource = dt;
            dg.DataBind();
        }
    }

    public DataTable GetData()
    {
        suc = 0;
        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("换手");
        dt.Columns.Add("1日", Type.GetType("System.Double"));
        dt.Columns.Add("2日", Type.GetType("System.Double"));
        dt.Columns.Add("3日", Type.GetType("System.Double"));
        dt.Columns.Add("4日", Type.GetType("System.Double"));
        dt.Columns.Add("5日", Type.GetType("System.Double"));
        dt.Columns.Add("总计", Type.GetType("System.Double"));

        DataTable dtLimitUp = DBHelper.GetDataTable(" select * from limit_up where alert_date <= '"
            + Util.GetLastTransactDate(DateTime.Now.Date, 10) + "'  order by alert_date desc ");
        foreach (DataRow drLimitUp in dtLimitUp.Rows)
        {
            Stock s = GetStock(drLimitUp["gid"].ToString().Trim());
            DateTime limitUpDate = DateTime.Parse(drLimitUp["alert_date"].ToString());
            int limitUpIndex = s.GetItemIndex(limitUpDate);

            if (limitUpIndex >= s.kLineDay.Length - 6 || limitUpIndex < 5)
            {
                continue;
            }

            int limitUpContinuousTimes = 1;
            for (int i = limitUpIndex - 1; limitUpContinuousTimes < 5 && SearchLimitUp(s.kLineDay, i); i--)
            {
                limitUpContinuousTimes++;
            }
            if (limitUpContinuousTimes < 2 )
            {
                continue;
            }
            if (SearchLimitUp(s.kLineDay, limitUpIndex + 1))
            {
                continue;
            }
            if (!SearchLimitUp(s.kLineDay, limitUpIndex + 2))
            {
                //continue;
            }

            double exchangeRate = (double)s.kLineDay[limitUpIndex + 1].volume / (double)s.TotalStockCount(s.kLineDay[limitUpIndex + 1].endDateTime.Date);
            if ( exchangeRate > 0.2)
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

            double buyPrice = s.kLineDay[limitUpIndex + 1].endPrice;

            double newHighestPrice = 0;
            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[limitUpIndex + 1].startDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["换手"] = Math.Round(100 * exchangeRate, 0);
            if (dt.Select(" 日期 = '" + dr["日期"].ToString().Trim() + "' and 代码 = '" + dr["代码"].ToString().Trim() + "' ").Length > 0)
            {
                continue;
            }


            dr["名称"] = s.Name.Trim();

            dr["1日"] = (s.kLineDay[limitUpIndex + 2].highestPrice - buyPrice) / buyPrice;
            newHighestPrice = Math.Max(newHighestPrice, s.kLineDay[limitUpIndex + 2].highestPrice);
            dr["2日"] = (s.kLineDay[limitUpIndex + 3].highestPrice - buyPrice) / buyPrice;
            newHighestPrice = Math.Max(newHighestPrice, s.kLineDay[limitUpIndex + 3].highestPrice);
            dr["3日"] = (s.kLineDay[limitUpIndex + 4].highestPrice - buyPrice) / buyPrice;
            newHighestPrice = Math.Max(newHighestPrice, s.kLineDay[limitUpIndex + 4].highestPrice);
            dr["4日"] = (s.kLineDay[limitUpIndex + 5].highestPrice - buyPrice) / buyPrice;
            newHighestPrice = Math.Max(newHighestPrice, s.kLineDay[limitUpIndex + 5].highestPrice);
            dr["5日"] = (s.kLineDay[limitUpIndex + 6].highestPrice - buyPrice) / buyPrice;
            newHighestPrice = Math.Max(newHighestPrice, s.kLineDay[limitUpIndex + 6].highestPrice);
            dr["总计"] = (newHighestPrice - buyPrice) / buyPrice;
            dt.Rows.Add(dr);

            for (int i = 1; i <= 5; i++)
            {
                if (SearchLimitUp(s.kLineDay, limitUpIndex + 1 + i))
                {
                    suc++;
                    break;
                }
            }

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
