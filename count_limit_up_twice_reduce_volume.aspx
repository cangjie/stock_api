<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

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

        DataTable dtOri = DBHelper.GetDataTable(" select a.alert_date, a.gid from limit_up a "
            + " where exists( select 'a' from limit_up b where a.gid = b.gid and dbo.func_GetLastTransactDate(a.alert_date, 1) = b.alert_date) "
            + " and not exists ( select 'a' from limit_up c where a.gid = c.gid and dbo.func_GetNextTransactDate(a.alert_date, 1) = c.alert_date ) "
            + " order by a.alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock s = GetStock(drOri["gid"].ToString().Trim());
            int currentIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (currentIndex >= s.kLineDay.Length - 1)
            {
                continue;
            }
            double maxVolume = 0;
            for (int i = currentIndex; s.IsLimitUp(i); i--)
            {
                maxVolume = Math.Max(maxVolume, s.kLineDay[i].volume);
            }
            if (s.kLineDay[currentIndex + 1].volume >= maxVolume)
            {
                continue;
            }
            if (s.kLineDay[currentIndex + 1].highestPrice <= s.kLineDay[currentIndex].highestPrice)
            {
                continue;
            }
            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[currentIndex + 1].endDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dt.Rows.Add(dr);
        }
        return dt;
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
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
        <div>
            <asp:DataGrid runat="server" id="dg" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
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
