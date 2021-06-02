<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public int totalCount = 0;
    public int peaceCount = 0;
    public int sucCount = 0;


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
        int volumeDiff = int.Parse(Util.GetSafeRequestValue(Request, "voldiff", "10"));
        bool needWeek = Util.GetSafeRequestValue(Request, "week", "1").Equals("1") ? true : false;
        int days = int.Parse(Util.GetSafeRequestValue(Request, "days", "10"));
        string buyPoint = Util.GetSafeRequestValue(Request, "buypoint", "settle");
        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", "2021-1-1").Trim());
        DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", "2021-6-1"));


      
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
        DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up a where not exists ( select 'a' from limit_up b where a.gid = b.gid and dbo.func_GetLastTransactDate(b.alert_date, 1) = a.alert_date  ) "
           + " and  alert_date >= '" + startDate.ToShortDateString()  + "' and alert_date <= '" + endDate.ToShortDateString() + "' order by alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock s = GetStock(drOri["gid"].ToString());
            int limitUpDayIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            int buyIndex = limitUpDayIndex + 2;
            if (buyIndex > s.kLineDay.Length - 1)
            {
                continue;
            }
            if (s.kLineDay[buyIndex].startPrice >= s.kLineDay[buyIndex].endPrice)
            {
                continue;
            }

            if (s.kLineDay[buyIndex].highestPrice < Math.Max(s.kLineDay[buyIndex - 1].startPrice, s.kLineDay[buyIndex - 1].endPrice))
            {
                continue;
            }

            if (s.kLineDay[buyIndex - 1].startPrice <= s.kLineDay[buyIndex - 1].endPrice)
            {
                continue;
            }

            if (s.kLineDay[buyIndex].startPrice <= s.kLineDay[buyIndex - 1].endPrice)
            {
                continue;
            }

            if ((int)(100 * Math.Abs(s.kLineDay[buyIndex].volume - s.kLineDay[buyIndex - 1].volume) / s.kLineDay[buyIndex - 1].volume) > volumeDiff)
            {
                continue;
            }

            if (needWeek)
            {
                int weekIndex = s.GetItemIndex(s.kLineDay[buyIndex].endDateTime.Date, "week");
                int kdjWeeks = s.kdjWeeks(weekIndex);
                if (kdjWeeks < 0 || kdjWeeks > 2)
                {
                    continue;
                }
            }





            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[buyIndex].startDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();

            double buyPrice =  s.kLineDay[buyIndex].endPrice;
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
                peaceCount++;
                dr["总计"] = "<font color=red >" + Math.Round(maxRate * 100, 2).ToString() + "%</font>";

            }
            else
            {
                peaceCount++;
                sucCount++;
                dr["总计"] = "<font color=red >" + Math.Round(maxRate * 100, 2).ToString() + "%</font>";

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
            平仓：<%= Math.Round(100 * (double)peaceCount / (double)totalCount, 2).ToString() %>%  成功：<%= Math.Round(100 * (double)sucCount / (double)totalCount, 2).ToString() %>%
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
