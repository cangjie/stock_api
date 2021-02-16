<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public static Core.RedisClient rc = new Core.RedisClient("52.81.252.140");

    public  int suc = 0;
    public  int sucMax = 0;
    public  int count = 0;
    public int horseHeadSuc = 0;
    public int horseHeadCount = 0;
    public int giveUpCount = 0;
    public int totalCount = 0;


    protected void Page_Load(object sender, EventArgs e)
    {



        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.DateTime"));
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("信号");
        dt.Columns.Add("缩量");
        dt.Columns.Add("买入");
        dt.Columns.Add("今涨", Type.GetType("System.Double"));

        dt.Columns.Add("1日", Type.GetType("System.Double"));
        dt.Columns.Add("2日", Type.GetType("System.Double"));
        dt.Columns.Add("3日", Type.GetType("System.Double"));
        dt.Columns.Add("4日", Type.GetType("System.Double"));
        dt.Columns.Add("5日", Type.GetType("System.Double"));
        dt.Columns.Add("6日", Type.GetType("System.Double"));
        dt.Columns.Add("7日", Type.GetType("System.Double"));
        dt.Columns.Add("8日", Type.GetType("System.Double"));
        dt.Columns.Add("9日", Type.GetType("System.Double"));
        dt.Columns.Add("10日", Type.GetType("System.Double"));
        dt.Columns.Add("总计", Type.GetType("System.Double"));


        DataTable dtNew = new DataTable();
        dtNew.Columns.Add("日期");
        dtNew.Columns.Add("代码");
        dtNew.Columns.Add("名称");
        dtNew.Columns.Add("信号");
        dtNew.Columns.Add("缩量");
        dtNew.Columns.Add("今涨");
        dtNew.Columns.Add("买入");
        dtNew.Columns.Add("1日");
        dtNew.Columns.Add("2日");
        dtNew.Columns.Add("3日");
        dtNew.Columns.Add("4日");
        dtNew.Columns.Add("5日");
        dtNew.Columns.Add("6日");
        dtNew.Columns.Add("7日");
        dtNew.Columns.Add("8日");
        dtNew.Columns.Add("9日");
        dtNew.Columns.Add("10日");
        dtNew.Columns.Add("总计");



        DataTable dtOri = DBHelper.GetDataTable(" select distinct  alert_ma5_line3_gold_cross.alert_date, alert_ma5_line3_gold_cross.gid from alert_ma5_line3_gold_cross  "
            + " join alert_traffic_light on alert_traffic_light.gid = alert_ma5_line3_gold_cross.gid  "
            + "  and alert_traffic_light.alert_date >= dbo.func_GetLastTransactDate(alert_ma5_line3_gold_cross.alert_date, 10) and alert_traffic_light.alert_date < alert_ma5_line3_gold_cross.alert_date "
            + " where alert_ma5_line3_gold_cross.alert_date <= '2021-1-25' "
            //+ " and alert_ma5_line3_gold_cross.alert_date = '2020-8-17' and alert_ma5_line3_gold_cross.gid = 'sh600496' "
            + " order by alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {

            try
            {
                Stock s = GetStock(drOri["gid"].ToString().Trim());
                int currentIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
                if (currentIndex < 0)
                {
                    continue;
                }
                if (currentIndex <= 10)
                {
                    continue;
                }
                double current5Line = s.GetAverageSettlePrice(currentIndex, 5, 5);
                double current3Line = s.GetAverageSettlePrice(currentIndex, 3, 3);
                double currentMa5 = s.GetAverageSettlePrice(currentIndex, 5, 0);
                double last5Line = s.GetAverageSettlePrice(currentIndex - 1, 5, 5);
                double last3Line = s.GetAverageSettlePrice(currentIndex - 1, 3, 3);
                double lastMa5 = s.GetAverageSettlePrice(currentIndex - 1, 5, 0);
                double lastPrice = s.kLineDay[currentIndex - 1].endPrice;
                double lastStart = s.kLineDay[currentIndex - 1].startPrice;
                double nextPrice = s.kLineDay[currentIndex + 1].endPrice;
                double next5Line = s.GetAverageSettlePrice(currentIndex + 1, 5, 5);
                double nextMa5 = s.GetAverageSettlePrice(currentIndex + 1, 5, 0);
                double next3Line = s.GetAverageSettlePrice(currentIndex + 1, 3, 3);
                double currentPrice = s.kLineDay[currentIndex].endPrice;
                double currentStart = s.kLineDay[currentIndex].startPrice;
                double nextStart = s.kLineDay[currentIndex + 1].startPrice;

                if (last5Line >= current5Line || current5Line >= next5Line)
                {
                    continue;
                }
                if (last5Line >= lastMa5 || current5Line >= currentMa5 || next5Line >= nextMa5)
                {
                    continue;
                }
                if (lastMa5 > last3Line || currentMa5 < current3Line || nextMa5 <= next3Line)
                {
                    continue;
                }
                if (lastPrice > Math.Min(currentPrice, nextPrice) || currentPrice > nextPrice
                    || lastStart >= lastPrice || currentStart >= currentPrice || nextStart >= nextPrice)
                {
                    continue;
                }
                if (nextPrice <= nextMa5 || nextPrice <= next3Line || nextPrice <= next5Line)
                {
                    continue;
                }
                /*
                double currentRise = (s.kLineDay[currentIndex].endPrice - s.kLineDay[currentIndex - 1].endPrice) / s.kLineDay[currentIndex - 1].endPrice;
                if (currentRise <= 0.03)
                {
                    continue;
                }
                */
                /*
                if (s.kLineDay[currentIndex - 1].endPrice <= s.kLineDay[currentIndex - 1].startPrice
                    || s.kLineDay[currentIndex].endPrice <= s.kLineDay[currentIndex].startPrice
                    || s.kLineDay[currentIndex+1].endPrice <= s.kLineDay[currentIndex+1].startPrice
                    || s.kLineDay[currentIndex - 1].endPrice >= s.kLineDay[currentIndex].endPrice
                    || s.kLineDay[currentIndex].endPrice >= s.kLineDay[currentIndex+1].endPrice)
                {
                    continue;
                }
                */



                int buyIndex = currentIndex + 1;



                if (dt.Select(" 日期 = '" + s.kLineDay[buyIndex].startDateTime.Date.ToShortDateString() + "' and 代码 = '" + s.gid.Trim() + "' ").Length == 0)
                {
                    DataRow dr = dt.NewRow();
                    dr["日期"] = s.kLineDay[buyIndex].startDateTime.Date;
                    dr["代码"] = s.gid.Trim();
                    dr["名称"] = s.Name.Trim();
                    dr["信号"] = "";
                    dr["缩量"] = Math.Round(100 * s.kLineDay[currentIndex + 1].volume / s.kLineDay[currentIndex].volume, 2).ToString() + "%";
                    double width = (s.kLineDay[buyIndex].highestPrice - s.kLineDay[buyIndex-2].lowestPrice)/s.kLineDay[buyIndex-2].lowestPrice;
                    if (width <= 0.1)
                    {
                        continue;
                    }
                    dr["今涨"] = width;
                    double buyPrice = s.kLineDay[buyIndex].endPrice;
                    dr["买入"] = Math.Round(buyPrice, 2).ToString();
                    bool over5Percent = false;
                    double maxPrice = 0;
                    bool giveUp = false;
                    for (int i = 1; i <= 10; i++)
                    {

                        maxPrice = Math.Max(maxPrice, s.kLineDay[buyIndex + i].endPrice);
                        dr[i.ToString() + "日"] = (s.kLineDay[buyIndex + i].endPrice - buyPrice) / buyPrice;
                        if ((s.kLineDay[buyIndex + i].highestPrice - buyPrice) / buyPrice >= 0.05 && !over5Percent)
                        {
                            dr[i.ToString() + "日"] = (s.kLineDay[buyIndex + i].highestPrice - buyPrice) / buyPrice;
                            maxPrice = Math.Max(maxPrice, s.kLineDay[buyIndex + i].highestPrice);
                            over5Percent = true;
                            //sucMax++;
                        }
                        if (i == 1 && (s.kLineDay[buyIndex + i].endPrice - buyPrice) / buyPrice <= -0.01 && !over5Percent )
                        {
                            giveUp = true;
                            //break;
                        }

                    }
                    dr["总计"] = (maxPrice - buyPrice) / buyPrice;
                    if ((double)dr["总计"] >= 0.01)
                    {
                        suc++;
                        if ((double)dr["总计"] >= 0.05)
                        {
                            sucMax++;
                        }
                    }
                    totalCount++;
                    if (giveUp)
                    {
                        giveUpCount++;
                    }
                    dt.Rows.Add(dr);


                }
            }
            catch
            {

            }
        }

        count = dt.Rows.Count;

        //DataTable dtNew = dt.Clone();
        foreach (DataRow dr in dt.Select("", "日期 desc"))
        {
            DataRow drNew = dtNew.NewRow();
            foreach (DataColumn c in dt.Columns)
            {
                if (c.DataType.FullName.ToString().Equals("System.Double"))
                {
                    try
                    {
                        double value = double.Parse(dr[c].ToString());
                        drNew[c.Caption] = "<font color='" + ((value < 0.01) ? "green" : "red") + "' >"
                            + Math.Round(100 * value, 2).ToString() + "%</font>";
                    }
                    catch
                    {

                    }
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
    <div>收盘涨幅过1%概率：<%= Math.Round(100*(double)suc/(double)count, 2).ToString() %>%</div>
    <div>盘中涨幅过5%概率：<%= Math.Round(100*(double)sucMax/(double)count, 2).ToString() %>%</div>
    <div>首日赔钱止损概率：<%= Math.Round(100*(double)giveUpCount/(double)totalCount, 2).ToString() %>%</div>
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
