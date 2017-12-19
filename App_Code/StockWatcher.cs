using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;
using System.Net;
using System.IO;
using System.Threading;
using System.Text.RegularExpressions;
using System.Collections;
/// <summary>
/// Summary description for StockWatcher
/// </summary>
public class StockWatcher
{
    public static ThreadStart tsKLineRefresher = new ThreadStart(RefreshKLine);

    public static Queue gidNeedUpdateKLine = new Queue();

    public static Thread tKLineRefresher = new Thread(tsKLineRefresher);

    public static ThreadStart tsWatchEachStock = new ThreadStart(WatchEachStock);

    public static Thread tWatchEachStock = new Thread(tsWatchEachStock);

    public static ThreadStart tsLogQuota = new ThreadStart(LogQuota);

    public static Thread tLogQuota = new Thread(tsLogQuota);

    public static ThreadStart tsRefreshUpdatedKLine = new ThreadStart(RefreshUpdatedKLine);

    public static Thread tRefreshUpdatedKLine = new Thread(tsRefreshUpdatedKLine);

    //public static ThreadStart tsLoadCurrentKLineToCache = new ThreadStart(LoadCurrentKLineToCache);

    //public static Thread tLoadCurrentKLineToCache = new Thread(tsLoadCurrentKLineToCache);

    public static ThreadStart tsLoadTodayKLine = new ThreadStart(LoadTodayKLine);

    public static Thread tLoadTodayKLine = new Thread(tsLoadTodayKLine);

    public StockWatcher()
    {
      
    }
    /*
    public static void LoadCurrentKLineToCache()
    {
        for (; true;)
        {
            int i = 0;
            for (; i < 100 && KLine.cacheStatus.Trim().Equals("busy"); i++)
            {
                Thread.Sleep(10);
            }
            if (!KLine.cacheStatus.Trim().Equals("busy"))
            {
                KLine.cacheStatus = "busy";
                try
                {
                    DataTable newCacheTable = DBHelper.GetDataTable(" select * from cache_k_line_day where start_date >  '" + DateTime.Now.ToShortDateString() + "'  ");
                    KLine.currentKLineTable = newCacheTable;
                }
                catch
                {

                }
                KLine.cacheStatus = "idle";
                
            }
            Thread.Sleep(60000);
        }
    }

*/
    public static void LoadTodayKLine()
    {
        for (; true;)
        {
            if (Util.IsTransacDay(DateTime.Now.Date) && Util.IsTransacTime(DateTime.Now))
            {
                try
                {
                    DataTable dt = DBHelper.GetDataTable(" select * from cache_k_line_day where start_date >= '" + DateTime.Now.ToShortDateString() + "' ");
                    KLine[] kArr = new KLine[dt.Rows.Count];
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {
                        try
                        {
                            kArr[i] = new KLine();
                            kArr[i].gid = dt.Rows[i]["gid"].ToString().Trim();
                            kArr[i].startDateTime = DateTime.Parse(dt.Rows[i]["start_date"].ToString().Trim());
                            kArr[i].highestPrice = double.Parse(dt.Rows[i]["highest"].ToString().Trim());
                            kArr[i].lowestPrice = double.Parse(dt.Rows[i]["lowest"].ToString().Trim());
                            kArr[i].startPrice = double.Parse(dt.Rows[i]["open"].ToString().Trim());
                            kArr[i].endPrice = double.Parse(dt.Rows[i]["settle"].ToString().Trim());
                            kArr[i].volume = int.Parse(dt.Rows[i]["volume"].ToString().Trim());
                            kArr[i].amount = double.Parse(dt.Rows[i]["amount"].ToString().Trim());
                        }
                        catch
                        {

                        }
                    }
                    Stock.todayKLineArr = kArr;
                }
                catch
                {

                }
            }
            Thread.Sleep(60000);
        }
    }

    public static void WatchEachStock()
    {
        for (; true;)
        {
            try
            {
                if (Util.IsTransacDay(DateTime.Parse(DateTime.Now.ToShortDateString())) && DateTime.Now.Hour >= 9 && DateTime.Now.Hour <= 15)
                {
                    string[] gidArr = Util.GetAllGids();
                    //Stock.GetKLineSetArray(gidArr, "day", 100);
                    for (int i = 0; i < gidArr.Length; i++)
                    {
                        //KLine.RefreshKLine(gidArr[i], DateTime.Parse(DateTime.Now.ToShortDateString()));
                        Stock stock = new Stock(gidArr[i].Trim());
                        stock.LoadKLineDay();
                        int currentIndex = stock.GetItemIndex(DateTime.Parse(DateTime.Now.ToShortDateString()));
                        try
                        {
                            SearchBottomBreak3Line(stock, DateTime.Parse(DateTime.Now.ToShortDateString()));
                        }
                        catch
                        {

                        }
                        
                        if (DateTime.Now.Hour == 15 && stock.IsLimitUp(currentIndex))
                        {
                            LimitUp.SaveLimitUp(stock.gid.Trim(), DateTime.Parse(stock.kLineDay[currentIndex].startDateTime.ToShortDateString()),
                                stock.kLineDay[currentIndex - 1].endPrice, stock.kLineDay[currentIndex].startPrice, stock.kLineDay[currentIndex].endPrice, 
                                stock.kLineDay[currentIndex].volume);
                        }

                        KLine.ComputeRSV(stock.kLineDay);
                        KLine.ComputeKDJ(stock.kLineDay);
                        KLine.ComputeMACD(stock.kLineDay);
                        KLine.SearchMACDAlert(stock.kLineDay, stock.kLineDay.Length - 1);
                        KLine.SearchKDJAlert(stock.kLineDay, stock.kLineDay.Length - 1);

                        int countDemark = KLine.ComputeDeMarkValue(stock.kLineDay, stock.kLineDay.Length - 1);
                        if (countDemark != 0)
                        {
                            try
                            {
                                DBHelper.InsertData("alert_demark", new string[,] {
                                {"gid", "varchar", stock.gid.Trim() },
                                {"alert_time", "datetime", stock.kLineDay[stock.kLineDay.Length - 1].endDateTime.ToString() },
                                {"alert_type", "varchar", "day" },
                                {"value", "int", countDemark.ToString() },
                                {"price", "float", stock.kLineDay[stock.kLineDay.Length - 1].endPrice.ToString() }
                            });
                            }
                            catch (Exception err)
                            {
                                Console.WriteLine(err.ToString());
                            }
                        }

                    }
                }
            }
            catch
            {

            }
            Thread.Sleep(10000);
        }
    }

    public static void LogQuota()
    {
        for (; true;)
        {
            try
            {
                if (Util.IsTransacDay(DateTime.Parse(DateTime.Now.ToShortDateString())) && DateTime.Now.Hour >= 9 && DateTime.Now.Hour <= 15)
                {
                    string[] gidArr = Util.GetAllGids();
                    //Stock.GetKLineSetArray(gidArr, "day", 100);
                    for (int i = 0; i < gidArr.Length; i++)
                    {
                        //if (gidArr[i].Trim().Equals("sh601128"))
                        {

                            //KLine.RefreshKLine(gidArr[i], DateTime.Parse(DateTime.Now.ToShortDateString()));
                            string gid = gidArr[i];
                            KLine[] kArr = Stock.LoadLocalKLine(gid, "day");
                            SearchFolks(gid, "day", kArr, kArr.Length - 1);
                            kArr = Stock.LoadLocalKLine(gid, "1hr");
                            SearchFolks(gid, "1hr", kArr, kArr.Length - 1);
                            kArr = Stock.LoadLocalKLine(gid, "30min");
                            SearchFolks(gid, "30min", kArr, kArr.Length - 1);
                        }
                    }
                }
            }
            catch
            {

            }
            Thread.Sleep(120000);
        }
    }

    public static void SearchFolks(string gid, string type, KLine[] kArr, int index)
    {
        KLine.ComputeMACD(kArr);
        KLine k = kArr[index];
        if (IsMacdFolk(kArr, index))
        {
            LogMacd(gid, type, k.endDateTime, k.endPrice, k.dif, k.dea, k.macd);
        }
        KLine.ComputeRSV(kArr);
        KLine.ComputeKDJ(kArr);
        if (IsKdjFolk(kArr, index))
        {
            LogKdj(gid, type, k.endDateTime, k.endPrice, k.k, k.d, k.j);
        }
        KLine.ComputeCci(kArr);
        if (IsCciFolk(kArr, index))
        {
            LogCci(gid, type, k.endDateTime, k.endPrice, k.cci);
        }

    }

    public static bool IsMacdFolk(KLine[] kArr, int index)
    {
        bool ret = false;
        if (index > 0)
        {
            if (kArr[index].macd >= 0 && kArr[index - 1].macd < 0 )
            {
                ret = true;
            }
        }
        return ret;
    }

    public static bool IsKdjFolk(KLine[] kArr, int index)
    {
        bool ret = false;
        if (kArr[index].j >= kArr[index].k && kArr[index - 1].j <= kArr[index - 1].k && Math.Abs(kArr[index].k - 50) >= 15 && Math.Abs(kArr[index].d - 50) >= 15)
        {
            ret = true;
        }
        return ret;
    }

    public static bool IsCciFolk(KLine[] kArr, int index)
    {
        bool ret = false;
        if (kArr[index].cci < 0 && kArr[index].cci > -100 && kArr[index - 1].cci < -100)
        {
            ret = true;
        }
        return ret;
    }

    public static int LogMacd(string gid, string type, DateTime qTime, double price, double dif, double dea, double macd)
    {
        int ret = -1;
        try
        {
            ret = DBHelper.InsertData("alert_macd", new string[,] { {"gid", "varchar", gid.Trim() },
            {"alert_type", "varchar", type.Trim() },
            {"alert_time", "datetime", qTime.ToString() },
            {"alert_price", "float", price.ToString()},
            {"dif", "float", dif.ToString() },
            {"dea", "float", dea.ToString() },
            {"macd", "float", macd.ToString() } });
        }
        catch
        {

        }
        return ret;
    }

    public static int LogKdj(string gid, string type, DateTime qTime, double price, double k, double d, double j)
    {
        int ret = -1;
        try
        {
            ret = DBHelper.InsertData("alert_kdj", new string[,] { {"gid", "varchar", gid.Trim() },
            {"alert_type", "varchar", type.Trim() },
            {"alert_time", "datetime", qTime.ToString() },
            {"alert_price", "float", price.ToString()},
            {"k", "float", k.ToString() },
            {"d", "float", d.ToString() },
            {"j", "float", j.ToString() } });
        }
        catch
        {

        }
        return ret;
    }

    public static int LogCci(string gid, string type, DateTime qTime, double price, double cci)
    {
        int ret = -1;
        try
        {
            ret = DBHelper.InsertData("alert_cci", new string[,] { {"gid", "varchar", gid.Trim() },
            {"alert_type", "varchar", type.Trim() },
            {"alert_time", "datetime", qTime.ToString() },
            {"alert_price", "float", price.ToString()},
            {"cci", "float", cci.ToString() }
            });
        }
        catch
        {

        }
        return ret;
    }



    /// <old methods>
    /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// </summary>
    public static void RefreshKLine()
    {
        for (; true;)
        {
           
            try
            {
                Util.RefreshTodayKLine();
            }
            catch
            {

            }
            Thread.Sleep(60000);
        }
    }

    public static void RefreshUpdatedKLine()
    {
        for (; true;)
        {
            try
            {
                if (Util.IsTransacDay(DateTime.Now.Date) && Util.IsTransacTime(DateTime.Now))
                {
                    DataTable dt = DBHelper.GetDataTable(" select * from timeline_update where deal = 0 and update_date = '" + DateTime.Now.ToShortDateString() + "' ");
                    string ids = "";
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {
                        try
                        {
                            string gid = dt.Rows[i]["gid"].ToString().Trim();
                            CachedKLine c = KLineCache.GetKLineCache(gid);
                            if (c.gid != null && !c.gid.Trim().Equals(""))
                            {
                                KLine lastKLine = c.kLine[c.kLine.Length - 1];
                                if (lastKLine.startDateTime.Date == DateTime.Now.Date)
                                {
                                    double currentPrice = double.Parse(dt.Rows[i]["price"].ToString().Trim());
                                    lastKLine.endPrice = currentPrice;
                                    lastKLine.lowestPrice = ((lastKLine.lowestPrice < currentPrice) ? lastKLine.lowestPrice : currentPrice);
                                    lastKLine.highestPrice = ((lastKLine.highestPrice > currentPrice) ? lastKLine.highestPrice : currentPrice);
                                    lastKLine.volume = int.Parse(dt.Rows[i]["volume"].ToString());
                                    lastKLine.amount = double.Parse(dt.Rows[i]["amount"].ToString());
                                }
                                c.kLine[c.kLine.Length - 1] = lastKLine;
                                KLineCache.UpdateKLineInCache(c);
                            }
                        }
                        catch
                        {


                        }
                        ids = ids + ((ids.Trim().Equals("") ? "" : ", ") + " '" + dt.Rows[i]["gid"].ToString().Trim()) + "' ";
                    }
                    System.Data.SqlClient.SqlConnection conn = new System.Data.SqlClient.SqlConnection(Util.conStr.Trim());
                    System.Data.SqlClient.SqlCommand cmd = new System.Data.SqlClient.SqlCommand(" update timeline_update set deal = 1 where deal = 0 and update_date = '"
                        + DateTime.Now.ToShortDateString() + "' and gid in (" + ids.Trim() + " )", conn);
                    conn.Open();
                    cmd.ExecuteNonQuery();
                    conn.Close();
                    cmd.Dispose();
                    conn.Dispose();
                }
            }
            catch
            {

            }
            Thread.Sleep(60000);
        }
        
    }


    public static void RefreshUpdatedKLine1()
    {
        for (; Util.IsTransacDay(DateTime.Now.Date) && Util.IsTransacTime(DateTime.Now);)
        {
            try
            {
                DataTable dt = DBHelper.GetDataTable(" select * from timeline_update where deal = 0 and update_date = '" + DateTime.Now.ToShortDateString() + "' ");
                string ids = "";
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    try
                    {
                        string gid = dt.Rows[i]["gid"].ToString().Trim();
                        CachedKLine c = KLineCache.GetKLineCache(gid);
                        if (c.gid == null || c.gid.Trim().Equals(""))
                        {
                            c.gid = gid;
                            c.type = "day";
                            c.kLine = Stock.LoadLocalKLineFromDB(gid, "day");
                            c.lastUpdate = DateTime.Parse(dt.Rows[i]["detail_time"].ToString().Trim());
                        }
                        else
                        {
                            if (c.lastUpdate <= DateTime.Parse(dt.Rows[i]["detail_time"].ToString().Trim()))
                            {
                                KLine lastKLine = c.kLine[c.kLine.Length - 1];
                                int volume = int.Parse(dt.Rows[i]["volume"].ToString());
                                double amount = double.Parse(dt.Rows[i]["amount"].ToString());

                                if (lastKLine.startDateTime.Date == DateTime.Now.Date)// && lastKLine.volume <= volume)
                                {
                                    if (lastKLine.volume < volume)
                                    {
                                        lastKLine.endPrice = double.Parse(dt.Rows[i]["price"].ToString());
                                        lastKLine.volume = Math.Max(lastKLine.volume, volume);
                                        lastKLine.amount = Math.Max(lastKLine.amount, amount);
                                        c.kLine[c.kLine.Length - 1] = lastKLine;
                                        KLineCache.UpdateKLineInCache(c);
                                    }
                                }
                                else
                                {
                                    lastKLine = new KLine();
                                    lastKLine.startDateTime = DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30");
                                    lastKLine.startPrice = double.Parse(dt.Rows[i]["price"].ToString());
                                    lastKLine.endPrice = lastKLine.startPrice;
                                    lastKLine.volume = volume;
                                    lastKLine.amount = amount;
                                    KLine[] kArrNew = new KLine[c.kLine.Length + 1];
                                    for (int j = 0; j < c.kLine.Length; j++)
                                    {
                                        kArrNew[j] = c.kLine[j];
                                    }
                                    kArrNew[c.kLine.Length] = lastKLine;
                                    c.kLine = kArrNew;
                                    KLineCache.UpdateKLineInCache(c);
                                }

                            }
                        }
                        ids = ids + ((ids.Trim().Equals("") ? "" : ", ") + " '" + dt.Rows[i]["gid"].ToString().Trim()) + "' ";
                        if (i % 100 == 0)
                        {
                            System.Data.SqlClient.SqlConnection conn = new System.Data.SqlClient.SqlConnection(Util.conStr.Trim());
                            System.Data.SqlClient.SqlCommand cmd = new System.Data.SqlClient.SqlCommand(" update timeline_update set deal = 1 where deal = 0 and update_date = '"
                                + DateTime.Now.ToShortDateString() + "' and gid in (" + ids.Trim() + " )", conn);
                            conn.Open();
                            cmd.ExecuteNonQuery();
                            conn.Close();
                            cmd.Dispose();
                            conn.Dispose();
                            ids = "";
                        }
                    }
                    catch
                    {


                    }
                    
                }
                if (!ids.Trim().Equals(""))
                {
                    System.Data.SqlClient.SqlConnection conn = new System.Data.SqlClient.SqlConnection(Util.conStr.Trim());
                    System.Data.SqlClient.SqlCommand cmd = new System.Data.SqlClient.SqlCommand(" update timeline_update set deal = 1 where deal = 0 and update_date = '"
                        + DateTime.Now.ToShortDateString() + "' and gid in (" + ids.Trim() + " )", conn);
                    conn.Open();
                    cmd.ExecuteNonQuery();
                    conn.Close();
                    cmd.Dispose();
                    conn.Dispose();
                }
            }
            catch
            {

            }
            Thread.Sleep(10000);
        }
        
    }

    public static void RefreshUpdatedKLineForSingleStock()
    {
        try
        {
            string gid = gidNeedUpdateKLine.Dequeue().ToString();
            DBHelper.UpdateData(" timeline_update ", new string[,] { { "deal", "int", "1" } },
                new string[,] { { "gid", "varchar", gid.Trim() }, { "update_date", "datetime", DateTime.Now.ToShortDateString() } }, Util.conStr);
            KLine.RefreshKLine(gid, DateTime.Parse(DateTime.Now.ToShortDateString()));

        }
        catch
        {

        }
    }

    public static void RefreshUpdatedKLineForSingleStock(string gid)
    {
        try
        {
            DBHelper.UpdateData(" timeline_update ", new string[,] { { "deal", "int", "1" } },
                new string[,] { { "gid", "varchar", gid.Trim() }, { "update_date", "datetime", DateTime.Now.ToShortDateString() } }, Util.conStr);
            KLine.RefreshKLine(gid, DateTime.Parse(DateTime.Now.ToShortDateString()));
        }
        catch
        {

        }
    }

    public static void SendAlertMessage(string openId, string gid, string name, double price, string type)
    {
        string templateId = "K2ef8z8NubKY7pJsH-zunAilcE5RT2nTk74-VPqd3d0";
        string json = "";
        string first = "";
        string keyword1 = "";
        string keyword2 = "";
        string keyword3 = "";
        //string url = "http://stocks.sina.cn/" + gid.Substring(0,2) + "/levle2?code=" + gid+"&vt=4";
        string url = "http://54.223.116.146:8848/show_k_line_day.aspx?gid=" + gid;
        switch (type)
        {
            case "star":
                templateId = "oioxM12STSFIEroKSVhzrq1pLbsFKSNEJxgsQcyoQpM";
                first = "[" + gid.Trim() + "]" + name.Trim();
                keyword1 = gid;
                keyword2 = name;
                keyword3 = price.ToString();
                break;
            default:
                type = type.Replace("top", "压力位").Replace("bottom", "支撑位").Replace("wave", "波段").Replace("low", "低位").Replace("high", "高位").Trim().Replace("over3line", "突破三线").Replace("volumeincrease", "放量");
                type = type.Replace("volumedecrease", "缩量调整后上涨超3%").Replace("3_line", "底部突破3线").Replace("macd", "MACD金叉").Replace("break_3_line_twice", "双穿三线").Replace("above_3_line_for_days", "三线上多日");
                first = type;
                keyword1 = "[" + gid.Trim() + "]" + name.Trim();
                keyword2 = price.ToString();
                keyword3 = DateTime.Now.ToString();
                break;
        }
        json = "{\"touser\":\"" + openId + "\",\"template_id\":\"" + templateId + "\",\"url\":\"" + url + "\", \"topcolor\":\"#FF0000\", \"data\":{" 
            + "\"first\":{\"value\":\"" + first + "\", \"color\":\"#000000\"}," 
            + "\"keyword1\": {\"value\":\"" + keyword1 + "\", \"color\":\"#000000\"},"
            + "\"keyword2\": {\"value\":\"" + keyword2 + "\", \"color\":\"#000000\"},"
            + "\"keyword3\": {\"value\":\"" + keyword3 + "\", \"color\":\"#000000\"}"
            + "}}";
        Util.GetWebContent("http://weixin.luqinwenda.com/api/send_template_message.aspx", "POST", json, "application/raw");
        
    }
   
    public static DataTable GetTimeLineTradeAndVolumeTable(string gid, DateTime date)
    {
        DataTable dt = DBHelper.GetDataTable("exec sp_snap '" + date.ToShortDateString() + "' , '" + gid  + "'  ");
        return dt;
    }

    public static DateTime GetVolumeIncrease(string gid, DateTime date, bool isPriceUp)
    {
        DataTable dt = GetTimeLineTradeAndVolumeTable(gid, date);
        double rate = 0.01;
        DateTime tick = DateTime.Parse("2000-1-1");
        int k = 0;
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = i + 1; j < dt.Rows.Count; j++)
            {
                if (Math.Round(double.Parse(dt.Rows[j]["volume_alpha"].ToString()), 0) >= 1)
                {
                    i = j;
                    break;
                }
                double priceIncrease = double.Parse(dt.Rows[j]["trade"].ToString())
                    - double.Parse(dt.Rows[i]["trade"].ToString());
                if (!isPriceUp)
                    priceIncrease = -1 * priceIncrease;
                if (priceIncrease / double.Parse(dt.Rows[i]["trade"].ToString()) >= rate)
                {
                    k = j;
                    break;
                }
            }
            if (k != 0)
            {
                tick = DateTime.Parse(dt.Rows[k]["ticktime"].ToString().Trim());
                try
                {
                    DBHelper.InsertData("volume_increase_log", new string[,] { { "volume_increase_time", "datetime", tick.ToString() },
                    { "gid", "varchar", gid}, {"volume_start", "float", dt.Rows[i]["volume"].ToString() },
                    { "volume_end", "float", dt.Rows[k]["volume"].ToString()}, { "price_start", "float", dt.Rows[i]["trade"].ToString()},
                    { "price_end", "float", dt.Rows[k]["trade"].ToString()} });
                }
                catch
                {

                }
                break;
            }
        }
        return tick;
    }

    public static bool AddAlert(DateTime alertDate, string gid, string type, string name, string message)
    {
        bool ret = false;
        if (type.StartsWith("top") || type.StartsWith("bottom"))
        {
            alertDate = DateTime.Parse(alertDate.ToShortDateString());
        }
        try
        {
            int i = DBHelper.InsertData("stock_alert_message", new string[,] { { "alert_date", "datetime", alertDate.ToShortDateString() },
            { "gid","varchar", gid}, { "alert_type", "varchar", type.Trim()}, { "name", "varchar", name.Trim()}, { "message", "varchar", message.Trim()} });
            if (i > 0)
                ret = true;
        }
        catch
        {

        }
        return ret;
    }

    public static void SendAlertMessage(string openId, string message)
    {
        string postStr = "{"
            + "\"fromuser\":\"gh_7c0c5cc0906a\","
            + "\"touser\":\"" + openId.Trim() + "\","
            + "\"msgtype\":\"text\","
            + "\"text\":{ \"content\":\"" + message.Trim() + "\"}"
            + "}";
        HttpWebRequest req = (HttpWebRequest)WebRequest.Create("http://weixin.luqinwenda.com/send_message.aspx");
        req.Method = "POST";
        req.ContentType = "application/raw";
        byte[] bArr = System.Text.Encoding.UTF8.GetBytes(postStr);
        req.ContentLength = bArr.Length;
        Stream reqStream = req.GetRequestStream();
        reqStream.Write(bArr, 0, bArr.Length);
        HttpWebResponse res = (HttpWebResponse)req.GetResponse();
        Stream s = res.GetResponseStream();
        s.Close();
        reqStream.Close();
        res.Close();
        req.Abort();
    }

    public static void WatchKDJMACD()
    {
        for (; true;)
        {
            foreach (string gid in Util.GetAllGids())
            {
                if (Util.IsTransacTime(DateTime.Now))
                {
                    try
                    {
                        KLine[] kArrDay = KLine.GetLocalKLine(gid, "day");
                        KLine.ComputeRSV(kArrDay);
                        KLine.ComputeKDJ(kArrDay);
                        KLine.SearchKDJAlert(kArrDay, kArrDay.Length - 1);
                        KLine.ComputeMACD(kArrDay);
                        KLine.SearchMACDAlert(kArrDay, kArrDay.Length - 1);


                        //KLine.SearchKDJAlert(gid, "day", DateTime.Now);
                        

                        //KLine.SearchKDJAlert(gid, "1hr", DateTime.Now);
                        //KLine.SearchKDJAlert(gid, "30min", DateTime.Now);
                        //KLine.SearchKDJAlert(gid, "15min", DateTime.Now);
                    }
                    catch
                    {

                    }
                }
            }
            Thread.Sleep(1000);
        }
    }

    public static void SearchBottomBreak3Line(Stock stock, DateTime currentDate)
    {
        if (!Util.IsTransacDay(currentDate))
            return;
        int currentIndex = stock.GetItemIndex(currentDate);
        if (currentIndex < 6)
            return;
        if (stock.IsCross3Line(currentIndex, "day"))
        {
            int goingDown3LineCount = stock.GoingDows3LineCount(currentIndex);
            int under3LineCount = stock.Under3LineKLines(currentIndex);
            try
            {
                DBHelper.InsertData("bottom_break_cross_3_line", new string[,] {
                    { "gid", "varchar", stock.gid},
                    { "suggest_date", "datetime", currentDate.ToShortDateString()},
                    { "name", "varchar", stock.Name.Trim()},
                    { "settlement", "float", stock.kLineDay[currentIndex-1].endPrice.ToString()},
                    { "[open]", "float", stock.kLineDay[currentIndex].startPrice.ToString()},
                    { "avg_3_3_yesterday", "float", stock.GetAverageSettlePrice(currentIndex-1, 3, 3).ToString()},
                    { "avg_3_3_today", "float", stock.GetAverageSettlePrice(currentIndex, 3, 3).ToString()},
                    { "under_3_line_days", "int", under3LineCount.ToString()},
                    { "going_down_3_line_days", "int", goingDown3LineCount.ToString()} });
            }
            catch
            {

            }
        }
    }

    public static string GetMarketType(string gid)
    {
        string marketType = "6";
        if (gid.StartsWith("sh6"))
        {
            marketType = "6";
        }
        else if (gid.StartsWith("sz002"))
        {
            marketType = "002";
        }
        else if (gid.StartsWith("sz300"))
        {
            marketType = "300";
        }
        else
        {
            marketType = "000";
        }
        return marketType.Trim();
    }

    public static void WriteAllKLineToFileCache()
    {
        string[] gidArr = Util.GetAllGids();
        foreach (string gid in gidArr)
        {
            WriteKLineToFileCache(gid, Stock.LoadLocalKLineFromDB(gid, "day"));
        }
    }

    public static void LoadAllKLineToMemory()
    {
        string rootPath = Util.physicalPath + @"\cache\k_line_day";
        if (!Directory.Exists(rootPath + @"\6"))
            return;
        if (!Directory.Exists(rootPath + @"\000"))
            return;
        if (!Directory.Exists(rootPath + @"\002"))
            return;
        if (!Directory.Exists(rootPath + @"\300"))
            return;
        for (int i = 0; i < 100 && KLine.cacheStatus.Trim().Equals("busy"); i++)
        {
            Thread.Sleep(10);
        }

        
        DataTable dt = KLine.currentKLineTable;
        if (dt.Rows.Count == 0)
        {
            KLine.cacheStatus = "busy";
            dt = DBHelper.GetDataTable(" select * from cache_k_line_day where start_date >  '" + DateTime.Now.ToShortDateString() + "'  ");
            KLine.cacheStatus = "idle";
            KLine.currentKLineTable = dt;
        }
        
        
        ArrayList arr = new ArrayList();
        foreach (string filePath in Directory.GetFiles(rootPath + @"\6"))
        {
            CachedKLine c = LoadOneKLineToMemory(filePath);
            DataRow[] drArr = dt.Select(" gid = '" + c.gid.Trim() + "' ");
            if (drArr.Length > 0)
            {
                KLine lastKLine = c.kLine[c.kLine.Length - 1];
                if (lastKLine.startDateTime.ToShortDateString().Equals(DateTime.Parse(drArr[0]["start_date"].ToString().Trim()).ToShortDateString()))
                {
                    lastKLine.startPrice = double.Parse(drArr[0]["open"].ToString().Trim());
                    lastKLine.endPrice = double.Parse(drArr[0]["settle"].ToString().Trim());
                    lastKLine.highestPrice = double.Parse(drArr[0]["highest"].ToString().Trim());
                    lastKLine.lowestPrice = double.Parse(drArr[0]["lowest"].ToString().Trim());
                    lastKLine.volume = int.Parse(drArr[0]["volume"].ToString().Trim());
                    lastKLine.amount = double.Parse(drArr[0]["amount"].ToString().Trim());
                    c.kLine[c.kLine.Length - 1] = lastKLine;
                }
                else
                {
                    lastKLine = new KLine();
                    lastKLine.startPrice = double.Parse(drArr[0]["open"].ToString().Trim());
                    lastKLine.endPrice = double.Parse(drArr[0]["settle"].ToString().Trim());
                    lastKLine.highestPrice = double.Parse(drArr[0]["highest"].ToString().Trim());
                    lastKLine.lowestPrice = double.Parse(drArr[0]["lowest"].ToString().Trim());
                    lastKLine.volume = int.Parse(drArr[0]["volume"].ToString().Trim());
                    lastKLine.amount = double.Parse(drArr[0]["amount"].ToString().Trim());
                    lastKLine.gid = c.gid;
                    lastKLine.type = "day";
                    lastKLine.startDateTime = DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30");
                    KLine[] kArrNew = new KLine[c.kLine.Length + 1];
                    for (int i = 0; i < c.kLine.Length; i++)
                    {
                        kArrNew[i] = c.kLine[i];
                    }
                    kArrNew[kArrNew.Length - 1] = lastKLine;
                    c.kLine = kArrNew;
                }
            }
            arr.Add(c);
        }
        foreach (string filePath in Directory.GetFiles(rootPath + @"\000"))
        {
            CachedKLine c = LoadOneKLineToMemory(filePath);
            DataRow[] drArr = dt.Select(" gid = '" + c.gid.Trim() + "' ");
            if (drArr.Length > 0)
            {
                KLine lastKLine = c.kLine[c.kLine.Length - 1];
                if (lastKLine.startDateTime.ToShortDateString().Equals(DateTime.Parse(drArr[0]["start_date"].ToString().Trim()).ToShortDateString()))
                {
                    lastKLine.startPrice = double.Parse(drArr[0]["open"].ToString().Trim());
                    lastKLine.endPrice = double.Parse(drArr[0]["settle"].ToString().Trim());
                    lastKLine.highestPrice = double.Parse(drArr[0]["highest"].ToString().Trim());
                    lastKLine.lowestPrice = double.Parse(drArr[0]["lowest"].ToString().Trim());
                    lastKLine.volume = int.Parse(drArr[0]["volume"].ToString().Trim());
                    lastKLine.amount = double.Parse(drArr[0]["amount"].ToString().Trim());
                    c.kLine[c.kLine.Length - 1] = lastKLine;
                }
                else
                {
                    lastKLine = new KLine();
                    lastKLine.startPrice = double.Parse(drArr[0]["open"].ToString().Trim());
                    lastKLine.endPrice = double.Parse(drArr[0]["settle"].ToString().Trim());
                    lastKLine.highestPrice = double.Parse(drArr[0]["highest"].ToString().Trim());
                    lastKLine.lowestPrice = double.Parse(drArr[0]["lowest"].ToString().Trim());
                    lastKLine.volume = int.Parse(drArr[0]["volume"].ToString().Trim());
                    lastKLine.amount = double.Parse(drArr[0]["amount"].ToString().Trim());
                    lastKLine.gid = c.gid;
                    lastKLine.type = "day";
                    lastKLine.startDateTime = DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30");
                    KLine[] kArrNew = new KLine[c.kLine.Length + 1];
                    for (int i = 0; i < c.kLine.Length; i++)
                    {
                        kArrNew[i] = c.kLine[i];
                    }
                    kArrNew[kArrNew.Length - 1] = lastKLine;
                    c.kLine = kArrNew;
                }
            }
            arr.Add(c);
        }
        foreach (string filePath in Directory.GetFiles(rootPath + @"\002"))
        {
            CachedKLine c = LoadOneKLineToMemory(filePath);
            DataRow[] drArr = dt.Select(" gid = '" + c.gid.Trim() + "' ");
            if (drArr.Length > 0)
            {
                KLine lastKLine = c.kLine[c.kLine.Length - 1];
                if (lastKLine.startDateTime.ToShortDateString().Equals(DateTime.Parse(drArr[0]["start_date"].ToString().Trim()).ToShortDateString()))
                {
                    lastKLine.startPrice = double.Parse(drArr[0]["open"].ToString().Trim());
                    lastKLine.endPrice = double.Parse(drArr[0]["settle"].ToString().Trim());
                    lastKLine.highestPrice = double.Parse(drArr[0]["highest"].ToString().Trim());
                    lastKLine.lowestPrice = double.Parse(drArr[0]["lowest"].ToString().Trim());
                    lastKLine.volume = int.Parse(drArr[0]["volume"].ToString().Trim());
                    lastKLine.amount = double.Parse(drArr[0]["amount"].ToString().Trim());
                    c.kLine[c.kLine.Length - 1] = lastKLine;
                }
                else
                {
                    lastKLine = new KLine();
                    lastKLine.startPrice = double.Parse(drArr[0]["open"].ToString().Trim());
                    lastKLine.endPrice = double.Parse(drArr[0]["settle"].ToString().Trim());
                    lastKLine.highestPrice = double.Parse(drArr[0]["highest"].ToString().Trim());
                    lastKLine.lowestPrice = double.Parse(drArr[0]["lowest"].ToString().Trim());
                    lastKLine.volume = int.Parse(drArr[0]["volume"].ToString().Trim());
                    lastKLine.amount = double.Parse(drArr[0]["amount"].ToString().Trim());
                    lastKLine.gid = c.gid;
                    lastKLine.type = "day";
                    lastKLine.startDateTime = DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30");
                    KLine[] kArrNew = new KLine[c.kLine.Length + 1];
                    for (int i = 0; i < c.kLine.Length; i++)
                    {
                        kArrNew[i] = c.kLine[i];
                    }
                    kArrNew[kArrNew.Length - 1] = lastKLine;
                    c.kLine = kArrNew;
                }
            }
            arr.Add(c);
        }
        foreach (string filePath in Directory.GetFiles(rootPath + @"\300"))
        {
            CachedKLine c = LoadOneKLineToMemory(filePath);
            DataRow[] drArr = dt.Select(" gid = '" + c.gid.Trim() + "' ");
            if (drArr.Length > 0)
            {
                KLine lastKLine = c.kLine[c.kLine.Length - 1];
                if (lastKLine.startDateTime.ToShortDateString().Equals(DateTime.Parse(drArr[0]["start_date"].ToString().Trim()).ToShortDateString()))
                {
                    lastKLine.startPrice = double.Parse(drArr[0]["open"].ToString().Trim());
                    lastKLine.endPrice = double.Parse(drArr[0]["settle"].ToString().Trim());
                    lastKLine.highestPrice = double.Parse(drArr[0]["highest"].ToString().Trim());
                    lastKLine.lowestPrice = double.Parse(drArr[0]["lowest"].ToString().Trim());
                    lastKLine.volume = int.Parse(drArr[0]["volume"].ToString().Trim());
                    lastKLine.amount = double.Parse(drArr[0]["amount"].ToString().Trim());
                    c.kLine[c.kLine.Length - 1] = lastKLine;
                }
                else
                {
                    lastKLine = new KLine();
                    lastKLine.startPrice = double.Parse(drArr[0]["open"].ToString().Trim());
                    lastKLine.endPrice = double.Parse(drArr[0]["settle"].ToString().Trim());
                    lastKLine.highestPrice = double.Parse(drArr[0]["highest"].ToString().Trim());
                    lastKLine.lowestPrice = double.Parse(drArr[0]["lowest"].ToString().Trim());
                    lastKLine.volume = int.Parse(drArr[0]["volume"].ToString().Trim());
                    lastKLine.amount = double.Parse(drArr[0]["amount"].ToString().Trim());
                    lastKLine.gid = c.gid;
                    lastKLine.type = "day";
                    lastKLine.startDateTime = DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30");
                    KLine[] kArrNew = new KLine[c.kLine.Length + 1];
                    for (int i = 0; i < c.kLine.Length; i++)
                    {
                        kArrNew[i] = c.kLine[i];
                    }
                    kArrNew[kArrNew.Length - 1] = lastKLine;
                    c.kLine = kArrNew;
                }
            }
            arr.Add(c);
        }
        Stock.kLineCache = arr;
    }

    public static CachedKLine LoadOneKLineToMemory(string path)
    {
        string[] pathArr = path.Split('\\');
        string gid = pathArr[pathArr.Length - 1].Replace(".txt", "");
        CachedKLine c = new CachedKLine();
        c.gid = gid;
        string[] content = File.ReadAllText(path).Split('\r');
        KLine[] kArr = new KLine[content.Length];
        for (int i = 0; i < kArr.Length; i++)
        {
            if (content[i].Trim().Equals(""))
                continue;
            string[] line = content[i].Trim().Split(',');
            kArr[i] = new KLine();
            kArr[i].gid = gid;
            kArr[i].type = "day";
            kArr[i].startDateTime = DateTime.Parse(line[0].Trim());
            kArr[i].startPrice = double.Parse(line[2].Trim());
            kArr[i].endPrice = double.Parse(line[3].Trim());
            kArr[i].highestPrice = double.Parse(line[4].Trim());
            kArr[i].lowestPrice = double.Parse(line[5].Trim());
            kArr[i].volume = int.Parse(line[6].Trim());
            kArr[i].amount = double.Parse(line[7].Trim());
        }
        c.kLine = kArr;
        c.lastUpdate = DateTime.Now;
        c.type = "day";
        return c;
    }

    public static void WriteKLineToFileCache(string gid, KLine[] kArr)
    {
        string marketType = GetMarketType(gid);     
        string rootPath = Util.physicalPath;
        if (!Directory.Exists(rootPath+@"\cache"))
        {
            Directory.CreateDirectory(rootPath + @"\cache");
        }
        if (!Directory.Exists(rootPath + @"\cache\k_line_day"))
        {
            Directory.CreateDirectory(rootPath + @"\cache\k_line_day");
        }
        if (!Directory.Exists(rootPath + @"\cache\k_line_day\" + marketType.Trim()))
        {
            Directory.CreateDirectory(rootPath + @"\cache\k_line_day\" + marketType.Trim());
        }
        string fileName = rootPath + @"\cache\k_line_day\" + marketType.Trim() + @"\" + gid.Trim() + ".txt";
        string content = "";
        foreach (KLine k in kArr)
        {
            content = content + (content.Trim().Equals("") ? "" : "\r\n") + k.startDateTime.ToString() + ","
                + k.endDateTime.ToString() + "," + k.startPrice.ToString() + "," + k.endPrice.ToString() + ","
                + k.highestPrice.ToString() + "," + k.lowestPrice.ToString() + "," + k.volume.ToString() + ","
                + k.amount.ToString();
        }
        try
        {
            if (File.Exists(fileName))
            {
                File.Delete(fileName);
            }
            File.AppendAllText(fileName, content);
        }
        catch
        {
            
        }
    }





    public static void ReadKLineFromFileCache(string gid)
    {
        string marketType = GetMarketType(gid);
        string fileName = Util.physicalPath + @"\cache\k_line_day\" + marketType.Trim() + @"\" + gid.Trim() + ".txt";
        var lines = File.ReadLines(fileName);

    }

}