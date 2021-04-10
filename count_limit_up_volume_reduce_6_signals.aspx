<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    public int line3Count = 0;
    public int line3Suc2Great = 0;
    public int line3Suc5Great = 0;
    public int line3Suc2 = 0;
    public int line3Suc5 = 0;

    public int f3Count = 0;
    public int f3Suc2 = 0;
    public int f3Suc5 = 0;
    public int f3Suc2Great = 0;
    public int f3Suc5Great = 0;


    public int f5Count = 0;
    public int f5Suc2 = 0;
    public int f5Suc5 = 0;
    public int f5Suc2Great = 0;
    public int f5Suc5Great = 0;


    public int newHighCount = 0;
    public int newHighSuc2 = 0;
    public int newHighSuc5 = 0;
    public int newHighSuc2Great = 0;
    public int newHighSuc5Great = 0;

    public int limit2Count = 0;
    public int limit2Suc2 = 0;
    public int limit2Suc5 = 0;
    public int limit2Suc2Great = 0;
    public int limit2Suc5Great = 0;

    public int horseHeadCount = 0;
    public int horseHeadSuc2 = 0;
    public int horseHeadSuc5 = 0;
    public int horseHeadSuc2Great = 0;
    public int horseHeadSuc5Great = 0;

    protected void Page_Load(object sender, EventArgs e)
    {



        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.DateTime"));
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("信号");
        dt.Columns.Add("缩量");
        dt.Columns.Add("买入");
        //dt.Columns.Add("高开幅度", Type.GetType("System.Double"));

        dt.Columns.Add("1日", Type.GetType("System.Double"));
        dt.Columns.Add("2日", Type.GetType("System.Double"));
        dt.Columns.Add("3日", Type.GetType("System.Double"));
        dt.Columns.Add("4日", Type.GetType("System.Double"));
        dt.Columns.Add("5日", Type.GetType("System.Double"));
        dt.Columns.Add("总计", Type.GetType("System.Double"));


        DataTable dtNew = new DataTable();
        dtNew.Columns.Add("日期");
        dtNew.Columns.Add("代码");
        dtNew.Columns.Add("名称");
        dtNew.Columns.Add("信号");
        dtNew.Columns.Add("缩量");
        //dtNew.Columns.Add("高开幅度");
        dtNew.Columns.Add("买入");
        dtNew.Columns.Add("1日");
        dtNew.Columns.Add("2日");
        dtNew.Columns.Add("3日");
        dtNew.Columns.Add("4日");
        dtNew.Columns.Add("5日");
        dtNew.Columns.Add("总计");



        DataTable dtOri = DBHelper.GetDataTable(" select  alert_date, gid from limit_up_volume_reduce   order by alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {
            string sigal = "";
            try
            {
                Stock s = GetStock(drOri["gid"].ToString().Trim());
                int currentIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
                if (currentIndex < 2)
                {
                    continue;
                }

                if (currentIndex + 7 >= s.kLineDay.Length)
                {
                    continue;
                }

                if (s.kLineDay[currentIndex].volume  > s.kLineDay[currentIndex - 1].volume)
                {
                    continue;
                }

                double high = Math.Max(s.kLineDay[currentIndex].highestPrice, s.kLineDay[currentIndex - 1].highestPrice);
                double low = Math.Min(s.kLineDay[currentIndex].lowestPrice, s.kLineDay[currentIndex - 1].lowestPrice);
                double f3 = high - (high - low) * 0.382;
                double f5 = high - (high - low) * 0.618;
                int buyIndex = currentIndex;

                if (s.kLineDay[currentIndex].lowestPrice < f5 && s.kLineDay[currentIndex].endPrice > f5)
                {
                    sigal = "F5";
                    f5Count++;
                }
                else if (s.kLineDay[currentIndex].lowestPrice < f3 && s.kLineDay[currentIndex].endPrice > f3)
                {
                    sigal = "F3";
                    f3Count++;
                }
                double current3Line = s.GetAverageSettlePrice(currentIndex, 3, 3);
                double next3Line =  s.GetAverageSettlePrice(currentIndex+1, 3, 3);
                if (s.kLineDay[currentIndex].lowestPrice < current3Line && s.kLineDay[currentIndex].endPrice > current3Line)
                {
                    sigal = sigal + "3⃣️";
                    line3Count++;
                }
                if(s.kLineDay[currentIndex + 1].lowestPrice < next3Line && s.kLineDay[currentIndex + 1].endPrice > next3Line)
                {
                    buyIndex = currentIndex + 1;
                    if (sigal.IndexOf("3⃣️") < 0)
                    {
                        sigal = sigal + "3⃣️";
                        line3Count++;
                    }
                }
                if (s.kLineDay[currentIndex + 1].endPrice > high)
                {
                    buyIndex = currentIndex + 1;
                    sigal = sigal + "<a title=\"新高\" >📈</a>";
                    newHighCount++;
                }
                if (s.kLineDay[currentIndex].startPrice > s.kLineDay[currentIndex - 1].endPrice
                    && s.kLineDay[currentIndex].endPrice > s.kLineDay[currentIndex - 1].endPrice)
                {
                    sigal = sigal + "🐴";
                    horseHeadCount++;
                }
                if (s.IsLimitUp(currentIndex - 2))
                {
                    sigal = sigal + "<a title=\"连板\" >🚩</a>";
                    limit2Count++;
                }
                if (!sigal.Trim().Equals("") && dt.Select(" 日期 = '" + s.kLineDay[currentIndex+2].startDateTime.Date.ToShortDateString() + "' and 代码 = '" + s.gid.Trim() + "' ").Length == 0)
                {
                    DataRow dr = dt.NewRow();
                    dr["日期"] = s.kLineDay[buyIndex].startDateTime.Date;
                    dr["代码"] = s.gid.Trim();
                    dr["名称"] = s.Name.Trim();
                    dr["信号"] = sigal.Trim();
                    dr["缩量"] = Math.Round(100 * s.kLineDay[currentIndex].volume / s.kLineDay[currentIndex-1].volume, 2).ToString() + "%";
                    //dr["高开幅度"] = (s.kLineDay[currentIndex + 2].startPrice - s.kLineDay[currentIndex + 1].endPrice) / s.kLineDay[currentIndex + 1].endPrice;
                    double buyPrice = s.kLineDay[buyIndex].endPrice;
                    dr["买入"] = Math.Round(buyPrice, 2).ToString();

                    double maxPrice = 0;
                    for (int i = 1; i <= 5; i++)
                    {
                        maxPrice = Math.Max(maxPrice, s.kLineDay[buyIndex + i].highestPrice);
                        double rate = (s.kLineDay[buyIndex + i].highestPrice - buyPrice) / buyPrice;
                        dr[i.ToString() + "日"] = rate;
                        if (i == 1 && rate >= 0.01)
                        {
                            if (sigal.IndexOf("F3") >= 0)
                            {
                                f3Suc2++;
                            }
                            if (sigal.IndexOf("F5") >= 0)
                            {
                                f5Suc2++;
                            }
                            if (sigal.IndexOf("3⃣️") >= 0)
                            {
                                line3Suc2++;
                            }
                            if (sigal.IndexOf("📈") >= 0)
                            {
                                newHighSuc2++;
                            }
                            if (sigal.IndexOf("🐴") >= 0)
                            {
                                horseHeadSuc2++;
                            }
                            if (sigal.IndexOf("🚩") >= 0)
                            {
                                limit2Suc2++;
                            }
                        }
                        if (i == 1 && rate >= 0.05)
                        {
                            if (sigal.IndexOf("F3") >= 0)
                            {
                                f3Suc2Great++;
                            }
                            if (sigal.IndexOf("F5") >= 0)
                            {
                                f5Suc2Great++;
                            }
                            if (sigal.IndexOf("3⃣️") >= 0)
                            {
                                line3Suc2Great++;
                            }
                            if (sigal.IndexOf("📈") >= 0)
                            {
                                newHighSuc2Great++;
                            }
                            if (sigal.IndexOf("🐴") >= 0)
                            {
                                horseHeadSuc2Great++;
                            }
                            if (sigal.IndexOf("🚩") >= 0)
                            {
                                limit2Suc2Great++;
                            }
                        }


                    }
                    double allRate = (maxPrice - buyPrice) / buyPrice;
                    dr["总计"] = allRate;
                    if (allRate >= 0.01)
                    { 
                        if (sigal.IndexOf("F3") >= 0)
                        {
                            f3Suc5++;
                        }
                        if (sigal.IndexOf("F5") >= 0)
                        {
                            f5Suc5++;
                        }
                        if (sigal.IndexOf("3⃣️") >= 0)
                        {
                            line3Suc5++;
                        }
                        if (sigal.IndexOf("📈") >= 0)
                        {
                            newHighSuc5++;
                        }
                        if (sigal.IndexOf("🐴") >= 0)
                        {
                            horseHeadSuc5++;
                        }
                        if (sigal.IndexOf("🚩") >= 0)
                        {
                            limit2Suc5++;
                        }
                    }
                    if (allRate >= 0.05)
                    { 
                        if (sigal.IndexOf("F3") >= 0)
                        {
                            f3Suc5Great++;
                        }
                        if (sigal.IndexOf("F5") >= 0)
                        {
                            f5Suc5Great++;
                        }
                        if (sigal.IndexOf("3⃣️") >= 0)
                        {
                            line3Suc5Great++;
                        }
                        if (sigal.IndexOf("📈") >= 0)
                        {
                            newHighSuc5Great++;
                        }
                        if (sigal.IndexOf("🐴") >= 0)
                        {
                            horseHeadSuc5Great++;
                        }
                        if (sigal.IndexOf("🚩") >= 0)
                        {
                            limit2Suc5Great++;
                        }
                    }
                    dt.Rows.Add(dr);
                }
            }
            catch
            {

            }
        }


        //DataTable dtNew = dt.Clone();
        foreach (DataRow dr in dt.Select("", "日期 desc"))
        {
            DataRow drNew = dtNew.NewRow();
            foreach (DataColumn c in dt.Columns)
            {
                if (c.DataType.FullName.ToString().Equals("System.Double"))
                {
                    double value = double.Parse(dr[c].ToString());
                    drNew[c.Caption] = "<font color='" + ((value < 0.01) ? "green" : "red") + "' >"
                        + Math.Round(100 * value, 2).ToString() + "%</font>";
                }
                else
                {
                    drNew[c.Caption] = dr[c].ToString();
                }
            }
            drNew["日期"] = ((DateTime)dr["日期"]).ToShortDateString();
            dtNew.Rows.Add(drNew);
        }


        dg.DataSource = dtNew;
        dg.DataBind();

    }



    public Stock GetStock(string gid)
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
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        3线：下1日：过1%：<% =Math.Round((double)100*line3Suc2/line3Count, 2).ToString() %>% 过5%：<% =Math.Round((double)100*line3Suc2Great/line3Count, 2).ToString() %>%
        下5日：过1%：<% =Math.Round((double)100*line3Suc5/line3Count, 2).ToString() %>% 过5%：<% =Math.Round((double)100*line3Suc5Great/line3Count, 2).ToString() %>%
    </div>
    <div>
        F5：下1日：过1%：<% =Math.Round((double)100* f5Suc2 / f5Count, 2).ToString() %>% 过5%：<% =Math.Round((double)100* f5Suc2Great / f5Count , 2).ToString() %>%
        下5日：过1%：<% =Math.Round((double)100* f5Suc5 / f5Count , 2).ToString() %>% 过5%：<% =Math.Round((double)100* f5Suc5Great / f5Count , 2).ToString() %>%
    </div>
    <div>
        F3：下1日：过1%：<% =Math.Round((double)100* f3Suc2 / f3Count, 2).ToString() %>% 过5%：<% =Math.Round((double)100* f3Suc2Great / f3Count , 2).ToString() %>%
        下5日：过1%：<% =Math.Round((double)100* f3Suc5 / f3Count , 2).ToString() %>% 过5%：<% =Math.Round((double)100* f3Suc5Great / f3Count , 2).ToString() %>%
    </div>
    <div>
        新高：下1日：过1%：<% =Math.Round((double)100* newHighSuc2 / newHighCount, 2).ToString() %>% 过5%：<% =Math.Round((double)100* newHighSuc2Great / newHighCount , 2).ToString() %>%
        下5日：过1%：<% =Math.Round((double)100* newHighSuc5 / newHighCount , 2).ToString() %>% 过5%：<% =Math.Round((double)100* newHighSuc5Great / newHighCount , 2).ToString() %>%
    </div>
    <div>
        马头：下1日：过1%：<% =Math.Round((double)100* horseHeadSuc2 / horseHeadCount, 2).ToString() %>% 过5%：<% =Math.Round((double)100* horseHeadSuc2Great / horseHeadCount , 2).ToString() %>%
        下5日：过1%：<% =Math.Round((double)100* horseHeadSuc5 / horseHeadCount , 2).ToString() %>% 过5%：<% =Math.Round((double)100* horseHeadSuc5Great / horseHeadCount , 2).ToString() %>%
    </div>
    <div>
        连板：下1日：过1%：<% =Math.Round((double)100* limit2Suc2 / limit2Count, 2).ToString() %>% 过5%：<% =Math.Round((double)100* limit2Suc2Great / limit2Count , 2).ToString() %>%
        下5日：过1%：<% =Math.Round((double)100* limit2Suc5 / limit2Count , 2).ToString() %>% 过5%：<% =Math.Round((double)100* limit2Suc5Great / limit2Count , 2).ToString() %>%
    </div>
    <div>
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
