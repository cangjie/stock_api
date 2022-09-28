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
        double step = 0.1;

        DataTable dt = new DataTable();
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("日期");
        dt.Columns.Add("量比");

        DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up a  where  "
            + " EXISTS (select 'a' from limit_up b where b.alert_date = dbo.func_getlasttransactdate(a.alert_date, 1) and a.gid = b.gid) "
            + " and not EXISTS (select 'a' from limit_up c where c.alert_date = dbo.func_getlasttransactdate(a.alert_date, 2) and c.gid = a.gid) "
            + " and EXISTS ( select 'a' from limit_up d where a.alert_date =  dbo.func_getlasttransactdate(d.alert_date, 1) and d.gid = a.gid) "
            + " and a.alert_date > '2021-1-1' order by a.alert_date desc");
        dtOri.Columns.Add("volume_diff", Type.GetType("System.Double"));
        dtOri.Columns.Add("name");
        double minDiff = double.MaxValue;
        double maxDiff = double.MinValue;
        for (int i = 0; i < dtOri.Rows.Count; i++)
        {
            Stock s = GetStock(dtOri.Rows[i]["gid"].ToString());
            DateTime alertDate = DateTime.Parse(dtOri.Rows[i]["alert_date"].ToString());
            int alertIndex = s.GetItemIndex(alertDate);
            if (alertIndex < 1)
            {
                continue;
            }
            if (s.kLineDay[alertIndex].highestPrice != s.kLineDay[alertIndex].endPrice
                || s.kLineDay[alertIndex].lowestPrice == s.kLineDay[alertIndex].highestPrice)
            {
                continue;
            }
            DataRow dr = dt.NewRow();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["日期"] = s.kLineDay[alertIndex].endDateTime.Date.ToShortDateString();

            double volDiff = s.kLineDay[alertIndex].volume / s.kLineDay[alertIndex-1].volume;
            dr["量比"] = Math.Round(volDiff, 2).ToString();
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
            s.LoadKLineWeek(Util.rc);
            KLine.ComputeMACD(s.kLineWeek);
            KLine.ComputeKDJ(s.kLineWeek);
            gidArr.Add(s);
        }
        return s;
    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>列表-三连板看头两板量比</title>
</head>
<body>
    <form id="form1" runat="server">
        <div>
            <asp:DataGrid ID="dg" runat="server" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
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
