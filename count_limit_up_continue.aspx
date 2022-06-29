<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public int limitNun = 3;
    public string sql = "";
    public DateTime startDate = DateTime.Parse("2021-1-1");
    public int suc = 0;
    public double sucRate = 0;

    protected void Page_Load(object sender, EventArgs e)
    {
        limitNun = int.Parse(Util.GetSafeRequestValue(Request, "limitnum", "3"));
        startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", "2021-1-1"));
        sql = " select * from limit_up a where  alert_date >= '" + startDate.ToShortDateString() + "' ";
        for (int i = 2; i < limitNun; i++)
        {
            sql = sql + " and  exists (select  'a' from limit_up a" + i.ToString() + "  where a.gid = a" + i.ToString() + ".gid and a" + i.ToString() + ".alert_date = dbo.func_GetLastTransactDate(a.alert_date, " + (i - 1).ToString() + ") ) ";
        }
        sql = sql + " and not exists ( select  'a' from limit_up ab where a.gid = ab.gid and ab.alert_date = dbo.func_GetLastTransactDate(a.alert_date, " + (limitNun - 1).ToString() + ")) "
            + " order by alert_date desc ";
        DataTable dtOri = DBHelper.GetDataTable(sql);

        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("成功");

        for (int i = 0; i < dtOri.Rows.Count; i++)
        {
            Stock s = GetStock(dtOri.Rows[i]["gid"].ToString().Trim());
            DateTime alertDate = DateTime.Parse(dtOri.Rows[i]["alert_date"].ToString().Trim());
            int alertIndex = s.GetItemIndex(alertDate);
            if (alertIndex >= s.kLineDay.Length - 1 || alertIndex <= limitNun)
            {
                continue;
            }
            bool contiLimitUp = true;
            for (int j = 0; j < limitNun - 1; j++)
            {
                if (!s.IsLimitUp(alertIndex - j))
                {
                    contiLimitUp = false;
                    break;
                }
            }
            if (!contiLimitUp)
            {
                continue;
            }

            bool isSuc = false;
            if (s.IsLimitUp(alertIndex + 1))
            {
                isSuc = true;
                suc++;
            }

            DataRow dr = dt.NewRow();
            dr["日期"] = alertDate.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["成功"] = isSuc ? "是" : "否";
            dt.Rows.Add(dr);
        }
        dg.DataSource = dt;
        dg.DataBind();
        if (dt.Rows.Count > 0)
        {
            sucRate = 100 * (double)suc / (double)dt.Rows.Count;
        }

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
    <title>连扳成功率</title>
</head>
<body>
    <form id="form1" runat="server">
        <div>再板率：<% =Math.Round(sucRate, 2).ToString() %>%</div>
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
