<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            DataTable dt = GetData();
            dg.DataSource = dt;
            dg.DataBind();
            dgShake.DataSource = GetShakeRateMidLevelTable(dt);
            dgShake.DataBind();
        }
    }

    public DataTable GetShakeRateMidLevelTable(DataTable dtOri)
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("振幅");
        dt.Columns.Add("天数");
        for (int i = 0; i < 10; i++)
        {
            DataRow dr = dt.NewRow();
            dr["振幅"] = i.ToString();
            dr["天数"] = 0;
            dt.Rows.Add(dr);
        }

        foreach (DataRow drOri in dtOri.Rows)
        {
            try
            {
                int num = int.Parse(dt.Rows[int.Parse(drOri["振幅"].ToString())]["天数"].ToString());
                dt.Rows[int.Parse(drOri["振幅"].ToString())]["天数"] = num + 1;
            }
            catch
            {

            }
        }
        return dt;
    }

    public DataTable GetData()
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("开盘价");
        dt.Columns.Add("开盘涨幅");
        dt.Columns.Add("收盘涨幅");
        dt.Columns.Add("最高涨幅");
        dt.Columns.Add("最低涨幅");
        dt.Columns.Add("振幅");

        Stock s = new Stock(Util.GetSafeRequestValue(Request, "gid", "sh601111"));
        s.kArr = KLine.GetKLine("day", s.gid, DateTime.Parse(Util.GetSafeRequestValue(Request, "start", "2017-1-1")),
            DateTime.Parse(DateTime.Now.ToShortDateString()));
        s.ComputeIncreasement();

        //double totalShake = 0;

        for (int i = 1; i < s.kArr.Length; i++)
        {
            DataRow dr = dt.NewRow();
            dr["日期"] = s.kArr[i].startDateTime.ToShortDateString();
            dr["开盘价"] = s.kArr[i].startPrice.ToString();
            dr["开盘涨幅"] = Math.Round(s.kArr[i].increaseRateOpen*100, 2).ToString();
            dr["收盘涨幅"] = Math.Round(s.kArr[i].increaseRateSettle*100, 2).ToString();
            dr["最高涨幅"] = Math.Round(s.kArr[i].increaseRateHighest*100, 2).ToString();
            dr["最低涨幅"] = Math.Round(s.kArr[i].increaseRateLowest*100, 2).ToString();
            dr["振幅"] = Math.Round(s.kArr[i].increaseRateShake*100, 0).ToString();
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
        <asp:DataGrid ID="dg" runat="server" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
            <AlternatingItemStyle BackColor="#DCDCDC" />
            <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
            <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
            <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
            <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
            <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
        </asp:DataGrid>
        <asp:DataGrid ID="dgShake" runat="server" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
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
