<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public static Stock[] gidArr;

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    public static int count = 0;

    public static int success5 = 0;

    public static int success2 = 0;

    public static int success1 = 0;


    protected void Page_Load(object sender, EventArgs e)
    {

        FillStockArr();

        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.DateTime"));
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("昨收");
        dt.Columns.Add("买入");
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
        dtNew.Columns.Add("昨收");
        dtNew.Columns.Add("买入");
        dtNew.Columns.Add("1日");
        dtNew.Columns.Add("2日");
        dtNew.Columns.Add("3日");
        dtNew.Columns.Add("4日");
        dtNew.Columns.Add("5日");
        dtNew.Columns.Add("总计");

        success1 = 0;
        success2 = 0;
        success5 = 0;
        //DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up where next_day_cross_star_un_limit_up = 1 and alert_date <= '2019-10-24' order by alert_date desc");
        foreach (Stock s  in gidArr)
        {

            for (int i = s.kLineDay.Length - 11; i >= 3; i--)
            {
                if (s.IsLimitUp(i - 1)
                    && s.kLineDay[i].lowestPrice > s.kLineDay[i-1].endPrice
                    && (s.kLineDay[i].lowestPrice - s.kLineDay[i-1].endPrice) / s.kLineDay[i-1].endPrice <= 0.0975)
                {
                    double maxPrice = s.kLineDay[i].highestPrice;
                    for (int j = i + 1; j <= i + 5; j++)
                    {
                        if (s.kLineDay[j].startPrice >= maxPrice
                            && (s.kLineDay[j].startPrice - s.kLineDay[j-1].endPrice) / s.kLineDay[j-1].endPrice <= 0.0975)
                        {
                            maxPrice = Math.Max(maxPrice, s.kLineDay[j].highestPrice);
                            DataRow dr = dt.NewRow();
                            dr["日期"] = s.kLineDay[j].startDateTime.Date;
                            dr["代码"] = s.gid.Trim();
                            dr["名称"] = s.Name.Trim();
                            dr["昨收"] = Math.Round(s.kLineDay[j - 1].endPrice, 2);

                            double buyPrice = s.kLineDay[j].startPrice;
                            dr["买入"] = Math.Round(buyPrice, 2);
                            double maxRate = double.MinValue;
                            for (int k = 1; k <= 5; k++)
                            {
                                double rate = (s.kLineDay[k + j].highestPrice - buyPrice) / buyPrice;
                                maxRate = Math.Max(maxRate, rate);
                                dr[k.ToString() + "日"] = rate;

                            }
                            dr["总计"] = maxRate;

                            dt.Rows.Add(dr);
                            break;
                        }
                    }



                }
            }


        }

        count = dt.Rows.Count;


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
            if (rateTotal >= 0.05)
            {
                success5++;
            }
            if (rateTotal >= 0.02)
            {
                success2++;
            }
            if (rateTotal >= 0.01)
            {
                success1++;
            }
            drNew["总计"] = "<font color=\"" + (rateTotal >= 0.01 ? "red" : "green") + "\" >" + Math.Round((rateTotal * 100), 2)+"%</font>";
            dtNew.Rows.Add(drNew);
        }


        dg.DataSource = dtNew;
        dg.DataBind();

    }

    public void FillStockArr()
    {
        DataTable dt = DBHelper.GetDataTable(" select distinct gid from limit_up ");
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
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <%=success5.ToString() %> / <%=count.ToString() %> = <%=Math.Round(100 * (double)success5/count, 2).ToString() %>%<br />
        <%=success2.ToString() %> / <%=count.ToString() %> = <%=Math.Round(100 * (double)success2/count, 2).ToString() %>%<br />
        <%=success1.ToString() %> / <%=count.ToString() %> = <%=Math.Round(100 * (double)success1/count, 2).ToString() %>%<br />
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
