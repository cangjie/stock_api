 <%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {

        Stock s = new Stock("sz000926");
        s.kLineDay = Stock.LoadLocalKLineFromDB(s.gid.Trim(), "day");
        s.kArr = s.kLineDay;
        for (int j = 0; j < 1; j++)
        {
            try
            {
                if (s.IsLimitUp(s.kLineDay.Length - 1 - j))
                {
                    LimitUp.SaveLimitUp(s.gid.Trim(), DateTime.Parse(s.kLineDay[s.kLineDay.Length - 1 - j].startDateTime.ToShortDateString()),
                            s.kLineDay[s.kLineDay.Length - 1 - j - 1].endPrice, s.kLineDay[s.kLineDay.Length - 1 - j].startPrice,
                            s.kLineDay[s.kLineDay.Length - 1 - j].highestPrice, s.kLineDay[s.kLineDay.Length - 1 - j].volume);
                }
            }
            catch
            {

            }
        }
        


        /*
        Stock s = new Stock("sh600846");
        s.kLineDay = Stock.LoadLocalKLineFromDB(s.gid, "day");
        s.kArr = s.kLineDay;
        s.IsLimitUp(s.kLineDay.Length - 5);
        */




        //KLine.RefreshKLine("sh603860", DateTime.Parse(DateTime.Now.ToShortDateString()));
        //Util.RefreshTodayKLine();

        //StockWatcher.RefreshUpdatedKLine();

        //StockWatcher.RefreshUpdatedKLine();

        /*
        DateTime currentDate = DateTime.Parse("2017-12-8");

        DateTime lastTransactDate = Util.GetLastTransactDate(currentDate, 1);
        DateTime limitUpEndDate = Util.GetLastTransactDate(lastTransactDate, 1);
        DateTime limitUpStartDate = Util.GetLastTransactDate(limitUpEndDate, 4);



        Stock s = new Stock(Util.GetSafeRequestValue(Request, "gid", "sz002138"));
        s.LoadKLineDay();

        Response.Write(s.GetAverageSettlePrice(s.GetItemIndex(DateTime.Now), 3, 3).ToString());
        */

        //Response.Write(cNew.gid.Trim());


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
