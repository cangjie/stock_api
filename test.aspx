﻿ <%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        //StockWatcher.LoadAllKLineToMemory();
        StockWatcher.RefreshUpdatedKLine();


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
