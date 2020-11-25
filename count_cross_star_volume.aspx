﻿<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public static Stock[] gidArr;

    public static Core.RedisClient rc = new Core.RedisClient("52.82.51.144");

    public string type = "success";

    protected void Page_Load(object sender, EventArgs e)
    {
        type = Util.GetSafeRequestValue(Request, "type", "success");

        FillStockArr();
        DataTable dtCount = new DataTable();
        dtCount.Columns.Add("放量");
        dtCount.Columns.Add("总个数");
        dtCount.Columns.Add("总利润");
        dtCount.Columns.Add("平均利润");

        DataRow drCount = dtCount.NewRow();
        drCount["放量"] = "<100%";
        drCount["总个数"] = "0";
        drCount["总利润"] = "0";
        drCount["平均利润"] = "0";
        dtCount.Rows.Add(drCount);

        drCount = dtCount.NewRow();
        drCount["放量"] = "100%-125%";
        drCount["总个数"] = "0";
        drCount["总利润"] = "0";
        drCount["平均利润"] = "0";
        dtCount.Rows.Add(drCount);

        drCount = dtCount.NewRow();
        drCount["放量"] = "125%-190%";
        drCount["总个数"] = "0";
        drCount["总利润"] = "0";
        drCount["平均利润"] = "0";
        dtCount.Rows.Add(drCount);

        drCount = dtCount.NewRow();
        drCount["放量"] = "190%-220%";
        drCount["总个数"] = "0";
        drCount["总利润"] = "0";
        drCount["平均利润"] = "0";
        dtCount.Rows.Add(drCount);

        drCount = dtCount.NewRow();
        drCount["放量"] = "220%-400%";
        drCount["总个数"] = "0";
        drCount["总利润"] = "0";
        drCount["平均利润"] = "0";
        dtCount.Rows.Add(drCount);

        drCount = dtCount.NewRow();
        drCount["放量"] = ">400%";
        drCount["总个数"] = "0";
        drCount["总利润"] = "0";
        drCount["平均利润"] = "0";
        dtCount.Rows.Add(drCount);

        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.DateTime"));
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("放量", Type.GetType("System.Double"));
        dt.Columns.Add("换手", Type.GetType("System.Double"));
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
        dtNew.Columns.Add("放量");
        dtNew.Columns.Add("换手");
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

            double volumeRate = s.kLineDay[currentIndex].volume / s.kLineDay[currentIndex - 1].volume;

            

            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[currentIndex].startDateTime.Date;
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["板数"] = limitUpNum;
            dr["放量"] = volumeRate;
            dr["换手"] = (double)s.kLineDay[currentIndex].volume / (double)s.TotalStockCount(s.kLineDay[currentIndex].startDateTime);
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
            if (type.Trim().Equals("fail"))
            {
                if (maxRate < 0.02)
                {
                    dt.Rows.Add(dr);
                }
            }
            else
            {
                if (maxRate >= 0.02)
                {
                    dt.Rows.Add(dr);
                }
            }

        }


        foreach (DataRow dr in dt.Select("", "日期 desc"))
        {
            DataRow drNew = dtNew.NewRow();
            foreach (DataColumn c in dt.Columns)
            {
                drNew[c.Caption] = dr[c].ToString();
            }

            int countIndex = 0;
            double volumeIncrease = double.Parse(drNew["放量"].ToString());
            if (volumeIncrease >= 1 && volumeIncrease < 1.25)
            {
                countIndex = 1;
            }
            else if (volumeIncrease >= 1.25 && volumeIncrease < 1.9)
            {
                countIndex = 2;
            }
            else if (volumeIncrease >= 1.9 && volumeIncrease < 2.2)
            {
                countIndex = 3;
            }
            else if (volumeIncrease >= 2.2 && volumeIncrease < 4)
            {
                countIndex = 4;
            }
            else if (volumeIncrease >= 4)
            {
                countIndex = 5;
            }
            else
            {
                countIndex = 0;
            }
            dtCount.Rows[countIndex]["总个数"] = (int.Parse(dtCount.Rows[countIndex]["总个数"].ToString()) + 1).ToString();
            dtCount.Rows[countIndex]["总利润"] = (double.Parse(dtCount.Rows[countIndex]["总利润"].ToString()) + double.Parse(drNew["总计"].ToString())).ToString();
            dtCount.Rows[countIndex]["平均利润"] = double.Parse(dtCount.Rows[countIndex]["总利润"].ToString()) / double.Parse(dtCount.Rows[countIndex]["总个数"].ToString());


            drNew["日期"] = ((DateTime)dr["日期"]).ToShortDateString();
            drNew["放量"] = Math.Round(100 * double.Parse(drNew["放量"].ToString()), 2).ToString() + "%";
            drNew["换手"] = Math.Round(100 * double.Parse(drNew["换手"].ToString()), 2).ToString() + "%";




            for (int i = 1; i <= 5; i++)
            {
                double rate = double.Parse(drNew[i.ToString()+"日"].ToString());
                drNew[i.ToString()+"日"] = "<font color=\"" + (rate >= 0.01 ? "red" : "green") + "\" >" + Math.Round((rate * 100), 2)+"%</font>";
            }
            double rateTotal = double.Parse(drNew["总计"].ToString());
            drNew["总计"] = "<font color=\"" + (rateTotal >= 0.01 ? "red" : "green") + "\" >" + Math.Round((rateTotal * 100), 2)+"%</font>";
            dtNew.Rows.Add(drNew);
        }

        for (int i = 0; i < dtCount.Rows.Count; i++)
        {
            dtCount.Rows[i]["总利润"] = Math.Round(100 * double.Parse(dtCount.Rows[i]["总利润"].ToString()), 2).ToString() + "%";
            dtCount.Rows[i]["平均利润"] = Math.Round(100 * double.Parse(dtCount.Rows[i]["平均利润"].ToString()), 2).ToString() + "%";
        }


        dgCount.DataSource = dtCount;
        dgCount.DataBind();

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
        <asp:DataGrid runat="server" Width="100%" ID="dgCount" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
            <AlternatingItemStyle BackColor="#DCDCDC" />
            <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
            <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
            <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
            <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
            <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
        </asp:DataGrid>
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
