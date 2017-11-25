 <%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        Stock s = new Stock("sh600031");
        s.LoadKLineDay();
        Response.End();

        foreach (string gid in Util.GetAllGids())
        {
            Stock stock = new Stock(gid);
            stock.LoadKLineDay();
            KLine.ComputeMACD(stock.kLineDay);
            for (int i = stock.kLineDay.Length - 1; i >= 0; i--)
            {
                if (KLine.IsJumpHigh(stock.kLineDay, i))
                {
                    int macdDays = stock.macdDays(i);
                    int kdjDays = stock.kdjDays(i);
                    try
                    {
                        DBHelper.InsertData("alert_jump_high", new string[,] { {"gid", "varhcar", stock.gid },
                            {"alert_time", "datetime", Util.GetDay(stock.kLineDay[i].endDateTime).ToShortDateString() },
                            {"alert_price", "float", stock.kLineDay[i].startPrice.ToString() },
                            {"settle", "float", stock.kLineDay[i - 1].endPrice.ToString() },
                            {"macd_days", "int", macdDays.ToString() },
                            {"kdj_days", "int", kdjDays.ToString() } });
                    }
                    catch
                    {

                    }
                }
            }
        }

        //StockWatcher.WatchEachStock();
        /*
                string[] gidArr = Util.GetAllGids();
                for (int i = 0; i < gidArr.Length; i++)
                {
                    try
                    {
                        Stock stock = new Stock(gidArr[i].Trim());
                        stock.LoadKLineDay();
                        KLine.ComputeMACD(stock.kLineDay);
                        KLine.ComputeRSV(stock.kLineDay);
                        KLine.ComputeKDJ(stock.kLineDay);
                        for (int j =  stock.kLineDay.Length - 1; j < stock.kLineDay.Length; j++)
                        {
                            try
                            {
                                if (KLine.IsJumpHigh(stock.kLineDay, j))
                                {
                                    int macdDays = stock.macdDays(j);
                                    int kdjDays = stock.kdjDays(j);
                                    try
                                    {
                                        DBHelper.InsertData("alert_jump_high", new string[,] { {"gid", "varhcar", stock.gid },
                                    {"alert_time", "datetime", Util.GetDay(stock.kLineDay[j].endDateTime).ToShortDateString() },
                                    {"alert_price", "float", stock.kLineDay[j].startPrice.ToString() },
                                    {"settle", "float", stock.kLineDay[j - 1].endPrice.ToString() },
                                    {"macd_days", "int", macdDays.ToString() },
                                    {"kdj_days", "int", kdjDays.ToString() } });
                                    }
                                    catch
                                    {

                                    }
                                }
                            }
                            catch
                            {

                            }
                        }
                    }
                    catch
                    {

                    }
                }
        */
        /*
        Stock s = new Stock("sh600088");
        s.LoadKLineDay();
        int count = KLine.ComputeDeMarkValue(s.kLineDay, s.kLineDay.Length - 1);
        int countDays = KLine.GetLastDeMarkBuyPointIndex(s.kLineDay, s.kLineDay.Length - 1);
        count = KLine.ComputeDeMarkValue(s.kLineDay, s.kLineDay.Length - 2);
        countDays = KLine.GetLastDeMarkBuyPointIndex(s.kLineDay, s.kLineDay.Length - 2);
        count = KLine.ComputeDeMarkValue(s.kLineDay, s.kLineDay.Length - 3);
        countDays = KLine.GetLastDeMarkBuyPointIndex(s.kLineDay, s.kLineDay.Length - 3);
        */
        /*
        for (int i = s.kLineDay.Length - 1; i >= 15; i--)
        {
            int count = KLine.ComputeDeMarkValue(s.kLineDay, i);
            if (count != 0)
            {
                try
                {
                    DBHelper.InsertData("alert_demark", new string[,] {
                        {"gid", "varchar", s.gid.Trim() },
                        {"alert_time", "datetime", s.kLineDay[i].endDateTime.ToString() },
                        {"alert_type", "varchar", "day" },
                        {"value", "int", count.ToString() },
                        {"price", "float", s.kLineDay[i].endPrice.ToString() }
                    });
                }
                catch(Exception err)
                {
                    Console.WriteLine(err.ToString());
                }
            }
            */
        /*
                        string count = KLine.ComputeDeMarkCount(s.kLineDay, i).Trim();
                        if (count.IndexOf("(") < 0 && !count.Equals("++") && !count.Equals("--"))
                        {
                            count = count.Replace("+", "");
                            try
                            {
                                DBHelper.InsertData("alert_demark", new string[,] {
                                    {"gid", "varchar", s.gid.Trim() },
                                    {"alert_time", "datetime", s.kLineDay[i].endDateTime.ToString() },
                                    {"alert_type", "varchar", "day" },
                                    {"value", "int", int.Parse(count).ToString() },
                                    {"price", "float", s.kLineDay[i].endPrice.ToString() }
                                });
                            }
                            catch(Exception err)
                            {
                                Console.WriteLine(err.ToString());
                            }
                        }
        */


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

</script>
