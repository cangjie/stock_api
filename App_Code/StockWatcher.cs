using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;
using System.Net;
using System.IO;
using System.Threading;
/// <summary>
/// Summary description for StockWatcher
/// </summary>
public class StockWatcher
{
    

    public static ThreadStart ts = new ThreadStart(StartWatch);

    public static Thread thread = new Thread(ts) ;

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
            if (Util.IsTransacDay(DateTime.Parse(DateTime.Now.ToShortDateString())) && DateTime.Now.Hour >= 9 && DateTime.Now.Hour <= 15)
            {
                try
                {
                    Watch();
                    WatchEachStock();
                }
                catch
                {

                }
            }
            Thread.Sleep(1000);
        }
    }

    public static void WatchEachStock()
    {
        DataTable dt = DBHelper.GetDataTable(" select [name]  from dbo.sysobjects where OBJECTPROPERTY(id, N'IsUserTable') = 1 and name like '%timeline'");
        foreach (DataRow dr in dt.Rows)
        {
            Stock s = new Stock(dr[0].ToString().Replace("_timeline", ""));
            s.kArr = KLine.GetKLine("day", s.gid, DateTime.Now.AddDays(-50), DateTime.Now);
            if (s.IsOver3X3(DateTime.Parse(DateTime.Now.ToShortDateString())))
            {
                string stockName = s.Name;
                string message = s.gid.Trim() + "[" + stockName.Trim() + "]已经突破3线，并且当日涨幅超过5%";
                if (AddAlert(DateTime.Now, s.gid, "over3line", s.Name.Trim(), message.Trim()))
                {
                    SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", message.Trim());
                    //SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", message.Trim());
                    SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", message.Trim());
                }
            }


        }
    }

    public static void Watch()
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
                        SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", message.Trim());
                        SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", message.Trim());
                        SendAlertMessage("oqrMvt8K6cwKt5T1yAavEylbJaRs", message.Trim());
                    }
                }

            }
            catch
            {

            }
            
        }  
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
}