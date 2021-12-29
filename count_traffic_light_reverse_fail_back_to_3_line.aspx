﻿<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public int suc = 0;
    public int newHighSuc = 0;
    public int count = 0;
    public int newHighCount = 0;
    public int backToF5Count = 0;

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

        string option = Util.GetSafeRequestValue(Request, "option", "high");

        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", "2021-1-1"));
        DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", DateTime.Now.ToShortDateString()));

        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("涨停");
        dt.Columns.Add("买入");
        dt.Columns.Add("前低");
        dt.Columns.Add("F5");
        dt.Columns.Add("F3");
        dt.Columns.Add("现高");
        for (int i = 1; i <= days; i++)
        {
            dt.Columns.Add(i.ToString() + "日");
        }

        dt.Columns.Add("总计");
        DataTable dtOri = DBHelper.GetDataTable(" select alert_date, gid  from alert_traffic_light  where  "
            + "   alert_date >= '" + startDate.ToShortDateString() + "' and alert_date <= '" + endDate.ToShortDateString() + "'  "
            //+ " and gid = 'sz300244' "
            + " order by alert_date desc ");

        foreach (DataRow drOri in dtOri.Rows)
        {



            Stock s = GetStock(drOri["gid"].ToString().Trim());



            int alertIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (alertIndex < 2 || alertIndex >= s.kLineDay.Length - 3 - days)
            {
                continue;
            }



            if (Math.Abs(s.kLineDay[alertIndex - 2].volume - s.kLineDay[alertIndex - 1].volume) / s.kLineDay[alertIndex - 2].volume >= 0.02
                && s.kLineDay[alertIndex].volume < s.kLineDay[alertIndex - 1].volume)
            {
                continue;
            }
            if (s.kLineDay[alertIndex].highestPrice <= s.kLineDay[alertIndex - 1].highestPrice)
            {
                continue;
            }

            double maxPrice = 0;
            int maxPriceIndex = 0;

            for (int i = alertIndex; i < s.kLineDay.Length && s.kLineDay[i].endPrice >= s.GetAverageSettlePrice(i, 3, 3) ; i++)
            {
                if (maxPrice < s.kLineDay[i].highestPrice)
                {
                    maxPrice = s.kLineDay[i].highestPrice;
                    maxPriceIndex = i;
                }
            }
            int minPriceIndex = 0;
            double minPrice = GetFirstLowestPrice(s.kLineDay, alertIndex - 1, out minPriceIndex);

            if (minPriceIndex == 0 || maxPriceIndex == 0)
            {
                continue;
            }

            double f3 = maxPrice - (maxPrice - minPrice) * 0.382;
            double f5 = maxPrice - (maxPrice - minPrice) * 0.618;

            int belowF5Days = 0;

            int f5Index = 0;

            for (int i = alertIndex; i - alertIndex <= 20 && i < s.kLineDay.Length && belowF5Days < 1; i++)
            {
                if (s.kLineDay[i].endPrice <= f5)
                {
                    belowF5Days++;
                    if (belowF5Days == 1)
                    {
                        f5Index = i;
                    }
                }
                else
                {
                    belowF5Days = 0;
                }
            }


            if (f5Index == 0)
            {
                continue;
            }

            if (s.kLineDay[f5Index].endPrice > s.GetAverageSettlePrice(f5Index, 3, 3))
            {
                continue;
            }

            int buyIndex = 0;
            for (int i = f5Index; i < s.kLineDay.Length ; i++)
            {
                if (s.kLineDay[i].endPrice > s.GetAverageSettlePrice(i, 3, 3))
                {
                    buyIndex = i;
                    break;
                }
            }

            if (buyIndex == 0)
            {
                continue;
            }


            double maxVolume = Math.Max(s.kLineDay[alertIndex].volume, s.kLineDay[alertIndex - 1].volume);








            if (buyIndex + days >= s.kLineDay.Length)
            {
                continue;
            }

            double buyPrice = s.kLineDay[buyIndex].endPrice;

            if (buyPrice >= f5)
            {
                continue;
            }

            double newMinPrice = double.MaxValue;

            for (int i = alertIndex; i <= buyIndex; i++)
            {
                newMinPrice = Math.Min(s.kLineDay[i].lowestPrice, newMinPrice);
            }

            double newF3 = newMinPrice + (maxPrice - newMinPrice) * 0.382;

            if (buyPrice >= newF3)
            {
                continue;
            }



            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[buyIndex].endDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["买入"] = buyPrice.ToString();
            dr["涨停"] = "--";
            dr["前低"] = minPrice;
            dr["F3"] = f3;
            dr["F5"] = f5;
            dr["现高"] = maxPrice;
            double finalRate = double.MinValue;
            bool backToF5 = false;
            for (int j = 1; j <= days && buyIndex + j < s.kLineDay.Length ; j++)
            {
                double rate = (s.kLineDay[buyIndex + j].highestPrice - buyPrice) / buyPrice;
                if (s.kLineDay[buyIndex + j].highestPrice > newF3)
                {
                    backToF5 = true;
                }
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
            if (backToF5)
            {
                backToF5Count++;
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
            折返到F3：<%=backToF5Count.ToString() %> / <%=Math.Round((double)100*backToF5Count/(double)count, 2).ToString() %>%
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