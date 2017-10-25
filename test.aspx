<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        string[] gidArr = Util.GetAllGids();
        for (int i = 0; i < gidArr.Length; i++)
        {
            string gid = gidArr[i].Trim();
            string type = "day";

            KLine[] kArr = Stock.LoadLocalKLine(gid, type);
            for (int j = kArr.Length - 1; j >= 14; j--)
            {
                StockWatcher.SearchFolks(gid, type, kArr, j);
            }

            type = "1hr";
            kArr = Stock.LoadLocalKLine(gid, type);
            for (int j = kArr.Length - 1; j >= 14; j--)
            {
                StockWatcher.SearchFolks(gid, type, kArr, j);
            }

            type = "30min";
            kArr = Stock.LoadLocalKLine(gid, type);
            for (int j = kArr.Length - 1; j >= 14; j--)
            {
                StockWatcher.SearchFolks(gid, type, kArr, j);
            }
        }


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
