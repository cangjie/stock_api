using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;
using System.Net;
using System.IO;
using System.Threading;
using System.Text.RegularExpressions;
/// <summary>
/// Summary description for StockWatcher
/// </summary>
public class StockWatcher
{
    public static ThreadStart tsKLineRefresher = new ThreadStart(RefreshKLine);

    public static Thread tKLineRefresher = new Thread(tsKLineRefresher);

    public static ThreadStart tsWatchEachStock = new ThreadStart(WatchEachStock);

    public static Thread tWatchEachStock = new Thread(tsWatchEachStock);

    public static ThreadStart tsLogQuota = new ThreadStart(LogQuota);

    public static Thread tLogQuota = new Thread(tsLogQuota);

    public StockWatcher()
    {
      
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
                    for (int i = 0; i < gidArr.Length; i++)
                    {
                        KLine.RefreshKLine(gidArr[i], DateTime.Parse(DateTime.Now.ToShortDateString()));
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
                    for (int i = 0; i < gidArr.Length; i++)
                    {
                        KLine.RefreshKLine(gidArr[i], DateTime.Parse(DateTime.Now.ToShortDateString()));
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
            if (kArr[index].macd > 0 && kArr[index - 1].macd < 0 && Math.Abs(kArr[index].macd) + Math.Abs(kArr[index - 1].macd) > 0.05)
            {
                ret = true;
            }
        }
        return ret;
    }

    public static bool IsKdjFolk(KLine[] kArr, int index)
    {
        bool ret = false;
        if (kArr[index].j >= kArr[index].k && kArr[index - 1].j <= kArr[index - 1].k && kArr[index].k < 35 && kArr[index].d < 35)
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
            if (Util.IsTransacTime(DateTime.Now))
            {
                try
                {
                    Util.RefreshTodayKLine();
                }
                catch
                {

                }
            }
            Thread.Sleep(1000);
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
                type = type.Replace("volumedecrease", "缩量调整后上涨超3%").Replace("3_line", "底部突破3线").Replace("macd", "MACD金叉");
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


}