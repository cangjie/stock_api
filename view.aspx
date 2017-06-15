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
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("昨收");
        dt.Columns.Add("昨3线");
        dt.Columns.Add("今开");
        dt.Columns.Add("今3线");
        dt.Columns.Add("涨幅");

        DataTable dtOri = DBHelper.GetDataTable(" select * from suggest_stock where suggest_date = '" + Util.GetSafeRequestValue(Request, "date", DateTime.Now.ToShortDateString()) + "'  ");
        foreach (DataRow drOri in dtOri.Rows)
        {
            DataRow dr = dt.NewRow();
            dr["代码"] = drOri["gid"].ToString().Remove(0, 2);
            dr["名称"] = drOri["name"].ToString().Trim();
            dr["昨收"] = drOri["settlement"].ToString().Trim();
            dr["昨3线"] = drOri["avg_3_3_yesterday"].ToString().Trim();
            dr["今开"] = drOri["open"].ToString().Trim();
            dr["今3线"] = drOri["avg_3_3_today"].ToString().Trim();
            dr["涨幅"] =
                (double.Parse(drOri["open"].ToString().Trim()) - double.Parse(drOri["settlement"].ToString().Trim()))
                / double.Parse(drOri["settlement"].ToString().Trim());
            dt.Rows.Add(dr);
        }

        DataRow[] drArr = dt.Select("", "涨幅 desc");

        DataTable dtNew = dt.Clone();

        foreach (DataRow drOrder in drArr)
        {
            DataRow drNew = dtNew.NewRow();
            foreach (DataColumn c in dt.Columns)
            {
                drNew[c.Caption] = drOrder[c.Caption];
            }
            drNew["涨幅"] = Math.Round(double.Parse(drNew["涨幅"].ToString()) * 100, 2).ToString() + "%";
            drNew["昨3线"] = Math.Round(double.Parse(drNew["昨3线"].ToString()), 3);
            drNew["今3线"] =  Math.Round(double.Parse(drNew["今3线"].ToString()), 3);
            dtNew.Rows.Add(drNew);
        }

        return dtNew;
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
    </div>
    </form>
</body>
</html>
