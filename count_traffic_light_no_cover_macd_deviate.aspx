<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public int suc = 0;
    public int newHighSuc = 0;
    public int count = 0;
    public int newHighCount = 0;


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

        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "startdate", "2020-1-1").Trim());
        DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "enddate", DateTime.Now.ToShortDateString()));
        int days = int.Parse(Util.GetSafeRequestValue(Request, "days", "10"));
        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("今涨");
        dt.Columns.Add("红绿灯涨");
        dt.Columns.Add("买入");

        for(int i = 1; i <= days; i++)
        {
            dt.Columns.Add(i.ToString() + "日");
        }

        dt.Columns.Add("总计");
        DataTable dtOri = DBHelper.GetDataTable(" select * from alert_traffic_light where alert_date >= '" + startDate.ToShortDateString()
            + "' and alert_date <= '" + endDate.ToShortDateString() + "' order by alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock s = GetStock(drOri["gid"].ToString().Trim());
            int alertIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (alertIndex < 2)
            {
                continue;
            }

            if (s.kLineDay[alertIndex].startPrice <= s.kLineDay[alertIndex - 1].endPrice)
            {
                continue;
            }

            int buyIndex = 0;
            for (int i = 1; i <= 30 && alertIndex + i < s.kLineDay.Length
                && s.kLineDay[alertIndex + i].highestPrice < s.kLineDay[alertIndex].highestPrice; i++)
            {
                if (s.kLineDay[alertIndex + i].macd >= 0
                    && s.kLineDay[alertIndex + i].endPrice < s.kLineDay[alertIndex + i - 1].endPrice
                    && s.kLineDay[alertIndex + i].macd > s.kLineDay[alertIndex + i - 1].macd
                    //&& s.kLineDay[alertIndex + i - 1].endPrice < s.kLineDay[alertIndex + i - 2].endPrice
                    //&& s.kLineDay[alertIndex + i - 1].macd > s.kLineDay[alertIndex + i - 2].macd
                    //&& s.kLineDay[alertIndex + i - 2].endPrice < s.kLineDay[alertIndex + i - 3].endPrice
                    //&& s.kLineDay[alertIndex + i - 2].macd > s.kLineDay[alertIndex + i - 3].macd
                    )
                {
                    buyIndex = alertIndex + i;
                    break;
                }
            }



            if (buyIndex == 0)
            {
                continue;

            }

            if (s.macdDays(buyIndex) > 1)
            {
                continue;
            }

            //int buyIndex = alertIndex ;

            if (buyIndex + days >= s.kLineDay.Length)
            {
                continue;
            }

            if (s.IsLimitUp(alertIndex))
            {
                continue;
            }

            double buyPrice = s.kLineDay[buyIndex].startPrice;

            string buyPoint = Util.GetSafeRequestValue(Request, "buypoint", "end");

            if (buyPoint.Trim().Equals("end"))
            {
                buyPrice = s.kLineDay[buyIndex].endPrice;
            }

            if (s.macdDays(buyIndex) > 2)
            {
                //continue;
            }

            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[buyIndex].endDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["买入"] = buyPrice.ToString();
            dr["今涨"] = Math.Round(100 * (s.kLineDay[buyIndex].endPrice - s.kLineDay[buyIndex - 1].endPrice) / s.kLineDay[buyIndex - 1].endPrice, 2).ToString() + "%";
            double trafficLightPrice = Math.Max(Math.Max(s.kLineDay[buyIndex].highestPrice, s.kLineDay[buyIndex - 1].highestPrice), s.kLineDay[buyIndex - 2].highestPrice);
            dr["红绿灯涨"] = Math.Round(100 * (s.kLineDay[buyIndex].endPrice - trafficLightPrice) / trafficLightPrice, 2).ToString() + "%";
            double finalRate = double.MinValue;



            for (int j = 1; j <= days; j++)
            {
                double rate = (s.kLineDay[buyIndex + j].highestPrice - buyPrice) / buyPrice;
                finalRate = Math.Max(finalRate, rate);
                if (rate >= 0.01)
                {
                    dr[j.ToString() + "日"] = "<font color=red >" + Math.Round(rate * 100, 2).ToString() + "%</font>";
                }
                else
                {
                    dr[j.ToString() + "日"] = "<font color=green >" + Math.Round(rate * 100, 2).ToString() + "%</font>";
                }
            }
            if (finalRate >= 0.01)
            {

                dr["总计"] = "<font color=red >" + Math.Round(finalRate * 100, 2).ToString() + "%</font>";
            }
            else
            {
                dr["总计"] = "<font color=green >" + Math.Round(finalRate * 100, 2).ToString() + "%</font>";
            }

            count++;

            if (finalRate >= 0.01)
            {
                suc++;
                if (finalRate >= 0.05)
                {
                    newHighCount++;
                }
            }

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
            KLine.ComputeMACD(s.kLineDay);
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
