<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    protected void Page_Load(object sender, EventArgs e)
    {
        DataTable dt = DBHelper.GetDataTable(" select * from alert_traffic_light order by alert_date desc ");
        DataTable dtResult = new DataTable();
        dtResult.Columns.Add("放量", Type.GetType("System.Int32"));
        dtResult.Columns.Add("个数", Type.GetType("System.Int32"));
        foreach (DataRow dr in dt.Rows)
        {
            Stock s = GetStock(dr["gid"].ToString());
            int alertIndex = s.GetItemIndex(DateTime.Parse(dr["alert_date"].ToString().Trim()).Date);
            if (alertIndex < 2)
            {
                continue;
            }
            double deltaVolume = s.kLineDay[alertIndex - 1].volume - s.kLineDay[alertIndex - 2].volume;
            int volumeChangeRate = (int)(10 * Math.Round(10 * deltaVolume / s.kLineDay[alertIndex - 2].volume, 0));
            DataRow[] drResultArr = dtResult.Select(" 放量 = '" + volumeChangeRate.ToString() + "' ");
            if (drResultArr.Length == 0)
            {
                DataRow drResult = dtResult.NewRow();
                drResult["放量"] = volumeChangeRate;
                drResult["个数"] = 1;
                dtResult.Rows.Add(drResult);
            }
            else
            {
                int num = (int)drResultArr[0]["个数"];
                num++;
                drResultArr[0]["个数"] = num;
            }
        }
        DataTable dtFinal = dtResult.Clone();
        foreach(DataRow drR in dtResult.Select(" ", " 个数 desc "))
        {
            DataRow drFinal = dtFinal.NewRow();
            drFinal["放量"] = drR["放量"];
            drFinal["个数"] = drR["个数"];
            dtFinal.Rows.Add(drFinal);
        }
        dg.DataSource = dtFinal;
        dg.DataBind();
    }

    public  Stock GetStock(string gid)
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
        <div>
            <asp:DataGrid runat="server" ID="dg" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
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
