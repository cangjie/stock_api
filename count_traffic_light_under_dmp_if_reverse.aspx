<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public int suc = 0;
    public int newHighSuc = 0;
    public int count = 0;
    public int newHighCount = 0;
    public int failCount = 0;

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
        int days = int.Parse(Util.GetSafeRequestValue(Request, "days", "10"));

        int line = int.Parse(Util.GetSafeRequestValue(Request, "line", "3"));

        string option = Util.GetSafeRequestValue(Request, "option", "high");

        int reverse = int.Parse(Util.GetSafeRequestValue(Request, "reverse", "1"));

        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", "2021-1-1"));
        DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", DateTime.Now.ToShortDateString()));

        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("涨停");
        dt.Columns.Add("买入");
        for (int i = 1; i <= days; i++)
        {
            dt.Columns.Add(i.ToString() + "日");
        }

        dt.Columns.Add("总计");
        DataTable dtOri = DBHelper.GetDataTable(" select alert_date, gid  from alert_traffic_light  where  "
            + "   alert_date >= '" + startDate.ToShortDateString() + "' and alert_date <= '" + endDate.ToShortDateString() + "'     order by alert_date desc ");

        foreach (DataRow drOri in dtOri.Rows)
        {



            Stock s = GetStock(drOri["gid"].ToString().Trim());



            int alertIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (alertIndex < 2 || alertIndex >= s.kLineDay.Length - 3 - days)
            {
                continue;
            }


            if (reverse == 1)
            {
                if (Math.Abs(s.kLineDay[alertIndex - 2].volume - s.kLineDay[alertIndex - 1].volume) / s.kLineDay[alertIndex - 2].volume >= 0.02
                    && s.kLineDay[alertIndex].volume < s.kLineDay[alertIndex - 1].volume)
                {
                    continue;
                }
                if (s.kLineDay[alertIndex].highestPrice <= s.kLineDay[alertIndex - 1].highestPrice)
                {
                    continue;
                }
            }
            else
            {
                if (Math.Abs(s.kLineDay[alertIndex - 2].volume - s.kLineDay[alertIndex - 1].volume) / s.kLineDay[alertIndex - 2].volume < 0.02
                    && s.kLineDay[alertIndex].volume >= s.kLineDay[alertIndex - 1].volume)
                {
                    continue;
                }
                if (s.kLineDay[alertIndex].highestPrice > s.kLineDay[alertIndex - 1].highestPrice)
                {
                    continue;
                }
            }

            KLine.ComputeMACD(s.kLineDay);

            if (s.macdDays(alertIndex) >= 0)
            {
                continue;
            }



            int buyIndex = alertIndex;



            double maxVolume = Math.Max(s.kLineDay[alertIndex].volume, s.kLineDay[alertIndex - 1].volume);






            //int buyIndex = touch3LineIndex;

            if (buyIndex + days >= s.kLineDay.Length)
            {
                continue;
            }

            double buyPrice = s.kLineDay[buyIndex].endPrice;



            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[buyIndex].endDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["买入"] = buyPrice.ToString();
            dr["涨停"] = "--";

            double finalRate = double.MinValue;
            for (int j = 1; j <= days && buyIndex + j < s.kLineDay.Length ; j++)
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
                suc++;
                if (finalRate >= 0.05)
                {
                    newHighCount++;
                }
                dr["总计"] = "<font color=red >" + Math.Round(finalRate * 100, 2).ToString() + "%</font>";
            }
            else
            {
                if (finalRate < 0)
                {
                    failCount++;
                }
                dr["总计"] = "<font color=green >" + Math.Round(finalRate * 100, 2).ToString() + "%</font>";
            }
            count++;

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

    public static double GetFirstLowestPrice(KLine[] kArr, int index, out int lowestIndex)
    {
        double ret = double.MaxValue;
        int find = 0;
        lowestIndex = 0;
        for (int i = index - 1; i > 0 && find < 2; i--)
        {
            double line3Pirce = KLine.GetAverageSettlePrice(kArr, i, 3, 3);
            ret = Math.Min(ret, kArr[i].lowestPrice);
            if (ret == kArr[i].lowestPrice)
            {
                lowestIndex = i;
            }
            if (kArr[i].endPrice < line3Pirce)
            {
                find = 1;
            }
            if (kArr[i].lowestPrice >= line3Pirce && find == 1)
            {
                find = 2;
            }
        }
        return ret;
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
            涨5%：<%=newHighCount.ToString() %> / <%=Math.Round((double)100*newHighCount/(double)count, 2).ToString() %>%<br />
            失败：<%= Math.Round(100*failCount/(double)count, 2)%>
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
