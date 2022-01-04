﻿<%@ Page Language="C#" %>
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
        int days = int.Parse(Util.GetSafeRequestValue(Request, "days", "10"));
        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");

        dt.Columns.Add("买入");

        for(int i = 1; i <= days; i++)
        {
            dt.Columns.Add(i.ToString() + "日");
        }

        dt.Columns.Add("总计");
        DataTable dtOri = DBHelper.GetDataTable(" select * from alert_traffic_light where alert_date >= '"
            + Util.GetSafeRequestValue(Request, "start", "2021-1-1") + "'  and alert_date <= '"
            + Util.GetSafeRequestValue(Request, "end", "2021-12-20") + "' "
            + " and exists ( select 'a' from limit_up where limit_up.gid = alert_traffic_light.gid and  limit_up.alert_date = alert_traffic_light.alert_date ) "
            + "  order by alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {


            Stock s = GetStock(drOri["gid"].ToString().Trim());

            int alertIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (alertIndex < 2 || alertIndex + days >= s.kLineDay.Length - 1 )
            {
                continue;
            }

            if (Util.GetSafeRequestValue(Request, "vol", "0").Trim().Equals("0"))
            {
                if (s.kLineDay[alertIndex].volume >= s.kLineDay[alertIndex - 1].volume)
                {
                    continue;
                }
            }
            else
            {
                if (s.kLineDay[alertIndex].volume <= s.kLineDay[alertIndex - 1].volume)
                {
                    continue;
                }
            }

            int buyIndex = alertIndex + 1;


            if (buyIndex + days >= s.kLineDay.Length)
            {
                continue;
            }

            double buyPrice = s.kLineDay[buyIndex].startPrice;

            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[buyIndex].endDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["买入"] = buyPrice.ToString();

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