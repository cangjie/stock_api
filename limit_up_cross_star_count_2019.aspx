<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public double[] totalRate = new double[22];

    public int[] totalCount = new int[22];

    public int[] totalSuccessCount = new int[22];

    

    public static Stock[] gidArr;

    public static DateTime startDate = DateTime.Parse("2018-1-1");



    protected void Page_Load(object sender, EventArgs e)
    {

        for (int i = 0; i < 22; i++)
        {
            startDate = DateTime.Parse("2018-1-1").AddMonths(i);
            FillStockArr();
            DataTable dt = DBHelper.GetDataTable(" select * from limit_up where alert_date >= '"
                + startDate.ToShortDateString() + "' and alert_date < '" + startDate.AddMonths(3).ToShortDateString() + "' and next_day_cross_star_un_limit_up = 1 ");
            foreach (DataRow dr in dt.Rows)
            {
                try
                {
                    Stock s = GetStock(dr["gid"].ToString());
                    DateTime currentDate = DateTime.Parse(dr["alert_date"].ToString());
                    int currentIndex = s.GetItemIndex(currentDate);
                    if (currentIndex + 5 >= s.kLineDay.Length)
                    {
                        continue;
                    }
                    double buyPrice = s.kLineDay[currentIndex + 1].endPrice;
                    double highestPrice = 0;
                    for (int j = 0; j < 5; j++)
                    {
                        highestPrice = Math.Max(highestPrice, s.kLineDay[currentIndex + 1 + j].highestPrice);
                    }
                    double rate = (highestPrice - buyPrice) / buyPrice;
                    totalRate[i] = totalRate[i] + rate;
                    totalCount[i]++;
                    if (rate >= 0.05)
                    {
                        totalSuccessCount[i]++;
                    }
                }
                catch
                {

                }
                //totalRate = totalRate + (highestPrice - buyPrice) / buyPrice;
            }
        }
    }

    public void FillStockArr()
    {
        DataTable dt = DBHelper.GetDataTable(" select distinct gid from limit_up where alert_date >= '"
            + startDate.ToShortDateString() + "' and alert_date < '" + startDate.AddMonths(1).ToShortDateString() + "' and next_day_cross_star_un_limit_up = 1 ");
        gidArr = new Stock[dt.Rows.Count];
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            gidArr[i] = new Stock(dt.Rows[i][0].ToString().Trim());
            gidArr[i].LoadKLineDay(Util.rc);
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
        <table >
            <%
                DateTime sm = DateTime.Parse("2018-1-1");
                for (int i = 0; i < 22; i++)
                {
                 %>
            <tr>
                <td><%=sm.AddMonths(i).ToShortDateString() %></td>
                <td><%=Math.Round(totalRate[i]*100, 2).ToString() %>%</td>
                <td><%=Math.Round((totalRate[i]/totalCount[i])*100, 2).ToString() %>%</td>
                <td><%=totalSuccessCount[i].ToString() %></td>
                <td><%=totalCount[i].ToString() %></td>
                <td><%=Math.Round((double)100*totalSuccessCount[i]/(double)totalCount[i], 2).ToString() %>%</td>
            </tr>
            <%
                }
                 %>
        </table>
    </div>
    </form>
</body>
</html>
