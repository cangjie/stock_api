﻿<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public static int count = 0;

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

        DataTable dtOri = DBHelper.GetDataTable("select * from limit_up a where exists(select 'a' from limit_up b where a.gid = b.gid and b.alert_date = dbo.func_GetLastTransactDate(a.alert_date, 1)) "
           // + " and gid = 'sz300643' " 
            + " order by a.alert_date desc"
            );
        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock stock = GetStock(drOri["gid"].ToString());
            int currentIndex = stock.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (currentIndex < 1)
            {
                continue;
            }
            if (!stock.IsLimitUpContinous(currentIndex, 2))
            {
                continue;
            }
            if (currentIndex >= stock.kLineDay.Length - 1)
            {
                continue;
            }
            if (Util.GetSafeRequestValue(Request, "continue", "1").Equals("1"))
            {
                if (!stock.IsLimitUp(currentIndex + 1))
                {
                    continue;
                }
            }
            else
            {
                if (stock.IsLimitUp(currentIndex + 1))
                {
                    continue;
                }
            }
            DataRow dr = dt.NewRow();
            dr["日期"] = stock.kLineDay[currentIndex].startDateTime.ToShortDateString();
            dr["代码"] = stock.gid;
            dr["名称"] = stock.Name.Trim();
            dt.Rows.Add(dr);
        }
        count = dt.Rows.Count;
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
        <div>总计：<%=count %></div>
        <div><asp:DataGrid ID="dg" runat="server" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" Width="100%">
            <AlternatingItemStyle BackColor="#DCDCDC" />
            <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
            <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
            <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
            <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
            <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
            </asp:DataGrid></div>
    </div>
    </form>
</body>
</html>
