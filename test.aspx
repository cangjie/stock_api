<%@ Page Language="C#" %>
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
            KLine.SearchMACDAlert(stock.kLineDay, stock.kLineDay.Length - 1);
            KLine.SearchKDJAlert(stock.kLineDay, stock.kLineDay.Length - 1);
        }
    }
</script>
