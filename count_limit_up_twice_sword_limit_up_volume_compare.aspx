<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    
    public int count = 0;
    public int count1 = 0;
    public int count2 = 0;
    public int count3 = 0;
    public int count4 = 0;
    public int count5 = 0;


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

        //DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "startdate", "2021-1-1").Trim());
        //DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "enddate", DateTime.Now.ToShortDateString()));
        int days = int.Parse(Util.GetSafeRequestValue(Request, "days", "10"));
        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");

        dt.Columns.Add("量差");

        dt.Columns.Add("分类");

        
        DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up a where  alert_date > '2021-1-1' "
            + " and exists (select 'a' from limit_up b where a.gid = b.gid and dbo.func_GetLastTransactDate(b.alert_date, 1) = a.alert_date) "
            + " and exists (select 'a' from limit_up c where a.gid = c.gid and dbo.func_GetLastTransactDate(c.alert_date, 2) = a.alert_date) "
            + " and exists (select 'a' from limit_up d where a.gid = d.gid and dbo.func_GetLastTransactDate(d.alert_date, 4) = a.alert_date) "
            + " order by alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock s = GetStock(drOri["gid"].ToString().Trim());
            int alertIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (alertIndex < 0)
            {
                continue;
            }

            if (alertIndex >= s.kLineDay.Length-3)
            {
                continue;
            }

            if (!s.IsLimitUp(alertIndex) || !s.IsLimitUp(alertIndex+1) || !s.IsLimitUp(alertIndex + 3) 
                || Math.Min(s.kLineDay[alertIndex + 2].startPrice, s.kLineDay[alertIndex + 2].endPrice) <= s.kLineDay[alertIndex - 1].endPrice)
            {
                continue;
            }

            double greenVolume = s.kLineDay[alertIndex + 2].volume;
            double redVolume = s.kLineDay[alertIndex + 1].volume;

            double diff = (greenVolume - redVolume) / redVolume;


            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[alertIndex + 1].endDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["量差"] = Math.Round(diff * 100, 2).ToString() + "%";
            string level = "";
            count++;
            if (diff <= -0.5)
            {
                level = "缩量50%以上";
                count1++;
            }
            else if (diff <= -0.1)
            {
                level = "缩量50%-10%";
                count2++;
            }
            else if (diff <= 0.1)
            {
                level = "平量";
                count3++;
            }
            else if (diff <= 2)
            {
                level = "放量";
                count4++;
            }
            else
            {
                level = "放大量";
                count5++;
            }
            dr["分类"] = level.Trim();
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
            总计:<%=count.ToString()%><br />
            缩量50%以上 <%=count1.ToString() %>  <%=Math.Round(100*count1/(double)count, 2).ToString() %>%<br />
            缩量50%-10% <%=count2.ToString() %>  <%=Math.Round(100*count2/(double)count, 2).ToString() %>%<br />
            平量 <%=count3.ToString() %>  <%=Math.Round(100*count3/(double)count, 2).ToString() %>%<br />
            放量 <%=count4.ToString() %>  <%=Math.Round(100*count4/(double)count, 2).ToString() %>%<br />
            放大量 <%=count5.ToString() %>  <%=Math.Round(100*count5/(double)count, 2).ToString() %>%<br />
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
