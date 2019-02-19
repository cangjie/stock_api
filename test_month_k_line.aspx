<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    protected void Page_Load(object sender, EventArgs e)
    {
        
        KLine[] klineMonth = Stock.LoadWeekKLine(Util.GetSafeRequestValue(Request, "gid", "sh600031"), rc);

        DataTable dt = new DataTable();
        dt.Columns.Add("month");
        dt.Columns.Add("open");
        dt.Columns.Add("highest");
        dt.Columns.Add("lowest");
        dt.Columns.Add("close");
        foreach (KLine k in klineMonth)
        {
            DataRow dr = dt.NewRow();
            dr["month"] = k.startDateTime.Year.ToString() + "-" + k.startDateTime.Month.ToString();
            dr["open"] = Math.Round(k.startPrice, 2).ToString();
            dr["highest"] = Math.Round(k.highestPrice, 2).ToString();
            dr["lowest"] = Math.Round(k.lowestPrice, 2).ToString();
            dr["close"] = Math.Round(k.endPrice, 2).ToString();
            dt.Rows.Add(dr);
        }
        dg.DataSource = dt;
        dg.DataBind();
        
        //Response.Write(Core.Util.GetWeekNumber(DateTime.Parse("2019-1-18")));
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
        <div>
            <asp:DataGrid Width="100%" runat="server" ID="dg" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical">
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
