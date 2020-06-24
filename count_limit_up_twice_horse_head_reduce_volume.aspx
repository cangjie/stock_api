﻿<%@ Page Language="C#" %>
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
        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        //dt.Columns.Add("新高");
        dt.Columns.Add("买入");
        dt.Columns.Add("缩量");
        dt.Columns.Add("1日");
        dt.Columns.Add("2日");
        dt.Columns.Add("3日");
        dt.Columns.Add("4日");
        dt.Columns.Add("5日");
        dt.Columns.Add("总计");
        DataTable dtOri = DBHelper.GetDataTable(" select a.alert_date, a.gid from limit_up a "
            + " where exists( select 'a' from limit_up b where a.gid = b.gid and dbo.func_GetLastTransactDate(a.alert_date, 1) = b.alert_date) "
            + " and not exists ( select 'a' from limit_up c where a.gid = c.gid and dbo.func_GetLastTransactDate(a.alert_date, 2) = c.alert_date )  "
            + " order by a.alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {

            bool newHigh = true;
            Stock s = GetStock(drOri["gid"].ToString().Trim());
            int currentIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (currentIndex + 6 >= s.kLineDay.Length)
            {
                continue;
            }

            if (s.kLineDay[currentIndex].volume <= s.kLineDay[currentIndex + 1].volume)
            {
                continue;
            }
            if (s.kLineDay[currentIndex].endPrice > s.kLineDay[currentIndex + 1].startPrice
                || s.kLineDay[currentIndex].endPrice > s.kLineDay[currentIndex + 1].endPrice)
            {
                continue;
            }

            if (s.IsLimitUp(currentIndex+1))
            {
                continue;
            }


            int buyIndex = currentIndex + 1;

            double buyPrice = s.kLineDay[currentIndex+1].endPrice;
            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[currentIndex + 1].endDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["买入"] = buyPrice.ToString();
            dr["缩量"] = Math.Round(100 * s.kLineDay[currentIndex + 1].volume / s.kLineDay[currentIndex].volume, 2).ToString() + "%";

            double finalRate = double.MinValue;
            for (int j = 1; j <= 5; j++)
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
                if (newHigh)
                {
                    newHighSuc++;
                }
                dr["总计"] = "<font color=red >" + Math.Round(finalRate * 100, 2).ToString() + "%</font>";
            }
            else
            {
                dr["总计"] = "<font color=green >" + Math.Round(finalRate * 100, 2).ToString() + "%</font>";
            }
            count++;
            if (newHigh)
            {
                newHighCount++;
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
            <!--创新高：<%=newHighCount.ToString() %> / <%=Math.Round((double)100*newHighSuc/(double)newHighCount, 2).ToString() %>-->
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