<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Collections.Generic" %>
<!DOCTYPE html>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        RunData();
    }

    public static void RunData()
    {
        string[] gidArr = Util.GetAllGids();
        for (int i = 0; i < gidArr.Length; i++)
        {
            Stock s = new Stock(gidArr[i].Trim());
            s.LoadKLineDay();

            for (int j = s.kLineDay.Length - 1; j >= 1; j--)
            {
                //KeyValuePair<string, double>[] qArr = s.GetSortedQuota(j);
                double ma6 = s.GetAverageSettlePrice(j, 6, 0);
                double ma12 = s.GetAverageSettlePrice(j, 12, 0);
                double ma24 = s.GetAverageSettlePrice(j, 24, 0);
                double line3 = s.GetAverageSettlePrice(j, 3, 3);
                double minLine = Math.Min(ma6, ma12);
                minLine = Math.Min(minLine, ma24);
                minLine = Math.Min(minLine, line3);


                double lastLowerPrice = Math.Min(s.kLineDay[j - 1].startPrice, s.kLineDay[j - 1].endPrice);
                double higherPrice = Math.Max(s.kLineDay[j].startPrice, s.kLineDay[j].endPrice);
                double lowerPrice = Math.Min(s.kLineDay[j].startPrice, s.kLineDay[j].endPrice);
                double shaddowUpper = s.kLineDay[j].highestPrice - higherPrice;
                double shaddowDown = lowerPrice - s.kLineDay[j].lowestPrice;
                double entity = Math.Abs(s.kLineDay[j].startPrice - s.kLineDay[j].endPrice);
                if (s.kLineDay[j].startPrice < lastLowerPrice && s.kLineDay[j].endPrice < lastLowerPrice && s.kLineDay[j].volume < s.kLineDay[j - 1].volume
                    && Math.Abs(s.kLineDay[j].startPrice - s.kLineDay[j].endPrice) / s.kLineDay[j].endPrice <= 0.005
                    && higherPrice < minLine && minLine > 0 && shaddowUpper >= entity && entity > shaddowDown && shaddowUpper > shaddowDown * 1.5 )
                {
                    try
                    {
                        DBHelper.InsertData("bottom_cross_star", new string[,] {
                            {"gid", "varchar", s.gid.Trim() },
                            {"alert_date", "datetime", s.kLineDay[j].startDateTime.ToShortDateString() },
                            {"highest_price", "float", s.kLineDay[j].highestPrice.ToString() },
                            {"open_price", "float", s.kLineDay[j].startPrice.ToString() },
                            {"settle_price", "float", s.kLineDay[j].endPrice.ToString() },
                            {"lowest_price", "float", s.kLineDay[j].lowestPrice.ToString() },
                            {"volume", "float", s.kLineDay[j].volume.ToString() },
                            {"last_volume", "float", s.kLineDay[j-1].volume.ToString() },
                            {"last_open_price", "float", s.kLineDay[j-1].startPrice.ToString() },
                            {"last_settle_price", "float", s.kLineDay[j-1].endPrice.ToString() }
                        });
                    }
                    catch
                    {

                    }
                }
            }
        }
    }



</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
    
    </div>
    </form>
</body>
</html>
