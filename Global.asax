<%@ Application Language="C#" %>

<script runat="server">

    void Application_Start(object sender, EventArgs e)
    {
        Util.physicalPath = Server.MapPath("//");
        for (int i = 0; KLineCache.allGid.Length == 0 && i < 100; i++)
        {
            KLineCache.allGid = Util.GetAllGids();
        }

        //Stock.todayKLineArr = new KLine[KLineCache.allGid.Length];

        

        KLineCache.kLineDayCache = new CachedKLine[Util.GetAllGids().Length];

        StockWatcher.tKLineRefresher.Start();
        //StockWatcher.tRefreshUpdatedKLine.Start();
        //StockWatcher.tLoadTodayKLine.Start();
        

        
        //StockWatcher.tLoadCurrentKLineToCache.Start();
        StockWatcher.tWatchEachStock.Start();
        StockWatcher.tLogQuota.Start();
        

        //StockWatcher.tRefreshUpdatedKLine.Start();

        //Core.RedisClient 

    }

    void Application_End(object sender, EventArgs e)
    {
        //  Code that runs on application shutdown

    }

    void Application_Error(object sender, EventArgs e)
    {
        // Code that runs when an unhandled error occurs

    }

    void Session_Start(object sender, EventArgs e)
    {
        // Code that runs when a new session is started

    }

    void Session_End(object sender, EventArgs e)
    {
        // Code that runs when a session ends. 
        // Note: The Session_End event is raised only when the sessionstate mode
        // is set to InProc in the Web.config file. If session mode is set to StateServer 
        // or SQLServer, the event is not raised.

    }

</script>
