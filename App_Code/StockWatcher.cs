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
    

    public static ThreadStart ts = new ThreadStart(StartWatch);

    public static Thread thread = new Thread(ts) ;

    public static ThreadStart tsKLineRefresher = new ThreadStart(RefreshKLine);

    public static Thread tKLineRefresher = new Thread(tsKLineRefresher);

    public static ThreadStart tsKDJ = new ThreadStart(WatchKDJ);

    public static Thread tKDJ = new Thread(tsKDJ);

    public StockWatcher()
    {
        //
        // TODO: Add constructor logic here
        //
    }

    public static void StartWatch()
    {
        for (; true;)
        {
            if (Util.IsTransacTime(DateTime.Now))
            {
                try
                {
                    WatchStar();
                    Watch();
                    WatchEachStock();
                    WatchWave();
                    
                }
                catch
                {

                }
            }
            Thread.Sleep(1000);
        }
    }

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

    public static void WatchStar()
    {
        try
        {


            string content = Util.GetWebContent("http://stock.tuyaa.com/promote_stock_by_3x3_new_gold.aspx");
            Regex reg = new Regex("alt=\"\\d\\d\\d\\d\\d\\d\"");
            MatchCollection mc = reg.Matches(content);
            foreach (Match m in mc)
            {
                string gid = m.Value.Trim().Replace("alt=\"", "").Replace("\"", "");
                if (gid.StartsWith("600"))
                    gid = "sh" + gid;
                else
                    gid = "sz" + gid;
                Stock s = new Stock(gid);
                string name = s.Name.Trim();
                string message = "[" + gid + "]" + name + " was marked star just now.";
                if (AddAlert(DateTime.Parse(DateTime.Now.ToShortDateString()), gid, "star", name, message))
                {
                    SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", gid, name, s.LastTrade, "star");
                    SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", gid, name, s.LastTrade, "star");
                    //SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", message.Trim());
                    //SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", message.Trim());
                    //SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", message.Trim());
                }
            }
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
        string url =   "http://stocks.sina.cn/sh/level2?code=" + gid + "&vt=4";
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
                first = type.Replace("top", "压力位").Replace("bottom", "支撑位").Replace("wave", "波段").Replace("low", "低位").Replace("high", "高位").Trim().Replace("over3line", "突破三线").Replace("volumeincrease", "放量");
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

    public static void WatchEachStock()
    {
        
        if (Util.IsTransacTime(DateTime.Now))
            return;
            
        DataTable dt = DBHelper.GetDataTable(" select [name]  from dbo.sysobjects where OBJECTPROPERTY(id, N'IsUserTable') = 1 and name like '%timeline'");
        foreach (DataRow dr in dt.Rows)
        {
            Stock s = new Stock(dr[0].ToString().Replace("_timeline", ""));
            s.kArr = KLine.GetKLine("day", s.gid, DateTime.Now.AddDays(-50), DateTime.Now);
            if (s.IsOver3X3(DateTime.Parse(DateTime.Now.ToShortDateString())))
            {
                string stockName = s.Name;
                string message = s.gid.Trim() + "[" + stockName.Trim() + "]已经突破3线，并且当日涨幅超过2%";
                if (AddAlert(DateTime.Now, s.gid, "over3line", s.Name.Trim(), message.Trim()))
                {
                    /*
                    SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", s.gid, stockName, s.LastTrade, "over3line");
                    SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", s.gid, stockName, s.LastTrade, "over3line");
                    SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", s.gid, stockName, s.LastTrade, "over3line");
                    */

                    try
                    {
                        double yesterdayPositiveRate = s.yesterdayPositiveRate(DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30"));
                        DBHelper.InsertData("suggest_stock", new string[,]{
                            { "suggest_date", "datetime", DateTime.Now.ToShortDateString() },
                            { "gid", "varchar", s.gid},
                            { "[name]", "varchar", s.Name},
                            { "settlement", "float", s.kArr[s.kArr.Length-1].endPrice.ToString()},
                            { "[open]", "float", s.kArr[s.kArr.Length-1].startPrice.ToString()},
                            { "avg_3_3_yesterday", "float", s.GetAverageSettlePrice(s.kArr.Length - 2, 3, 3).ToString()},
                            { "avg_3_3_today", "float", s.GetAverageSettlePrice(s.kArr.Length - 1, 3, 3).ToString()},
                            { "double_cross_3_3", "int", (s.IsCross3X3Twice(DateTime.Parse(DateTime.Now.ToShortDateString()), 20)? "1" : "0")},
                            { "last_day_over_flow", "float", yesterdayPositiveRate.ToString()},
                            { "is_cross_3_3", "int", "1"}
                        });
                    }
                    catch
                    {

                    }


                    //SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", message.Trim());
                    //SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", message.Trim());
                    //SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", message.Trim());
                }
            }

            DateTime volumeTime = GetVolumeIncrease(s.gid, DateTime.Parse(DateTime.Now.ToShortDateString()), true);
            if (volumeTime > DateTime.Parse("2011-1-1"))
            {
                string stockName = s.Name;
                string message = s.gid.Trim() + "[" + stockName.Trim() + "]放量";
                if (AddAlert(volumeTime, s.gid, "volumeincrease", s.Name.Trim(), message.Trim()))
                {
                    //SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", s.gid, stockName, s.LastTrade, "volumeincrease");
                    //SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", s.gid, stockName, s.LastTrade, "volumeincrease");
                    SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", s.gid, stockName, s.LastTrade, "volumeincrease");

                }
            }


        }
    }

    public static void WatchWave()
    {
        DataTable dt = DBHelper.GetDataTable(" select gid from stock_wave_attention ");
        foreach (DataRow dr in dt.Rows)
        {
            Stock s = new Stock(dr[0].ToString());
            if (s.IsAtBuyPoint)
            {
                string name = s.Name;
                string message = s.gid + "[" + name + "]" + " 低价：" + s.drLastTimeline["trade"].ToString();
                if (AddAlert(DateTime.Parse(DateTime.Now.ToShortDateString()), s.gid, "wave_low", name, message))
                {
                    SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", s.gid, name, s.LastTrade, "wave_low");
                    SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", s.gid, name, s.LastTrade, "wave_low");
                    //SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", message.Trim());
                    //SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", message.Trim());
                    //SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", message.Trim());
                }
            }
            if (s.IsAtSellPoint)
            {
                string name = s.Name;
                string message = s.gid + "[" + name + "]" + " 高价：" + s.drLastTimeline["trade"].ToString();
                if (AddAlert(DateTime.Parse(DateTime.Now.ToShortDateString()), s.gid, "wave_high", name, message))
                {
                    SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", s.gid, name, s.LastTrade, "wave_high");
                    SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", s.gid, name, s.LastTrade, "wave_high");
                    //SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", message.Trim());
                    //SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", message.Trim());
                    //SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", message.Trim());
                }
            }
        }
    }

    public static void Watch()
    {
        try
        {


            DataTable dt = DBHelper.GetDataTable(" select * from stock_alert ");
            foreach (DataRow dr in dt.Rows)
            {
                try
                {
                    Stock s = new Stock(dr["gid"].ToString().Trim().StartsWith("6") ? "sh" + dr["gid"].ToString().Trim() : "sz" + dr["gid"].ToString().Trim());
                    string message = "";
                    string type = "";
                    if (Math.Round(s.LastTrade, 2) == Math.Round(double.Parse(dr["top_f3"].ToString()), 2))
                    {
                        type = "top_f3";
                        message = s.gid + dr["name"].ToString() + " 现价：" + Math.Round(s.LastTrade, 2).ToString() + " 已经达到压力F3";
                        //SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", message);
                    }
                    if (Math.Round(s.LastTrade, 2) == Math.Round(double.Parse(dr["top_f5"].ToString()), 2))
                    {
                        type = "top_f5";
                        message = s.gid + dr["name"].ToString() + " 现价：" + Math.Round(s.LastTrade, 2).ToString() + " 已经达到压力F5";
                    }
                    if (Math.Round(s.LastTrade, 2) == Math.Round(double.Parse(dr["bottom_f3"].ToString()), 2))
                    {
                        type = "bottom_f3";
                        message = s.gid + dr["name"].ToString() + " 现价：" + Math.Round(s.LastTrade, 2).ToString() + " 已经达到支撑F3";
                    }
                    if (Math.Round(s.LastTrade, 2) == Math.Round(double.Parse(dr["bottom_f5"].ToString()), 2))
                    {
                        type = "bottom_f5";
                        message = s.gid + dr["name"].ToString() + " 现价：" + Math.Round(s.LastTrade, 2).ToString() + " 已经达到支撑F5";
                    }
                    if (!message.Trim().Equals(""))
                    {
                        if (AddAlert(DateTime.Now, s.gid, type, dr["name"].ToString().Trim(), message))
                        {
                            string name = s.Name.Trim();
                            SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", s.gid, name, s.LastTrade, type);
                            SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", s.gid, name, s.LastTrade, type);
                            SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", s.gid, name, s.LastTrade, type);
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
        catch(Exception e)
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

    public static void WatchKDJ()
    {
        for (; true;)
        {
            foreach (string gid in Util.GetAllGids())
            {
                if (Util.IsTransacTime(DateTime.Now))
                {
                    try
                    {
                        KLine.SearchKDJAlert(gid, "day", DateTime.Now);
                        KLine.SearchKDJAlert(gid, "1hr", DateTime.Now);
                        KLine.SearchKDJAlert(gid, "30min", DateTime.Now);
                        KLine.SearchKDJAlert(gid, "15min", DateTime.Now);
                    }
                    catch
                    {

                    }
                }
            }
            Thread.Sleep(1000);
        }
    }
}