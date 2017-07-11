<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">

    public static Queue queue = new Queue();

    protected void Page_Load(object sender, EventArgs e)
    {

        StockWatcher.WatchEachStock();
        //double[] volumeAndAmount = Stock.GetVolumeAndAmount("sh600031", DateTime.Now);
        //Response.Write(volumeAndAmount[0].ToString() + "|" + volumeAndAmount[1].ToString());
        


        /*
        Util.RefreshTodayKLine();
        foreach (string gid in Util.GetAllGids())
        {
            try
            {
                int todayIndex = 0;
                KLine[] kArr = KLine.GetLocalKLine(gid, "day");
                kArr = KLine.ComputeRSV(kArr);
                kArr = KLine.ComputeKDJ(kArr);
                todayIndex = KLine.GetStartIndexForDay(kArr, DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30"));
                KLine.SearchKDJAlert(kArr, todayIndex);
                kArr = KLine.GetLocalKLine(gid, "1hr");
                kArr = KLine.ComputeRSV(kArr);
                kArr = KLine.ComputeKDJ(kArr);
                todayIndex = KLine.GetStartIndexForDay(kArr, DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30"));
                KLine.SearchKDJAlert(kArr, todayIndex);
                kArr = KLine.GetLocalKLine(gid, "30min");
                kArr = KLine.ComputeRSV(kArr);
                kArr = KLine.ComputeKDJ(kArr);
                todayIndex = KLine.GetStartIndexForDay(kArr, DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30"));
                KLine.SearchKDJAlert(kArr, todayIndex);
                kArr = KLine.GetLocalKLine(gid, "15min");
                kArr = KLine.ComputeRSV(kArr);
                kArr = KLine.ComputeKDJ(kArr);
                todayIndex = KLine.GetStartIndexForDay(kArr, DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30"));
                KLine.SearchKDJAlert(kArr, todayIndex);
            }
            catch
            {

            }

        }*/

    }


</script>
