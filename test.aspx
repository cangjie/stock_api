 <%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {

        Stock s = new Stock("sh600259");
        s.LoadKLineDay();
        KLine.ComputeMACD(s.kLineDay);
        KLine.ComputeRSV(s.kLineDay);
        KLine.ComputeKDJ(s.kLineDay);
        int currentIndex = s.GetItemIndex(DateTime.Parse("2017-10-20"));
        double macdRate = KLine.ComputeMacdDegree(s.kLineDay, currentIndex);

        Response.Write(s.kLineDay[s.kLineDay.Length - 2].macd);


        /*
        Stock stock = new Stock("sh600138");
        stock.LoadKLineDay();
        KLine k = stock.kLineDay[stock.kLineDay.Length - 1];
        */
        //Stock.GetVolumeAndAmount("sh600138", DateTime.Parse("2017-10-20"));



        //Response.Write(k.volume);

        //StockWatcher.WatchKDJMACD();

        /*
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
                */
    }
</script>
