﻿<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        //StockWatcher.WatchKDJMACD();


        string[] gidArr = Util.GetAllGids();
        for (int i = 0; i < gidArr.Length; i++)
        {
            Stock stock = new Stock(gidArr[i].Trim());
            stock.LoadKLineDay();
            KLine.ComputeRSV(stock.kLineDay);
            KLine.ComputeKDJ(stock.kLineDay);
            KLine.ComputeMACD(stock.kLineDay);
            KLine.SearchMACDAlert(stock.kLineDay);
            KLine.SearchKDJAlert(stock.kLineDay);
        }

        //StockWatcher.SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", "test", "test stock", 0, "bottom");
        /*
        string[] gidArr = Util.GetAllGids();
        foreach (string gid in gidArr)
        {
            Stock stock = new Stock(gid);
            stock.LoadKLineDay();
            int currentIndex = stock.GetItemIndex(DateTime.Parse("2017-9-29"));
            if (stock.IsLimitUp(currentIndex))
            {
                LimitUp.SaveLimitUp(stock.gid.Trim(), DateTime.Parse(stock.kLineDay[currentIndex].startDateTime.ToShortDateString()),
                    stock.kLineDay[currentIndex - 1].endPrice, stock.kLineDay[currentIndex].startPrice, stock.kLineDay[currentIndex].endPrice, 
                    stock.kLineDay[currentIndex].volume);
            }
           
        }*/
    }
</script>
