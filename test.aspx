 <%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.Write(KLineCache.kLineDayCache.Length.ToString());

        CachedKLine c = new CachedKLine();
        c.gid = "sh600031";
        c.type = "day";
        c.kLine = Stock.LoadLocalKLineFromDB("sh600031", "day");
        c.lastUpdate = DateTime.Now;
        KLineCache.UpdateKLineInCache(c);
        CachedKLine cNew = KLineCache.GetKLineCache("sh600031");
        Response.Write(cNew.gid.Trim());


        //StockWatcher.LoadAllKLineToMemory();
        //StockWatcher.RefreshUpdatedKLine();


        //StockWatcher.LoadCurrentKLineToCache();
        //Stock s = new Stock("sz000606");
        //s.LoadKLineDay();
        
        //s.LoadKLineDay();
        //KLine.RefreshKLine("sh6000Line.LoadTodaysKLine();
        //StockWatcher.LoadAllKLineToMemory();
        //StockWatcher.ReadKLineFromFileCache("sh600031");
        //string[] gidArr = Util.GetAllGids();
        /*
        string[] gidArrNew = new string[3000];
        for (int i = 0; i < gidArrNew.Length; i++)
        {
            gidArrNew[i] = gidArr[i];
        }
        */
        //CachedKLine[] clArr = Stock.GetKLineSetArray(gidArr, "day", 500);
    }

</script>
