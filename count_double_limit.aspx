<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public int over10PerIn5Days = 0;

    public int openHighLimitUp = 0;

    public int overBuyPriceIn5Days = 0;

    public int count = 0;

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            DataTable dt = GetData();
            dg.DataSource = RendData(dt.Select("", "日期 desc"));
            dg.DataBind();
        }
    }

    public DataTable RendData(DataRow[] drArr)
    {
        DataTable dtNew = new DataTable();
        foreach (DataColumn dc in drArr[0].Table.Columns)
        {
            dtNew.Columns.Add(dc.Caption.Trim());
        }
        foreach (DataRow dr in drArr)
        {
            DataRow drNew = dtNew.NewRow();
            foreach (DataColumn dc in drArr[0].Table.Columns)
            {
                drNew[dc.Caption] = dr[dc].ToString();
            }
            double currentRate = double.Parse(dr["当日"].ToString());
            if (currentRate >= 0.01)
            {
                drNew["当日"] = "<font color='red' >" + Math.Round(100 * currentRate, 2).ToString() + "%</font>";
            }
            else
            {
                drNew["当日"] = "<font color='green' >" + Math.Round(100 * currentRate, 2).ToString() + "%</font>";
            }
            for (int i = 1; i <= 5; i++)
            {
                double rate = double.Parse(dr[i.ToString() + "日"].ToString());
                if (rate >= 0.01)
                {
                    drNew[i.ToString() + "日"] = "<font color='red' >" + Math.Round(100 * rate, 2).ToString() + "%</font>";
                }
                else
                {
                    drNew[i.ToString() + "日"] = "<font color='green' >" + Math.Round(100 * rate, 2).ToString() + "%</font>";
                }
            }
            currentRate = double.Parse(dr["总计"].ToString());
            if (currentRate >= 0.01)
            {
                drNew["总计"] = "<font color='red' >" + Math.Round(100 * currentRate, 2).ToString() + "%</font>";
            }
            else
            {
                drNew["总计"] = "<font color='green' >" + Math.Round(100 * currentRate, 2).ToString() + "%</font>";
            }
            dtNew.Rows.Add(drNew);
        }
        return dtNew;
    }

    public DataTable GetData()
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("买入");
        dt.Columns.Add("当日");
        dt.Columns.Add("1日");
        dt.Columns.Add("2日");
        dt.Columns.Add("3日");
        dt.Columns.Add("4日");
        dt.Columns.Add("5日");
        dt.Columns.Add("总计");

        KeyValuePair<Stock, DateTime>[] gidArr = Util.GetDoubleLimitUpFrom3Line();
        foreach (KeyValuePair<Stock, DateTime> gidPair in gidArr)
        {
            Stock s = gidPair.Key;
            DateTime currentDate = gidPair.Value;
            int currentIndex = s.GetItemIndex(currentDate);
            if (currentIndex < 0)
            {
                continue;
            }
            if (currentIndex > s.kLineDay.Length - 7)
            {
                continue;
            }
            if (s.kLineDay[currentIndex + 1].startPrice <= s.kLineDay[currentIndex].endPrice
                || !s.IsLimitUp(currentIndex) || !s.IsLimitUp(currentIndex - 1))
            {
                continue;
            }
            double buyPrice = s.kLineDay[currentIndex + 1].startPrice;
            DataRow dr = dt.NewRow();
            dr["日期"] = currentDate;
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["买入"] = buyPrice;
            dr["当日"] = (s.kLineDay[currentIndex + 1].endPrice - buyPrice) / buyPrice;
            double maxPrice = 0;
            for (int i = 1; i <= 5; i++)
            {
                maxPrice = Math.Max(s.kLineDay[currentIndex + 1 + i].highestPrice, maxPrice);
                dr[i.ToString() + "日"] = (s.kLineDay[currentIndex + 1 + i].highestPrice - buyPrice) / buyPrice;
            }
            double totalRate = (maxPrice - buyPrice) / buyPrice;
            dr["总计"] = totalRate;
            if (maxPrice > buyPrice)
            {
                overBuyPriceIn5Days++;
            }
            if (s.IsLimitUp(currentIndex + 1))
            {
                openHighLimitUp++;
            }
            if (totalRate >= 0.1)
            {
                over10PerIn5Days++;
            }
            count = dt.Rows.Count;
            dt.Rows.Add(dr);
        }


        return dt;
    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <div>
            总计：<%=count.ToString() %><br />
            5日涨10%以上：<%=over10PerIn5Days.ToString() %> <%=Math.Round(100*(double)over10PerIn5Days/count, 2).ToString() %>%<br />
            当日涨停：<%=openHighLimitUp.ToString() %> <%=Math.Round(100*(double)openHighLimitUp/count, 2).ToString() %>%<br />
            5日不赔：<%=overBuyPriceIn5Days.ToString() %> <%=Math.Round(100*(double)overBuyPriceIn5Days/count, 2).ToString() %>%<br />
        </div>
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
