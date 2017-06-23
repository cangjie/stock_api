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
                }
                catch
                {

                }
            }
            Thread.Sleep(1000);
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
                if (Math.Round(s.LastTrade, 2) == Math.Round(double.Parse(dr["top_f3"].ToString()), 2))
                {
                    message = s.gid + dr["name"].ToString() + " 现价：" + Math.Round(s.LastTrade, 2).ToString() + " 已经达到压力F3";
                    //SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", message);
                }
                if (Math.Round(s.LastTrade, 2) == Math.Round(double.Parse(dr["top_f5"].ToString()), 2))
                {
                    message = s.gid + dr["name"].ToString() + " 现价：" + Math.Round(s.LastTrade, 2).ToString() + " 已经达到压力F5";
                }
                if (Math.Round(s.LastTrade, 2) == Math.Round(double.Parse(dr["bottom_f3"].ToString()), 2))
                {
                    message = s.gid + dr["name"].ToString() + " 现价：" + Math.Round(s.LastTrade, 2).ToString() + " 已经达到支撑F3";
                }
                if (Math.Round(s.LastTrade, 2) == Math.Round(double.Parse(dr["bottom_f5"].ToString()), 2))
                {
                    message = s.gid + dr["name"].ToString() + " 现价：" + Math.Round(s.LastTrade, 2).ToString() + " 已经达到支撑F5";
                }
                if (!message.Trim().Equals(""))
                {
                    SendAlertMessage("oqrMvtySBUCd-r6-ZIivSwsmzr44", message.Trim());
                    SendAlertMessage("oqrMvt6-N8N1kGONOg7fzQM7VIRg", message.Trim());
                }

            }
            catch
            {

            }
            
        }  
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