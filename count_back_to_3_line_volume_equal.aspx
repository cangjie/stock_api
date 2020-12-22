<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public static Core.RedisClient rc = new Core.RedisClient("52.81.252.140");

    public static int highCount = 0;

    public static int highSuccess = 0;

    public static int lowCount = 0;

    public static int lowSuccess = 0;

    public static int count = 0;

    protected void Page_Load(object sender, EventArgs e)
    {



        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.DateTime"));
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("缩量");
        dt.Columns.Add("日均涨幅");
        dt.Columns.Add("买入");
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
        dtNew.Columns.Add("缩量");
        dtNew.Columns.Add("日均涨幅");
        dtNew.Columns.Add("买入");
        dtNew.Columns.Add("1日");
        dtNew.Columns.Add("2日");
        dtNew.Columns.Add("3日");
        dtNew.Columns.Add("4日");
        dtNew.Columns.Add("5日");
        dtNew.Columns.Add("总计");


        DataTable dtOri = DBHelper.GetDataTable(" select *  from alert_above_3_line_for_days where alert_date >= '2020-1-1' and above_3_line_days = 7 ");
        foreach (DataRow drOri in dtOri.Rows)
        {
            try
            {
                Stock s = GetStock(drOri["gid"].ToString().Trim());
                int alertIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
                int currentIndex = alertIndex;
                bool touch3Line = false;
                for (int i = alertIndex + 1; i < alertIndex + 5; i++)
                {
                    double line3T = s.GetAverageSettlePrice(i, 3, 3);
                    if (i + 5 < s.kLineDay.Length && s.kLineDay[i].lowestPrice < line3T * 1.01
                        && s.kLineDay[i].endPrice > line3T)
                    {
                        touch3Line = true;
                        currentIndex = i;
                        break;
                    }
                }
                if (!touch3Line)
                {
                    continue;
                }
                bool settleUnder3Line = false;





                if (currentIndex < 10)
                {
                    continue;
                }
                if (currentIndex + 6 >= s.kLineDay.Length)
                {
                    continue;
                }
                int daysAbove3Line = int.Parse(drOri["above_3_line_days"].ToString());

                for (int k = alertIndex - int.Parse(drOri["above_3_line_days"].ToString()) + 1; k <= currentIndex; k++)
                {
                    if (s.kLineDay[k].endPrice <= s.GetAverageSettlePrice(k, 3, 3))
                    {
                        settleUnder3Line = true;
                        break;
                    }
                }
                if (settleUnder3Line)
                {
                    continue;
                }
                double startRaisePrice = s.kLineDay[currentIndex - daysAbove3Line - 1].endPrice;
                double avgRaiseRate = (s.kLineDay[currentIndex].endPrice - startRaisePrice) / (startRaisePrice * daysAbove3Line) ;
                if (avgRaiseRate < 0.01)
                {
                    continue;
                }
                double line3Price = s.GetAverageSettlePrice(currentIndex, 3, 3);
                if (s.kLineDay[currentIndex].lowestPrice >= line3Price * 1.01 || s.kLineDay[currentIndex].endPrice <= line3Price)
                {
                    continue;
                }


                if (s.kLineDay[currentIndex].startPrice >= s.kLineDay[currentIndex].endPrice)
                {
                    continue;
                }

                if ((s.kLineDay[currentIndex].highestPrice - s.kLineDay[currentIndex].lowestPrice) / s.kLineDay[currentIndex].lowestPrice < 0.03)
                {
                    continue;
                }

                bool isNewHigh = true;
                double higesthPrice = Math.Max(s.kLineDay[currentIndex].highestPrice, s.kLineDay[currentIndex - 1].highestPrice);

                for (int j = currentIndex - 2; j >= 0 && s.kLineDay[j].endPrice > s.GetAverageSettlePrice(j, 3, 3); j--)
                {
                    if (higesthPrice <= s.kLineDay[j].highestPrice)
                    {
                        isNewHigh = false;
                        break;
                    }
                }
                if (!isNewHigh)
                {
                    continue;
                }


                double volumeChange = s.kLineDay[currentIndex].volume / Stock.GetAvarageVolume(s.kLineDay, currentIndex, 10);

                if (Math.Abs(1 - volumeChange) > 0.25)
                {
                    continue;
                }

                //double startRaisePrice = s.kLineDay[currentIndex - daysAbove3Line - 1].endPrice;


                if (dt.Select(" 日期 = '" + s.kLineDay[currentIndex].startDateTime.Date.ToShortDateString() + "' and 代码 = '" + s.gid.Trim() + "' ").Length == 0)
                {
                    DataRow dr = dt.NewRow();
                    dr["日期"] = s.kLineDay[currentIndex].startDateTime.Date;
                    dr["代码"] = s.gid.Trim();
                    dr["名称"] = s.Name.Trim();
                    dr["缩量"] = Math.Round(100 * volumeChange, 2).ToString() + "%";
                    dr["日均涨幅"] = Math.Round(avgRaiseRate * 100, 2).ToString() + "%";
                    dt.Rows.Add(dr);
                    double buyPrice = s.kLineDay[currentIndex].endPrice;
                    double maxPrice = 0;
                    for (int j = 1; j <= 5; j++)
                    {
                        maxPrice = Math.Max(maxPrice, s.kLineDay[currentIndex + j].highestPrice);
                        dr[j.ToString() + "日"] = (s.kLineDay[currentIndex  + j].highestPrice - buyPrice) / buyPrice;
                    }
                    dr["总计"] = (maxPrice - buyPrice) / buyPrice;
                    if ((double)dr["总计"] >= 0.01)
                    {
                        lowSuccess++;
                        if ((double)dr["总计"] >= 0.05)
                        {
                            highSuccess++;
                        }
                    }
                    dt.Rows.Add(dr);
                }
            }
            catch
            {

            }
        }

        count = dt.Rows.Count;


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
        涨1%：<%=Math.Round(lowSuccess * 100 / (double)count, 2)%>% 涨5%：<%=Math.Round(highSuccess * 100 / (double)count, 2)%>%
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
