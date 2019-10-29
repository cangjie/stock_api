<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>

<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    public static Stock[] gidArr;

    public DataTable dt;

    protected void Page_Load(object sender, EventArgs e)
    {
        FillGidArr();
        dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("买入");
        dt.Columns.Add("1日");
        dt.Columns.Add("2日");
        dt.Columns.Add("3日");

        dt.Columns.Add("总计");

        for (DateTime currentDate = DateTime.Now.AddDays(-7); currentDate >= DateTime.Parse("2018-1-1"); currentDate = currentDate.AddDays(-1))
        {
            if (Util.IsTransacDay(currentDate))
            {
                foreach (Stock s in gidArr)
                {
                    int currentIndex = s.GetItemIndex(currentDate);
                    if (currentIndex <= 5)
                    {
                        continue;
                    }
                    if (s.IsLimitUp(currentIndex - 1) && !s.IsLimitUp(currentIndex - 2) && s.IsLimitUp(currentIndex - 3)
                        && s.IsLimitUp(currentIndex - 4) && s.kLineDay[currentIndex].startPrice > s.kLineDay[currentIndex].endPrice)
                    {
                        try
                        {
                            DataRow dr = dt.NewRow();
                            dr["日期"] = currentDate.ToShortDateString();
                            dr["名称"] = s.Name.Trim();
                            dr["代码"] = s.gid.Trim();
                            double buyPrice = s.kLineDay[currentIndex].startPrice;
                            dr["买入"] = Math.Round(buyPrice, 2).ToString();
                            double maxPrice = s.kLineDay[currentIndex + 1].highestPrice;
                            double rate = (s.kLineDay[currentIndex + 1].highestPrice - buyPrice) / buyPrice;
                            dr["1日"] = "<font color=\"" + ((rate > 0.01) ? "red" : "green") + "\" >" + Math.Round(rate * 100, 2).ToString() + "%</a>";
                            maxPrice = Math.Max(maxPrice, s.kLineDay[currentIndex + 2].highestPrice);
                            rate = (s.kLineDay[currentIndex + 2].highestPrice - buyPrice) / buyPrice;
                            dr["2日"] = "<font color=\"" + ((rate > 0.01) ? "red" : "green") + "\" >" + Math.Round(rate * 100, 2).ToString() + "%</a>";
                            maxPrice = Math.Max(maxPrice, s.kLineDay[currentIndex + 3].highestPrice);
                            rate = (s.kLineDay[currentIndex + 3].highestPrice - buyPrice) / buyPrice;
                            dr["3日"] = "<font color=\"" + ((rate > 0.01) ? "red" : "green") + "\" >" + Math.Round(rate * 100, 2).ToString() + "%</a>";
                            dt.Rows.Add(dr);
                        }
                        catch
                        {

                        }
                    }

                }
            }
        }
        dg.DataSource = dt;
        dg.DataBind();

    }

    public static void FillGidArr()
    {
        DataTable dt = DBHelper.GetDataTable(" select distinct gid from limit_up ");
        gidArr = new Stock[dt.Rows.Count];
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            gidArr[i] = new Stock(dt.Rows[i][0].ToString());
            gidArr[i].LoadKLineDay(rc);
        }
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <asp:DataGrid ID="dg" runat="server" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical">
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
