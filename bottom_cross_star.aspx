<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Text" %>
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
            for (int j = 1; j < s.kLineDay.Length; j++)
            {
                double lastLowerPrice = Math.Min(s.kLineDay[j - 1].startPrice, s.kLineDay[j - 1].endPrice);
                if (s.kLineDay[j].startPrice < lastLowerPrice && s.kLineDay[j].endPrice < lastLowerPrice && s.kLineDay[j].volume < s.kLineDay[j - 1].volume
                    && Math.Abs(s.kLineDay[j].startPrice - s.kLineDay[j].endPrice) / s.kLineDay[j].endPrice <= 0.005)
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
