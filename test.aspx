<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<script runat="server">

    public static Queue queue = new Queue();

    protected void Page_Load(object sender, EventArgs e)
    {
		RunData();

        //ThreadStart ts = new ThreadStart(RunData);
        //Thread t = new Thread(ts);
        //t.Start();

        /*
        DataTable dt = DBHelper.GetDataTable(" select [name]  from dbo.sysobjects where OBJECTPROPERTY(id, N'IsUserTable') = 1 and name like '%timeline'");
        foreach (DataRow dr in dt.Rows)
        {
            KLine.ComputeAndUpdateKLine(dr["name"].ToString().Replace("_timeline", ""), "day", DateTime.Parse("2017-6-16"), DateTime.Parse("2017-7-6"));
            KLine.ComputeAndUpdateKLine(dr["name"].ToString().Replace("_timeline", ""), "1hr", DateTime.Parse("2017-6-16"), DateTime.Parse("2017-7-6"));
            KLine.ComputeAndUpdateKLine(dr["name"].ToString().Replace("_timeline", ""), "30min", DateTime.Parse("2017-6-16"), DateTime.Parse("2017-7-6"));
            KLine.ComputeAndUpdateKLine(dr["name"].ToString().Replace("_timeline", ""), "15min", DateTime.Parse("2017-6-16"), DateTime.Parse("2017-7-6"));
        }
        */

        /*
        Stock s = new Stock("sh600031");
        //s.kLineHour = Stock.LoadLocalKLine(s.gid, "1hr");
        s.kLineHour = KLine.ComputeKDJ(KLine.ComputeRSV(s.kLineHour));
        */


        //KLine.ComputeAndUpdateKLine("sh600031", "day", DateTime.Parse("2017-6-30"), DateTime.Parse("2017-7-5"));
        //KLine.CreateKLineTable("sh600056");
        /*
        TimeLine[] timeLineArr = TimeLine.GetTimeLineItem("sh600031", DateTime.Parse("2017-7-4"), DateTime.Now);
        if (timeLineArr.Length > 0)
        {
            KLine[] kArr = TimeLine.CreateKLineArray("sh600031", "day", timeLineArr);
        }
        */
        //StockWatcher.WatchEachStock();
        //StockWatcher.SendAlertMessage
        //StockWatcher.SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", ", stockName, s.LastTrade, "volumeincrease");
        /*
        DataTable dt = DBHelper.GetDataTable(" select [name]  from dbo.sysobjects where OBJECTPROPERTY(id, N'IsUserTable') = 1 and name like '%timeline'");
        foreach (DataRow dr in dt.Rows)
        {
            string gid = dr[0].ToString().Replace("_timeline", "");
            for (DateTime i = DateTime.Parse("2017-6-15"); i <= DateTime.Parse("2017-6-29"); i = i.AddDays(1))
            {
                if (Util.IsTransacDay(i))
                {
                    StockWatcher.GetVolumeIncrease(gid, i, true);
                }
            }
        }
        */
        //Response.Write(StockWatcher.GetVolumeIncrease("sh600378", DateTime.Parse("2017-6-28"), true));
        //Response.Write(StockWatcher.GetVolumeIncrease("sh600378", DateTime.Parse("2017-6-28"), true));
        //StockWatcher.WatchStar();
        //StockWatcher.AddAlert(DateTime.Now, "sh600031", "top_f3", "三一重工", "balabala");
        //StockWatcher.SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", "aaa");
        //KLine[] kArr = KLine.GetKLineDayFromSohu("sh600031", DateTime.Parse("2017-5-25"), DateTime.Parse("2017-6-1"));
        //Util.RefreshSuggestStockForToday();
        //Util.RefreshSuggestStock(DateTime.Parse("2017-6-13"));
        /*
        for (DateTime i = DateTime.Parse("2017-5-15"); i >= DateTime.Parse("2017-5-1"); i = i.AddDays(-1))
        {
            if (Util.IsTransacDay(i))
            {
                Util.RefreshSuggestStock(i);
                
                queue.Enqueue(i);
            ThreadStart ts = new ThreadStart(RunData);
            Thread t = new Thread(ts);
            t.Start();
                Thread.Sleep(1000);
                
            }
            
        }*/
    }

    public void RunData()
    {
        //DateTime currentDate = (DateTime)queue.Dequeue();
        //Util.RefreshSuggestStock(currentDate);
        DataTable dt = DBHelper.GetDataTable(" select [name]  from dbo.sysobjects where OBJECTPROPERTY(id, N'IsUserTable') = 1 and name like '%timeline'");
        foreach (DataRow dr in dt.Rows)
        {
	try
{
            KLine.ComputeAndUpdateKLine(dr["name"].ToString().Replace("_timeline", ""), "day", DateTime.Parse("2017-6-16"), DateTime.Parse("2017-7-6"));
}
catch{}
try
{ 
           KLine.ComputeAndUpdateKLine(dr["name"].ToString().Replace("_timeline", ""), "1hr", DateTime.Parse("2017-6-16"), DateTime.Parse("2017-7-6"));
}
catch{}
try
{ 
           KLine.ComputeAndUpdateKLine(dr["name"].ToString().Replace("_timeline", ""), "30min", DateTime.Parse("2017-6-16"), DateTime.Parse("2017-7-6"));
}
catch{}
try
{ 
 
          KLine.ComputeAndUpdateKLine(dr["name"].ToString().Replace("_timeline", ""), "15min", DateTime.Parse("2017-6-16"), DateTime.Parse("2017-7-6"));
}
catch
{}
        }
    }
</script>
