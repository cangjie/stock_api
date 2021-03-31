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
        double startRate = double.Parse(Util.GetSafeRequestValue(Request, "start", "-0.2"));
        double endRate = double.Parse(Util.GetSafeRequestValue(Request, "end", "0.2"));
        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "startdate", "2020-1-1").Trim());
        DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "enddate", DateTime.Now.ToShortDateString()));
        int days = int.Parse(Util.GetSafeRequestValue(Request, "days", "5"));

        DataTable dtSummary = new DataTable();
        dtSummary.Columns.Add("涨幅");
        dtSummary.Columns.Add("总计");
        dtSummary.Columns.Add("涨1%");
        dtSummary.Columns.Add("涨5%");


        for (double i = -0.09; i <= 0.1; i = i + 0.01)
        {
            DataRow drSummary = dtSummary.NewRow();
            drSummary["涨幅"] = ((int)(100 * i)).ToString() + "%";
            drSummary["总计"] = "0";
            drSummary["涨1%"] = "0";
            drSummary["涨5%"] = "0";
            dtSummary.Rows.Add(drSummary);
        }

        /*
        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("涨停");
        dt.Columns.Add("买入");
        dt.Columns.Add("今涨");
        for(int i = 1; i <= days; i++)
        {
            dt.Columns.Add(i.ToString() + "日");
        }
        
        dt.Columns.Add("总计");
        */
        DataTable dtOri = DBHelper.GetDataTable(" select * from alert_traffic_light "
            //+ " where gid = 'sh600980' "
            + " where alert_date >= '" + startDate.ToShortDateString() + "' and alert_date <= '" + endDate.ToShortDateString() + "'  "
            + " order by alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {

            Stock s = GetStock(drOri["gid"].ToString().Trim());

            int alertIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (alertIndex < 2)
            {
                continue;
            }

            if (alertIndex + days >= s.kLineDay.Length)
            {
                continue;
            }
            double maxPrice = Math.Max(s.kLineDay[alertIndex - 1].endPrice, s.kLineDay[alertIndex - 2].endPrice);


            if (!s.IsLimitUp(alertIndex-2))
            {
                continue;
            }

            if (s.IsLimitUp(alertIndex))
            {
                continue;
            }





            int buyIndex = alertIndex ;

            if (buyIndex + days >= s.kLineDay.Length)
            {
                continue;
            }

            double rise = (s.kLineDay[alertIndex].endPrice - maxPrice) / maxPrice;

            if (rise <= startRate || rise >= endRate)
            {
                continue;
            }

            double buyPrice = s.kLineDay[buyIndex].endPrice;
            double finalRate = double.MinValue;

            if (rise < -0.1)
            {
                rise = -0.1;
            }
            if (rise > 0.1)
            {
                rise = 0.1;
            }

            int currentSummaryIndex = (int)(100 * (rise + 0.1));
            int count = int.Parse(dtSummary.Rows[currentSummaryIndex]["总计"].ToString().Trim());
            dtSummary.Rows[currentSummaryIndex]["总计"] = (count + 1).ToString();
            for (int j = 1; j <= days; j++)
            {
                double rate = (s.kLineDay[buyIndex + j].highestPrice - buyPrice) / buyPrice;
                finalRate = Math.Max(finalRate, rate);
            }
            if (finalRate >= 0.01)
            {
                count = int.Parse(dtSummary.Rows[currentSummaryIndex]["涨1%"].ToString().Trim());
                dtSummary.Rows[currentSummaryIndex]["涨1%"] = (count + 1).ToString();

                if (finalRate >= 0.05)
                {
                    count = int.Parse(dtSummary.Rows[currentSummaryIndex]["涨5%"].ToString().Trim());
                    dtSummary.Rows[currentSummaryIndex]["涨5%"] = (count + 1).ToString();
                }
            }

        }
        for (int k = 0; k < dtSummary.Rows.Count; k++)
        {
            int totalCount = int.Parse(dtSummary.Rows[k]["总计"].ToString());
            int count1P = int.Parse(dtSummary.Rows[k]["涨1%"].ToString());
            int count5P = int.Parse(dtSummary.Rows[k]["涨5%"].ToString());
            dtSummary.Rows[k]["涨1%"] = Math.Round(100 * (double)count1P / totalCount).ToString() + "%";
            dtSummary.Rows[k]["涨5%"] = Math.Round(100 * (double)count5P / totalCount).ToString() + "%";
        }
        return dtSummary;
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
