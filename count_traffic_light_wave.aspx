<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    

    public int sucCount = 0;
    public int supplementCount = 0;
    public int supplementFair = 0;
    public int supplementSuc = 0;
    public int totalCount = 0;

    protected void Page_Load(object sender, EventArgs e)
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("买入");
        dt.Columns.Add("需补仓");
        dt.Columns.Add("补仓日");
        dt.Columns.Add("补仓价");

        dt.Columns.Add("总盈亏");


        string baseModel = Util.GetSafeRequestValue(Request, "basemodel", "limit_up_volume_reduce_new_high");

        DataTable dtOri = DBHelper.GetDataTable(" select * from alert_traffic_light_base_signal where base_page = '"
            + baseModel + "' and alert_date < '" + Util.GetLastTransactDate(DateTime.Now, 10).ToShortDateString() + "'  order by alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {
            try
            {
                Stock s = GetStock(drOri["gid"].ToString().Trim());
                int currentIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
                if (currentIndex <= 10)
                {
                    continue;
                }

                bool needContinue = false;

                switch (baseModel)
                {
                    case "limit_up_volume_reduce_new_high":
                        if (!s.IsLimitUp(currentIndex - 2))
                        {
                            needContinue = true;
                        }
                        if (s.kLineDay[currentIndex - 1].endPrice >= s.kLineDay[currentIndex - 1].startPrice)
                        {
                            needContinue = true;
                        }
                        if (s.kLineDay[currentIndex].endPrice <= s.kLineDay[currentIndex].startPrice)
                        {
                            needContinue = true;
                        }
                        break;
                    default:
                        break;
                }

                if (needContinue)
                {
                    continue;
                }

                int buyIndex = currentIndex;
                bool suc = false;
                int supplementIndex = 0;
                double supplementPrice = 0;
                double finalMargin = 0;
                double buyPrice = s.kLineDay[currentIndex].endPrice;
                if (dt.Select(" 日期 = '" + s.kLineDay[buyIndex].startDateTime.Date.ToShortDateString() + "' and 代码 = '" + s.gid.Trim() + "' ").Length == 0)
                {
                    double maxHighPriceFirst = 0;
                    for (int i = 1; i <= 5; i++)
                    {
                        maxHighPriceFirst = Math.Max(maxHighPriceFirst, s.kLineDay[currentIndex + i].highestPrice);
                    }
                    finalMargin = (maxHighPriceFirst - buyPrice) / buyPrice;
                    if (finalMargin >= 0.05)
                    {
                        suc = true;
                        sucCount++;
                    }
                    if (!suc)
                    {
                        for (int i = 1; i <= 20; i++)
                        {
                            if (currentIndex + i < s.kLineDay.Length && s.kLineDay[currentIndex + i - 1].endPrice < s.GetAverageSettlePrice(currentIndex + i - 1, 3, 3)
                                && s.kLineDay[currentIndex + i].endPrice > s.GetAverageSettlePrice(currentIndex + i, 3, 3))
                            {
                                supplementIndex = currentIndex + i;
                                break;
                            }
                        }
                        if (supplementIndex > 0)
                        {
                            supplementCount++;
                            supplementPrice = s.kLineDay[supplementIndex].endPrice;
                            double maxHighPriceSupplement = 0;
                            for (int i = 1; i <= 5; i++)
                            {
                                if (supplementIndex + i < s.kLineDay.Length)
                                {
                                    maxHighPriceSupplement = Math.Max(maxHighPriceSupplement, s.kLineDay[supplementIndex + i].highestPrice);
                                }
                            }
                            double supplementCost = (buyPrice + supplementPrice) / 2;
                            finalMargin = (maxHighPriceSupplement - supplementCost) / supplementCost;
                            if (finalMargin > 0)
                            {
                                supplementFair++;
                                if (finalMargin > 0.05)
                                {
                                    supplementSuc++;
                                }
                            }
                        }
                    }

                    DataRow dr = dt.NewRow();
                    dr["日期"] = s.kLineDay[currentIndex].endDateTime.ToShortDateString();
                    dr["代码"] = s.gid.Trim();
                    dr["名称"] = s.Name.Trim();
                    dr["买入"] = buyPrice;
                    dr["需补仓"] = (suc ? "否" : "是");
                    dr["补仓日"] = (supplementIndex == 0) ? "--" : s.kLineDay[supplementIndex].endDateTime.ToShortDateString();
                    dr["补仓价"] = (supplementIndex == 0) ? "--" : s.kLineDay[supplementIndex].endPrice.ToString();
                    dr["总盈亏"] = Math.Round(100 * finalMargin, 2).ToString() + "%";
                    totalCount++;
                    dt.Rows.Add(dr);
                }
            }
            catch
            {

            }
        }

        dg.DataSource = dt;
        dg.DataBind();

    }



    public Stock GetStock(string gid)
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
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">

    <div>5日内涨幅过5%概率：<%= Math.Round(100*(double)sucCount/(double)totalCount, 2).ToString() %>%</div>
    <div>20日内补仓机会：<%= Math.Round(100*(double)supplementCount/(double)(totalCount-sucCount), 2).ToString() %>%</div>
    <div>补仓平进平出：<%= Math.Round(100*(double)supplementFair/(double)supplementCount, 2).ToString() %>%</div>
    <div>补仓盈利：<%= Math.Round(100*(double)supplementSuc/(double)supplementCount, 2).ToString() %>%</div>
    <div>
        <asp:DataGrid runat="server" Width="100%" ID="dg" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
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
