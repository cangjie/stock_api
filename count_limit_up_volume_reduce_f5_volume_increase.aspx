<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public int suc = 0;
    public int newHighSuc = 0;
    public int count = 0;
    public int newHighCount = 0;

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            dg.DataSource = GetData();
            dg.DataBind();
        }
    }

    public DataTable GetData()
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");

        dt.Columns.Add("买入");
        dt.Columns.Add("1日");
        dt.Columns.Add("2日");
        dt.Columns.Add("3日");
        dt.Columns.Add("4日");
        dt.Columns.Add("5日");
        dt.Columns.Add("总计");
        DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up_volume_reduce where alert_date >= '2019-12-1' and gid = 'sz300265'  order by alert_date desc " );
        foreach (DataRow drOri in dtOri.Rows)
        {


            Stock s = GetStock(drOri["gid"].ToString().Trim());
            int alertIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (alertIndex + 10 >= s.kLineDay.Length)
            {
                continue;
            }
            if (alertIndex <= 1)
            {
                continue;
            }

            if (s.kLineDay[alertIndex].volume >= s.kLineDay[alertIndex - 1].volume * 1.1)
            {
                continue;
            }
            double highPrice = Math.Max(s.kLineDay[alertIndex].highestPrice, s.kLineDay[alertIndex].highestPrice);
            int lowIndex = 0;
            double lowPrice = GetFirstLowestPrice(s.kLineDay, alertIndex, out lowIndex);
            if (lowIndex == 0)
            {
                continue;
            }
            double f3 = highPrice - (highPrice - lowPrice) * 0.382;
            double f5 = highPrice - (highPrice - lowPrice) * 0.618;
            int f5Index = 0;
            for (int i = alertIndex; i <= alertIndex + 5 && i < s.kLineDay.Length ; i++)
            {
                if (s.kLineDay[i].lowestPrice < f5)
                {
                    f5Index = i;
                    break;
                }
            }
            if (f5Index == 0)
            {
                continue;
            }
            int buyIndex = 0;

            for (int i = f5Index; i <= f5Index + 5 && i < s.kLineDay.Length; i++)
            {
                if (i > f5Index && s.kLineDay[i].endPrice <= f5)
                {
                    break;
                }
                if (s.kLineDay[i].endPrice > f5 && s.kLineDay[i].volume > s.kLineDay[i - 1].volume && s.kLineDay[i].endPrice > s.GetAverageSettlePrice(i, 3, 3))
                {
                    buyIndex = i;
                    break;
                }
            }
            if (buyIndex == 0)
            {
                continue;
            }
            if (f5Index - alertIndex > 5)
            {
                continue;
            }
            double buyPrice = s.kLineDay[buyIndex].endPrice;
            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[buyIndex].endDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["买入"] = buyPrice.ToString();

            double finalRate = double.MinValue;
            for (int j = 1; j <= 5; j++)
            {
                double rate = (s.kLineDay[buyIndex + j].highestPrice - buyPrice) / buyPrice;
                finalRate = Math.Max(finalRate, rate);
                if (rate >= 0.01)
                {
                    dr[j.ToString() + "日"] = "<font color=red >" + Math.Round(rate * 100, 2).ToString() + "%</font>";
                }
                else
                {
                    dr[j.ToString() + "日"] = "<font color=green >" + Math.Round(rate * 100, 2).ToString() + "%</font>";
                }
            }
            if (finalRate >= 0.01)
            {
                suc++;
                if (finalRate >= 0.05)
                {
                    newHighSuc++;
                }
                dr["总计"] = "<font color=red >" + Math.Round(finalRate * 100, 2).ToString() + "%</font>";
            }
            else
            {
                dr["总计"] = "<font color=green >" + Math.Round(finalRate * 100, 2).ToString() + "%</font>";
            }
            count++;

            dt.Rows.Add(dr);
        }
        return dt;
    }

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
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
        <div>
            总计：<%=count.ToString() %> / <%=Math.Round((double)100*suc/(double)count, 2).ToString() %>% 5%：<%=newHighCount.ToString() %> / <%=Math.Round((double)100*newHighSuc/(double)count, 2).ToString() %>%
        </div>
        <div>
            <asp:DataGrid runat="server" id="dg" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
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
