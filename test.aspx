 <%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">

    //public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    protected void Page_Load(object sender, EventArgs e)
    {
        StackExchange.Redis.RedisValue[] rvArr = Util.rc.redisDb.SetMembers((StackExchange.Redis.RedisKey)"all_gids");
        string[] gidArr = new string[rvArr.Length];
        int i = 0;
        foreach (object o in rvArr)
        {
            string str = o.ToString();
            str = str.Substring(0, 8).Trim();
            gidArr[i] = str;
            i++;

        }

        i--;
        //StockWatcher.SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", "600031", "三一重工", 10.01, "above_3_line_for_days");

        //KeyValuePair<Stock, DateTime>[] gidArr = Util.GetDoubleLimitUpFrom3Line();

    }

    public static double GetFirstLowestPrice(KLine[] kArr, int index, out int lowestIndex)
    {
        double ret = double.MaxValue;
        int find = 0;
        lowestIndex = 0;
        for (int i = index; i > 0 && find < 2; i--)
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
