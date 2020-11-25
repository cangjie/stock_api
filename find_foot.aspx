<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public DataTable footTable = new DataTable();
    public static Core.RedisClient rc = new Core.RedisClient("52.81.252.140");

    protected void Page_Load(object sender, EventArgs e)
    {
        footTable.Columns.Add("gid");
        footTable.Columns.Add("raise");
        string[] gidArr = Util.GetAllGids();
        foreach (string gid in gidArr)
        {
            Stock stock = new Stock(gid.Trim(), rc);
            stock.LoadKLineDay(rc);
            int currentIndex = stock.GetItemIndex(DateTime.Now.Date);
            Core.Timeline[] timelineArray = Core.Timeline.LoadTimelineArrayFromRedis(stock.gid, DateTime.Now.Date.AddDays(-3), rc);
            double lowestPrice = 0;
            int i = 0;
            foreach (Core.Timeline t in timelineArray)
            {
                if (lowestPrice == 0)
                {
                    lowestPrice = t.todayLowestPrice;
                }
                if (lowestPrice > t.todayLowestPrice)
                {
                    if (t.todayLowestPrice / lowestPrice <= 0.98)
                    {
                        if (t.todayLowestPrice / timelineArray[i + 1].todayEndPrice <= 0.98)
                        {
                            DataRow dr = footTable.NewRow();
                            dr[0] = stock.gid.Trim();
                            double raise = (stock.kLineDay[currentIndex].endPrice - stock.kLineDay[currentIndex - 1].endPrice) / stock.kLineDay[currentIndex - 1].endPrice;
                            dr[1] = "<font color='" + ((raise < 0.01) ? "green" : "red") + "' >" + Math.Round(raise * 100, 2).ToString() + "%</font>";
                            footTable.Rows.Add(dr);
                            break;
                        }
                    }
                    lowestPrice = t.todayLowestPrice;
                }
                i++;
            }
        }
        dg.DataSource = footTable;
        dg.DataBind();
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <asp:DataGrid runat="server" ID="dg" BackColor="White" Width="100%" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
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
