﻿<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public static Stock[] gidArr;

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    public static int highCount = 0;

    public static int highSuccess = 0;

    public static int lowCount = 0;

    public static int lowSuccess = 0;

    protected void Page_Load(object sender, EventArgs e)
    {

        FillStockArr();

        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.DateTime"));
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("板数", Type.GetType("System.Int32"));
        dt.Columns.Add("1日");
        dt.Columns.Add("2日");
        dt.Columns.Add("3日");
        dt.Columns.Add("4日");
        dt.Columns.Add("5日");
        dt.Columns.Add("总计");

        DataTable dtNew = new DataTable();
        dtNew.Columns.Add("日期");
        dtNew.Columns.Add("代码");
        dtNew.Columns.Add("名称");
        dtNew.Columns.Add("板数");
        dtNew.Columns.Add("1日");
        dtNew.Columns.Add("2日");
        dtNew.Columns.Add("3日");
        dtNew.Columns.Add("4日");
        dtNew.Columns.Add("5日");
        dtNew.Columns.Add("总计");


        DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up where next_day_cross_star_un_limit_up = 1 and alert_date <= '2019-10-24' order by alert_date desc");
        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock s = GetStock(drOri["gid"].ToString().Trim());
            int currentIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (currentIndex < 0)
            {
                continue;
            }
            if (currentIndex + 6 >= s.kLineDay.Length)
            {
                continue;
            }
            currentIndex++;
            int limitUpNum = 0;
            for (int i = currentIndex - 1; i > 0 && s.kLineDay[currentIndex].endPrice >= s.GetAverageSettlePrice(i, 3, 3); i--)
            {
                if (s.IsLimitUp(i))
                {
                    limitUpNum++;
                }
            }
            if (limitUpNum <= 0)
            {
                continue;
            }
           
            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[currentIndex].startDateTime.Date;
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["板数"] = limitUpNum;
            double maxRate = -100;
            double buyPrice = s.kLineDay[currentIndex].endPrice;
            for (int i = 1; i <= 5; i++)
            {
                double rate = (s.kLineDay[currentIndex + i].highestPrice - buyPrice) / buyPrice;
                maxRate = Math.Max(maxRate, rate);
                //dr[i.ToString() + "日"] = "<font color=\"" + (rate >= 0.01 ? "red" : "green") + "\" >" + Math.Round((rate * 100), 2)+"%</font>";
                dr[i.ToString() + "日"] = rate;
            }
            //dr["总计"] = "<font color=\"" + (maxRate >= 0.01 ? "red" : "green") + "\" >" + Math.Round((maxRate * 100), 2)+"%</font>";
            dr["总计"] = maxRate;


            if ( (s.kLineDay[currentIndex].endPrice - s.kLineDay[currentIndex-1].endPrice) / s.kLineDay[currentIndex-1].endPrice >= 0.04)
            {
                highCount++;
                if (maxRate >= 0.05)
                {
                    highSuccess++;
                }
            }
            else
            {
                lowCount++;
                if (maxRate >= 0.05)
                {
                    lowSuccess++;
                }
            }
           


            dt.Rows.Add(dr);
        }



        //DataTable dtNew = dt.Clone();
        foreach (DataRow dr in dt.Select("", "日期 desc"))
        {
            DataRow drNew = dtNew.NewRow();
            foreach (DataColumn c in dt.Columns)
            {
                drNew[c.Caption] = dr[c].ToString();
            }
            drNew["日期"] = ((DateTime)dr["日期"]).ToShortDateString();


            for (int i = 1; i <= 5; i++)
            {
                double rate = double.Parse(drNew[i.ToString()+"日"].ToString());
                drNew[i.ToString()+"日"] = "<font color=\"" + (rate >= 0.01 ? "red" : "green") + "\" >" + Math.Round((rate * 100), 2)+"%</font>";
            }
            double rateTotal = double.Parse(drNew["总计"].ToString());
            drNew["总计"] = "<font color=\"" + (rateTotal >= 0.01 ? "red" : "green") + "\" >" + Math.Round((rateTotal * 100), 2)+"%</font>";
            dtNew.Rows.Add(drNew);
        }


        dg.DataSource = dtNew;
        dg.DataBind();

    }

    public void FillStockArr()
    {
        DataTable dt = DBHelper.GetDataTable(" select distinct gid from limit_up where next_day_cross_star_un_limit_up = 1 ");
        gidArr = new Stock[dt.Rows.Count];
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            gidArr[i] = new Stock(dt.Rows[i][0].ToString().Trim());
            gidArr[i].LoadKLineDay(rc);
        }
    }

    public Stock GetStock(string gid)
    {
        Stock s = new Stock();
        foreach (Stock st in gidArr)
        {
            if (st.gid.Trim().Equals(gid))
            {
                s = st;
                break;
            }
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
        涨：<%=highSuccess.ToString() %> / <%=highCount.ToString() %> = <%=Math.Round(100 * (double)highSuccess/highCount, 2).ToString() %>%<br />
        跌：<%=lowSuccess.ToString() %> / <%=lowCount.ToString() %> = <%=Math.Round(100 * (double)lowSuccess/lowCount, 2).ToString() %>%<br />
        <asp:DataGrid runat="server" Width="100%" ID="dg" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
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