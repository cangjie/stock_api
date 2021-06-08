<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public int totalCount = 0;
    public int trafficLightCount = 0;
    public int trafficLightPeaceCount = 0;
    public int trafficLightSucCount = 0;
    public int noneTrafficLightPeaceCount = 0;
    public int noneTrafficLightSucCount = 0;

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

        bool needWeek = Util.GetSafeRequestValue(Request, "week", "1").Equals("1") ? true : false;
        int days = int.Parse(Util.GetSafeRequestValue(Request, "days", "15"));
        int greenDays = int.Parse(Util.GetSafeRequestValue(Request, "greendays", "5"));
        string buyPoint = Util.GetSafeRequestValue(Request, "buypoint", "settle");
        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", "2021-4-15").Trim());
        DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", "2021-5-15"));



        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        
        dt.Columns.Add("买入");
        for (int i = 1; i <= days; i++)
        {
            dt.Columns.Add(i.ToString() + "日");
        }
        dt.Columns.Add("总计");
        DataTable dtOri = DBHelper.GetDataTable(" select * from alert_continuous_green  where alert_date >= '" + startDate.ToShortDateString()
            + "' and alert_date <= '" + endDate.ToShortDateString() + "' and green_num = " + greenDays.ToString() 
            //+ " and gid = 'sh600395' "
            + " order by alert_date desc  ");
        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock s = GetStock(drOri["gid"].ToString());

            int alertIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            int buyIndex = -1;

            if (alertIndex < 0 || alertIndex > s.kLineDay.Length)
            {
                continue;
            }

            for (int i = alertIndex + 1; i < s.kLineDay.Length; i++)
            {
                if (  (s.kLineDay[i-1].endPrice < s.GetAverageSettlePrice(i-1, 3, 3) || s.kLineDay[i].startPrice < s.GetAverageSettlePrice(i, 3, 3)) && s.kLineDay[i].endPrice > s.GetAverageSettlePrice(i, 3, 3) 
                    && s.kLineDay[i-2].macd <= s.kLineDay[i-1].macd && s.kLineDay[i-1].macd <= s.kLineDay[i].macd)
                {
                    buyIndex = i;
                    break;
                }
            }

            if (buyIndex < 0 || buyIndex > s.kLineDay.Length)
            {
                continue;
            }




          
            int buyWeekIndex = s.GetItemIndex(s.kLineDay[buyIndex].startDateTime.Date, "week");

            if (needWeek)
            {
                int weeks = s.kdjWeeks(buyWeekIndex);
                if (weeks < 0 || weeks > 2)
                {
                    continue;
                }
            }

            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[buyIndex].startDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
           
            double buyPrice = buyPoint.Trim().Equals("settle") ? s.kLineDay[buyIndex].endPrice : s.kLineDay[buyIndex].startPrice;
            dr["买入"] = buyPrice;
            double maxPrice = 0;
            if (buyIndex + days >= s.kLineDay.Length)
            {
                continue;
            }
            for (int i = 1; i <= days; i++)
            {
                double rate = (s.kLineDay[buyIndex + i].highestPrice - buyPrice) / buyPrice;
                maxPrice = Math.Max(maxPrice, s.kLineDay[buyIndex + i].highestPrice);
                if (rate >= 0.01)
                {
                    dr[i.ToString() + "日"] = "<font color=red >" + Math.Round(rate * 100, 2).ToString() + "%</font>";
                }
                else
                {
                    dr[i.ToString() + "日"] = "<font color=green >" + Math.Round(rate * 100, 2).ToString() + "%</font>";
                }

            }
            double maxRate = (maxPrice - buyPrice) / buyPrice;
            if (maxRate < 0.01)
            {
                dr["总计"] = "<font color=green >" + Math.Round(maxRate * 100, 2).ToString() + "%</font>";
            }
            else if (maxRate < 0.05)
            {
                dr["总计"] = "<font color=red >" + Math.Round(maxRate * 100, 2).ToString() + "%</font>";
                noneTrafficLightPeaceCount++;
                
            }
            else
            {
                dr["总计"] = "<font color=red >" + Math.Round(maxRate * 100, 2).ToString() + "%</font>";
                noneTrafficLightPeaceCount++;
                noneTrafficLightSucCount++;
                
            }
            
            totalCount++;
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

            s.LoadKLineWeek(Util.rc);
            KLine.ComputeMACD(s.kLineWeek);
            KLine.ComputeRSV(s.kLineWeek);
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
        <div>
            涨1%：<%=Math.Round(100 * (double)noneTrafficLightPeaceCount/(double)(totalCount - trafficLightCount), 2).ToString() %> 涨5%：<%=Math.Round(100 * (double)noneTrafficLightSucCount/(double)(totalCount - trafficLightCount), 2).ToString() %>
        </div>
        <div>
            <asp:DataGrid ID="dg" runat="server" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
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
