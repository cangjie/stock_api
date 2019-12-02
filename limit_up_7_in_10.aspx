<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

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
        dt.Columns.Add("板数");

        DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up order by alert_date desc ");

        foreach (DataRow drOri in dtOri.Rows)
        {
            DateTime endLimitUpDate = DateTime.Parse(drOri["alert_date"].ToString()).Date;
            DateTime startLimitUpDate = Util.GetLastTransactDate(endLimitUpDate, 9).Date;
            DataRow[] drOriArr = dtOri.Select(" gid = '" + drOri["gid"].ToString() + "' and alert_date >= '"
                + startLimitUpDate.ToShortDateString() + "' and alert_date <= '" + endLimitUpDate.ToShortDateString() + "' ");
            if (drOriArr.Length >= 7)
            {
                DataRow dr = dt.NewRow();
                dr["日期"] = endLimitUpDate.ToShortDateString();
                dr["代码"] = drOri["gid"].ToString();
                Stock s = new Stock(drOri["gid"].ToString());
                dr["名称"] = s.Name.Trim();
                dr["板数"] = drOriArr.Length.ToString();
                dt.Rows.Add(dr);
            }
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
        <asp:DataGrid ID="dg" runat="server" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" Width="100%"  >
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
