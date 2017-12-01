<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {

    }

    public DataTable GetData()
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("gid", Type.GetType("System.String"));
        dt.Columns.Add("update_time", Type.GetType("System.DateTime"));
        //CachedKLine[] cachedKLine = new CachedKLine[Stock.kLineCache.Count];
        for (int i = 0; i < Stock.kLineCache.Count; i++)
        {
            CachedKLine c = (CachedKLine)Stock.kLineCache[i];
            DataRow dr = dt.NewRow();
            dr["gid"] = c.gid.Trim();
            dr["update_time"] = c.lastUpdate;
            dt.Rows.Add(dr);
        }

        DataTable dtNew = dt.Clone();
        int j = 0;
        foreach (DataRow dr in dt.Select("", "update_time"))
        {
            DataRow drNew = dtNew.NewRow();
            drNew["gid"] = dr["gid"].ToString();
            drNew["update_time"] = dr["update_time"];
            dtNew.Rows.Add(drNew);
            j++;
        }
        dt.Dispose();
        DataRow drTotal = dtNew.NewRow();
        drTotal["gid"] = "总计：" + j.ToString();
        dtNew.Rows.Add(drTotal);
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
