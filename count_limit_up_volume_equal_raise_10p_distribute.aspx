<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public int suc = 0;
    public int newHighSuc = 0;
    public int count = 0;
    public int newHighCount = 0;

    public string countPage = "limit_up_box_settle";

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            countPage = Util.GetSafeRequestValue(Request, "page", "limit_up_box_settle");
            dg.DataSource = GetData(countPage);
            dg.DataBind();
        }
    }

    public DataTable GetData(string countPage)
    {

        DataTable dt = new DataTable();
        dt.Columns.Add("量变");
        dt.Columns.Add("个数");

        for (int j = -9; j <= 10; j++)
        {
            DataRow dr = dt.NewRow();
            dr["量变"] = j.ToString();
            dr["个数"] = 0;
            dt.Rows.Add(dr);
        }

        DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up where alert_date >= '"
            + Util.GetSafeRequestValue(Request, "start", "2021-11-1") + "'  and alert_date <= '"
            + Util.GetSafeRequestValue(Request, "end", DateTime.Now.ToShortDateString()) + "' order by alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {

            bool newHigh = false;
            Stock s = GetStock(drOri["gid"].ToString().Trim());

            int alertIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (alertIndex < 2 || alertIndex >= s.kLineDay.Length - 1)
            {
                continue;
            }

            int buyIndex = alertIndex + 1;


            if (buyIndex + 1 >= s.kLineDay.Length)
            {
                continue;
            }

            double volumeChange = (s.kLineDay[buyIndex].volume - s.kLineDay[alertIndex].volume) / s.kLineDay[alertIndex].volume;

            if (volumeChange >= 0.1 || volumeChange <= -0.1)
            {
                continue;
            }

            int index = (int)(volumeChange * 100) + 10;

            if (volumeChange < 0)
            {
                index--;
            }

            if (Math.Min(s.kLineDay[buyIndex].startPrice, s.kLineDay[buyIndex].endPrice) <= s.kLineDay[alertIndex].highestPrice)
            {
                //no continue;
            }



            double buyPrice = s.kLineDay[buyIndex].endPrice;

            for (int i = buyIndex + 1; i < s.kLineDay.Length && i <= buyIndex + 10; i++)
            {
                if ((s.kLineDay[i].highestPrice - buyPrice) / buyPrice >= 0.1)
                {
                    int count = int.Parse(dt.Rows[index][1].ToString());
                    count++;
                    dt.Rows[index][1] = count.ToString();
                    break;
                }
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
            总计：<%=count.ToString() %> / <%=Math.Round((double)100*suc/(double)count, 2).ToString() %>%<br />
            涨5%：<%=newHighCount.ToString() %> / <%=Math.Round((double)100*newHighCount/(double)count, 2).ToString() %>%
        </div>
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
