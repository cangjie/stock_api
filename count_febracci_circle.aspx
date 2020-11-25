<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    //public static Stock[] gidArr;

    //public static Core.RedisClient rc = new Core.RedisClient("52.81.252.140");

    public static int count = 0;

    public static int success5 = 0;

    public static int success2 = 0;

    public static int success1 = 0;

    public static int fail = 0;


    protected void Page_Load(object sender, EventArgs e)
    {



        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.DateTime"));
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
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
        //string[] gidArr = new string[] { "sz002838"};//Util.GetAllGids();
        string[] gidArr = Util.GetAllGids();
        //foreach (Stock s  in gidArr)
        for(int m = 0; m < gidArr.Length; m++)
        {
            Stock s = new Stock(gidArr[m].Trim());
            s.LoadKLineDay(Util.rc);
            for (int i = 0; i < s.kLineDay.Length - 16; i++)
            {
                if (!s.IsLimitUp(i))
                {
                    continue;
                }
                if (!s.IsLimitUp(i + 1))
                {
                    continue;
                }
                if (s.IsLimitUp(i + 7) && s.kLineDay[i + 7].highestPrice == s.kLineDay[i + 7].lowestPrice)
                {
                    continue;
                }
                bool fistTwiceLimitUp = true;
                if (s.kLineDay[i].endPrice > s.GetAverageSettlePrice(i, 3, 3))
                {
                    for (int j = i; j >= 0 && s.kLineDay[j].endPrice >= s.GetAverageSettlePrice(j, 3, 3) && fistTwiceLimitUp ; j--)
                    {
                        if (s.IsLimitUp(j))
                        {
                            fistTwiceLimitUp = false;
                        }
                    }
                }
                if (!fistTwiceLimitUp)
                {
                    //continue;
                }

                if (!s.IsLimitUp(i + 3) || !s.IsLimitUp(i + 5) || !s.IsLimitUp(i + 6))
                {
                    continue;
                }
                if (s.kLineDay[i + 2].volume / s.TotalStockCount(s.kLineDay[i + 2].startDateTime.Date) >= 0.3
                    || s.kLineDay[i + 4].volume / s.TotalStockCount(s.kLineDay[i + 4].startDateTime.Date) >= 0.3
                    || s.kLineDay[i + 7].volume / s.TotalStockCount(s.kLineDay[i + 7].startDateTime.Date) >= 0.3)
                {
                    continue;
                }
                double buyPrice = s.kLineDay[i + 7].endPrice;
                double maxPrice = Math.Max(Math.Max(s.kLineDay[i + 8].highestPrice,
                    s.kLineDay[i + 9].highestPrice), s.kLineDay[i + 10].highestPrice);
                double rate = (maxPrice - buyPrice) / buyPrice;
                if (rate >= 0.3)
                {
                    success1++;
                }
                else if (rate >= 0.2)
                {
                    success2++;
                }
                else if (rate >= 0.1)
                {
                    success5++;
                }
                DataRow dr = dt.NewRow();
                dr["日期"] = s.kLineDay[i+7].startDateTime.Date;
                dr["代码"] = s.gid.Trim();
                dr["名称"] = s.Name.Trim();
                dr["买入"] = buyPrice;
                double maxRate = double.MinValue;
                for (int k = 1; k <= 5; k++)
                {
                    rate = (s.kLineDay[i + 7 + k].highestPrice - buyPrice) / buyPrice;
                    maxRate = Math.Max(maxRate, rate);
                    dr[k.ToString() + "日"] = rate;
                }
                dr["总计"] = maxRate;
                dt.Rows.Add(dr);

            }

        }

        count = dt.Rows.Count;


        //DataTable dtNew = dt.Clone();
        string lastDateString = "";
        string lastGid = "";
        foreach (DataRow dr in dt.Select("", "日期 desc"))
        {
            //if (dtNew.Rows[dtNew.Rows.Count - 1]["日期"].ToString()
            if (lastDateString.Trim().Equals(((DateTime)dr["日期"]).ToShortDateString()) && lastGid.Trim().Equals(dr["代码"].ToString()))
            {
                continue;
            }
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
            if (rateTotal < 0.01)
            {
                fail++;
            }
            lastDateString = ((DateTime)dr["日期"]).ToShortDateString();
            lastGid = dr["代码"].ToString();
        }


        dg.DataSource = dtNew;
        dg.DataBind();

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
        1板：<%=success5.ToString() %> / <%=count.ToString() %> = <%=Math.Round(100 * (double)success5/count, 2).ToString() %>%<br />
        2板：<%=success2.ToString() %> / <%=count.ToString() %> = <%=Math.Round(100 * (double)success2/count, 2).ToString() %>%<br />
        3板：<%=success1.ToString() %> / <%=count.ToString() %> = <%=Math.Round(100 * (double)success1/count, 2).ToString() %>%<br />
        失败：<%=fail.ToString() %> / <%=count.ToString() %> = <%=Math.Round(100 * (double)fail/count, 2).ToString() %>%<br />
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
