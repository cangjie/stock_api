<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">



    public int count = 0;

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
        dt.Columns.Add("gid", Type.GetType("System.String"));
        dt.Columns.Add("update_time", Type.GetType("System.DateTime"));
        dt.Columns.Add("last_K_line", Type.GetType("System.DateTime"));
        for (int i = 0; i < KLineCache.kLineDayCache.Length; i++)
        {
            CachedKLine c = (CachedKLine)KLineCache.kLineDayCache[i];
            if (c.gid != null && !c.gid.Trim().Equals("") && c.kLine.Length > 0)
            {
                DataRow dr = dt.NewRow();
                dr["gid"] = c.gid.Trim();
                dr["update_time"] = c.lastUpdate;
                dr["last_K_line"] = c.kLine[c.kLine.Length - 1].startDateTime ;
                dt.Rows.Add(dr);
            }
        }
        DataTable dtNew = dt.Clone();
        int j = 0;
        foreach (DataRow dr in dt.Select("", "last_K_line desc"))
        {
            DataRow drNew = dtNew.NewRow();
            drNew["gid"] = dr["gid"].ToString();
            drNew["update_time"] = dr["update_time"];
            drNew["last_K_line"] = dr["last_K_line"];
            dtNew.Rows.Add(drNew);
            j++;
        }
        dt.Dispose();
        count = j;
        return dtNew;
    }


</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
        <%=count %>
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
