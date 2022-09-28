<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();
    public int totalCount = 0;
    public int sucCount = 0;


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
        //double step = 0.1;

        DataTable dt = new DataTable();
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("日期");
        dt.Columns.Add("量比");
        dt.Columns.Add("次日");

        DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up a  where  "
            + " EXISTS (select 'a' from limit_up b where b.alert_date = dbo.func_getlasttransactdate(a.alert_date, 1) and a.gid = b.gid) "
            + " and not EXISTS (select 'a' from limit_up c where c.alert_date = dbo.func_getlasttransactdate(a.alert_date, 2) and c.gid = a.gid) "
            //+ " and EXISTS ( select 'a' from limit_up d where a.alert_date =  dbo.func_getlasttransactdate(d.alert_date, 1) and d.gid = a.gid) "
            + " and a.alert_date > '2021-1-1' order by a.alert_date desc");


        for (int i = 0; i < dtOri.Rows.Count; i++)
        {
            Stock s = GetStock(dtOri.Rows[i]["gid"].ToString());
            DateTime alertDate = DateTime.Parse(dtOri.Rows[i]["alert_date"].ToString());
            int alertIndex = s.GetItemIndex(alertDate);
            if (alertIndex < 1 || alertIndex >= s.kLineDay.Length - 1)
            {
                continue;
            }

            if (s.kLineDay[alertIndex].highestPrice == s.kLineDay[alertIndex].endPrice
                || s.kLineDay[alertIndex - 1].highestPrice == s.kLineDay[alertIndex - 1].endPrice
                || s.kLineDay[alertIndex].highestPrice != s.kLineDay[alertIndex].endPrice)
            {
                continue;
            }
            double volDiff = s.kLineDay[alertIndex].volume / s.kLineDay[alertIndex - 1].volume;
            bool flag = false;
            if ((volDiff >= 1 && volDiff < 1.2) || (volDiff >= 1.3 && volDiff < 1.5))
            {
                flag = true;
            }
            if (!flag)
            {
                continue;
            }

            DataRow dr = dt.NewRow();
            dr["代码"] = s.gid;
            dr["名称"] = s.Name;
            dr["日期"] = s.kLineDay[alertIndex].startDateTime.ToShortDateString();
            dr["量比"] = Math.Round(volDiff, 2).ToString();
            dr["次日"] = Math.Round(100 * (s.kLineDay[alertIndex + 1].endPrice - s.kLineDay[alertIndex].endPrice) / s.kLineDay[alertIndex].endPrice, 2).ToString() + "%";
            dt.Rows.Add(dr);
            totalCount++;
            if (s.IsLimitUp(alertIndex + 1))
            {
                sucCount++;
            }


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
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
        <div><%= Math.Round(100*sucCount/(float)totalCount, 2).ToString() %>%</div>
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
