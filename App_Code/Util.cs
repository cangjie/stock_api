using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Net;
using System.IO;
using System.Web.Script.Serialization;
using System.Collections;
using System.Data;
using System.Threading;

/// <summary>
/// Summary description for Util
/// </summary>
public class Util
{
    public static string conStr = System.Configuration.ConfigurationSettings.AppSettings["constr"].Trim();

    public static string physicalPath = "";

    public Util()
    {
        //
        // TODO: Add constructor logic here
        //
    }

    public static string GetWebContent(string url, string method, string content, string contentType)
    {
        HttpWebRequest req = (HttpWebRequest)WebRequest.Create(url);
        req.Method = method.Trim();
        req.ContentType = contentType;
        if (!content.Trim().Equals(""))
        {
            StreamWriter sw = new StreamWriter(req.GetRequestStream());
            sw.Write(content);
            sw.Close();
        }
        HttpWebResponse res = (HttpWebResponse)req.GetResponse();
        Stream s = res.GetResponseStream();
        StreamReader sr = new StreamReader(s);
        string str = sr.ReadToEnd();
        sr.Close();
        s.Close();
        res.Close();
        req.Abort();
        return str;
    }

    public static string GetWebContent(string url)
    {
        return GetWebContent(url, "GET", "", "html/text");
    }

    

    public static string GetSimpleJsonValueByKey(string jsonStr, string key)
    {
        JavaScriptSerializer serializer = new JavaScriptSerializer();
        Dictionary<string, object> json = (Dictionary<string, object>)serializer.DeserializeObject(jsonStr);
        object v;
        json.TryGetValue(key, out v);
        return v.ToString();
    }

    public static Dictionary<string, object> GetObjectFromJsonByKey(string jsonStr, string key)
    {
        JavaScriptSerializer serializer = new JavaScriptSerializer();
        Dictionary<string, object> json = (Dictionary<string, object>)serializer.DeserializeObject(jsonStr);
        object v;
        json.TryGetValue(key, out v);
        return (Dictionary<string, object>)v;
    }
/*
    public static Dictionary<string, object[]> GetArrayObjectFromJsonByKey(string jsonStr, string key)
    {
        JavaScriptSerializer serializer = new JavaScriptSerializer();
        object[] oArr = (object[])serializer.DeserializeObject(jsonStr);
        //object[] oArrResult;
        object o = oArr[0];
        
        foreach (object o in (object[])oArr[0])
        {
            try
            {
                Dictionary<string, object[]> json = (Dictionary<string, object[]>)o;
                object[] valueArr;
                json.TryGetValue(key, out valueArr);
            }
            catch
            {

            }
        }
        
        return null;
    } 
*/
    public static Dictionary<string, object>[] GetObjectArrayFromJsonByKey(string jsonStr, string key)
    {
        JavaScriptSerializer serializer = new JavaScriptSerializer();
        Dictionary<string, object> json = (Dictionary<string, object>)serializer.DeserializeObject(jsonStr);
        object v;
        json.TryGetValue(key, out v);
        object[] vArr = (object[])v;
        Dictionary<string, object>[] retArr = new Dictionary<string, object>[vArr.Length];
        for (int i = 0; i < retArr.Length; i++)
        {
            Dictionary<string, object> keyPairObjectArray = (Dictionary<string, object>)vArr[i];
            retArr[i] = keyPairObjectArray;
        }
        return retArr;
    }

    public static object[] GetArrayFromJsonByKey(string jsonStr, string key)
    {
        JavaScriptSerializer serializer = new JavaScriptSerializer();
        Dictionary<string, object> json = (Dictionary<string, object>)serializer.DeserializeObject(jsonStr);
        object v;
        json.TryGetValue(key, out v);
        object[] vArr = (object[])v;  
        return vArr;
    }

    public static string GetSimpleJsonStringFromKeyPairArray(KeyValuePair<string, object>[] vArr)
    {
        string r = "";
        for (int i = 0; i < vArr.Length; i++)
        {
            if (i == 0)
            {
                r = "\"" + vArr[i].Key.Trim() + "\" : \"" + vArr[i].Value.ToString() + "\"";
            }
            else
            {
                r = r + ", \"" + vArr[i].Key.Trim() + "\" : \"" + vArr[i].Value.ToString() + "\" ";
            }
        }
        return "{ " + r + " }";
    }

    public static string GetSafeRequestValue(HttpRequest request, string parameterName, string defaultValue)
    {
        return ((request[parameterName] == null) ? defaultValue : request[parameterName].Trim()).Replace("'", "");
    }

    public static KeyValuePair<string, string>[] GetAllStockCodeAndName()
    {
        ArrayList arr = new ArrayList();
        for (int i = 1; i <= 15; i++)
        {
            string szJson = Util.GetWebContent("http://web.juhe.cn:8080/finance/stock/shall?key=f3e86989786e6af59a105cf2349a85bf&type=4&page=" + i.ToString());
            string errorCode = Util.GetSimpleJsonValueByKey(szJson, "error_code");
            if (errorCode.Equals("0"))
            {
                Dictionary<string, object> result = Util.GetObjectFromJsonByKey(szJson, "result");
                object[] timelineArr = (object[])result["data"];
                foreach (object o in timelineArr)
                {
                    Dictionary<string, object> timeline = (Dictionary<string, object>)o;
                    KeyValuePair<string, string> codeAndName = new KeyValuePair<string, string>(timeline["symbol"].ToString().Trim(), timeline["name"].ToString().Trim());
                    arr.Add(codeAndName);
                }
            }
        }

        for (int i = 1; i <= 30; i++)
        {
            string szJson = Util.GetWebContent("http://web.juhe.cn:8080/finance/stock/szall?key=f3e86989786e6af59a105cf2349a85bf&type=4&page=" + i.ToString());
            string errorCode = Util.GetSimpleJsonValueByKey(szJson, "error_code");
            if (errorCode.Equals("0"))
            {
                Dictionary<string, object> result = Util.GetObjectFromJsonByKey(szJson, "result");
                object[] timelineArr = (object[])result["data"];
                foreach (object o in timelineArr)
                {
                    Dictionary<string, object> timeline = (Dictionary<string, object>)o;
                    KeyValuePair<string, string> codeAndName = new KeyValuePair<string, string>(timeline["symbol"].ToString().Trim(), timeline["name"].ToString().Trim());
                    arr.Add(codeAndName);
                }
            }

        }

        KeyValuePair<string, string>[] kvpArr = new KeyValuePair<string, string>[arr.Count];
        for (int i = 0; i < arr.Count; i++)
        {
            kvpArr[i] = (KeyValuePair<string, string>)arr[i];
        }
        return kvpArr;
    }

    public static string[] GetAllStockCode()
    {
        ArrayList arr = new ArrayList();
        for (int i = 1; i <= 15; i++)
        {
            string szJson = Util.GetWebContent("http://web.juhe.cn:8080/finance/stock/shall?key=f3e86989786e6af59a105cf2349a85bf&type=4&page=" + i.ToString());
            string errorCode = Util.GetSimpleJsonValueByKey(szJson, "error_code");
            if (errorCode.Equals("0"))
            {
                Dictionary<string, object> result = Util.GetObjectFromJsonByKey(szJson, "result");
                object[] timelineArr = (object[])result["data"];
                foreach (object o in timelineArr)
                {
                    Dictionary<string, object> timeline = (Dictionary<string, object>)o;
                    arr.Add(timeline["symbol"].ToString());
                }
            }
        }

        for (int i = 1; i <= 30; i++)
        {
            string szJson = Util.GetWebContent("http://web.juhe.cn:8080/finance/stock/szall?key=f3e86989786e6af59a105cf2349a85bf&type=4&page=" + i.ToString());
            string errorCode = Util.GetSimpleJsonValueByKey(szJson, "error_code");
            if (errorCode.Equals("0"))
            {
                Dictionary<string, object> result = Util.GetObjectFromJsonByKey(szJson, "result");
                object[] timelineArr = (object[])result["data"];
                foreach (object o in timelineArr)
                {
                    Dictionary<string, object> timeline = (Dictionary<string, object>)o;
                    arr.Add(timeline["symbol"].ToString());
                }
            }

        }

        string[] retArr = new string[arr.Count];
        for(int i = 0; i < arr.Count; i++)
        {
            retArr[i] = arr[i].ToString().Trim();
        }
        return retArr;
    }

    public static bool IsTransacDay(DateTime date)
    {
        bool ret = true;
        if ((date.DayOfWeek == DayOfWeek.Saturday) || (date.DayOfWeek == DayOfWeek.Sunday))
        {
            ret = false;
        }
        if (Util.GetDay(date) >= DateTime.Parse("2017-10-1") && Util.GetDay(date) <= DateTime.Parse("2017-10-8"))
            ret = false;
        return ret;
    }

    public static bool IsTransacTime(DateTime date)
    {
        DateTime dateRef = DateTime.Parse(date.ToShortDateString());
        bool ret = false;
        if ((date >= DateTime.Parse(dateRef.ToShortDateString() + " 9:30") && date <= DateTime.Parse(dateRef.ToShortDateString() + " 12:00"))
            || (date >= DateTime.Parse(dateRef.ToShortDateString() + " 13:00") && date <= DateTime.Parse(dateRef.ToShortDateString() + " 20:30")))
            ret = true;
        return ret && IsTransacDay(dateRef);
    }

    public static bool IsTransacTimeReally(DateTime date)
    {
        DateTime dateRef = DateTime.Parse(date.ToShortDateString());
        bool ret = false;
        if ((date >= DateTime.Parse(dateRef.ToShortDateString() + " 9:30") && date < DateTime.Parse(dateRef.ToShortDateString() + " 11:30"))
            || (date >= DateTime.Parse(dateRef.ToShortDateString() + " 13:00") && date < DateTime.Parse(dateRef.ToShortDateString() + " 15:00")))
            ret = true;
        return ret && IsTransacDay(dateRef);
    }

    public static double Compute_3_3_Price(KLine[] kArr, DateTime date)
    {
        double ret = 0;
        for (int i = 5; i < kArr.Length; i++)
        {
            if (kArr[i].startDateTime == date)
            {
                ret = (kArr[i - 5].endPrice + kArr[i - 4].endPrice + kArr[i - 3].endPrice) / 3;
                break;
            }
        }
        return ret;
    }

    public static void RefreshSuggestStockForToday()
    {
        if (IsTransacDay(DateTime.Now) && ((DateTime.Now.Hour ==9 && DateTime.Now.Minute > 28) || DateTime.Now.Hour > 9))
        {
            RefreshSuggestStock(DateTime.Parse(DateTime.Now.ToShortDateString()));
        }
    }

    public static void RefreshSuggestStock(DateTime day)
    {
        KeyValuePair<string, string>[] stockListArr = Util.GetAllStockCodeAndName();
        if (Util.IsTransacDay(day))
        {
            foreach (KeyValuePair<string, string> stock in stockListArr)
            {
                KLine[] kArr = IsSuggest(day, stock.Key.Trim());
                if (kArr.Length > 5)
                {
                    try
                    {
                        Stock stockObj = new Stock();
                        stockObj.gid = stock.Key.Trim();
                        stockObj.kArr = kArr;

                        DBHelper.InsertData("suggest_stock", new string[,]{
                            { "suggest_date", "datetime", day.ToShortDateString() },
                            { "gid", "varchar", stock.Key.Trim()},
                            { "[name]", "varchar", stock.Value.Trim()},
                            { "settlement", "float", kArr[kArr.Length - 2].endPrice.ToString()},
                            { "[open]", "float", kArr[kArr.Length - 1].startPrice.ToString()},
                            { "avg_3_3_yesterday", "float", Compute_3_3_Price(kArr, kArr[kArr.Length - 2].startDateTime).ToString()},
                            { "avg_3_3_today", "float", Compute_3_3_Price(kArr, kArr[kArr.Length - 1].startDateTime).ToString()},
                            { "double_cross_3_3", "int", (stockObj.IsCross3X3Twice(day, 20)? "1" : "0")},
                            { "last_day_over_flow", "float", stockObj.yesterdayPositiveRate(day).ToString()}
                        });
                    }
                    catch
                    {
                        
                    }
                    
                    
                }
            }
        }

    }

    public static KLine[] IsSuggest(DateTime day, string stockCode)
    {
        Stock stock = new Stock(stockCode);
        if (stock.IsCross3X3(day))
            return stock.kArr;
        else
            return new KLine[0];
    }

    public static int currentKLineIndex = 0;

    public static void  RefreshTodayKLine()
    {
        string[] gidArr = GetAllGids();
        for (int i = 0; i < gidArr.Length; i++)
        {
            try
            {
                KLine.RefreshKLine(gidArr[i], DateTime.Parse(DateTime.Now.ToShortDateString()));
                CachedKLine c = new CachedKLine();
                c.gid = gidArr[i];
                c.type = "day";
                c.kLine = Stock.LoadLocalKLineFromDB(c.gid, "day");
                c.lastUpdate = DateTime.Now;
                KLineCache.UpdateKLineInCache(c);
                currentKLineIndex = i;
            }
            catch
            {

            }
        }
    }



    public static Queue gidQueue = new Queue();

    public static void RefreshTodayKLineMultiThread()
    {
        if (gidQueue.Count == 0)
        {
            string[] gidArr = Util.GetAllGids();
            foreach (string gid in gidArr)
            {
                gidQueue.Enqueue(gid);
            }
        }
        for (; gidQueue.Count > 0;)
        {
            ThreadStart tsKLine = new ThreadStart(RefreshTodayKLineFromQueue);
            Thread t = new Thread(tsKLine);
            t.Start();
        }
    }

    public static void RefreshTodayKLineFromQueue()
    {
        try
        {
            string gid = gidQueue.Dequeue().ToString();
            KLine.RefreshKLine(gid, DateTime.Parse(DateTime.Now.ToShortDateString()));
        }
        catch
        {

        }
    }

    public static string[] GetAllGids()
    {
        if (KLineCache.allGid.Length == 0)
        {
            DataTable dt = DBHelper.GetDataTable(" select [name]  from dbo.sysobjects where OBJECTPROPERTY(id, N'IsUserTable') = 1 and name like '%timeline'");
            string[] gidArr = new string[dt.Rows.Count];
            for (int i = 0; i < dt.Rows.Count; i++)
            {
                gidArr[i] = dt.Rows[i][0].ToString().Replace("_timeline", "");
            }
            dt.Dispose();
            KLineCache.allGid = gidArr;
            return gidArr;
        }
        else
        {
            return KLineCache.allGid;
        }

    }

    public static DateTime GetDay(DateTime dateTime)
    {
        return DateTime.Parse(dateTime.ToShortDateString());
    }

    public static DateTime GetTime(DateTime dateTime)
    {
        return DateTime.Parse(dateTime.ToShortTimeString());
    }

    public static double[] GetRaiseGoldLine(double lowPrice, double highPrice)
    {
        double[] priceArr = new double[9];
        double diff = highPrice - lowPrice;
        priceArr[0] = lowPrice;
        priceArr[1] = lowPrice + diff * 0.236;
        priceArr[2] = lowPrice + diff * 0.382;
        priceArr[3] = lowPrice + diff * 0.5;
        priceArr[4] = lowPrice + diff * 0.618;
        priceArr[5] = lowPrice + diff * 0.809;
        priceArr[6] = highPrice;
        priceArr[7] = lowPrice + diff * 1.382;
        priceArr[8] = lowPrice + diff * 1.618;
        return priceArr;
    }

    public static double GetBuyPrice(double lowPrice, double highPrice, double currentPrice)
    {
        double[] priceArr = GetRaiseGoldLine(lowPrice, highPrice);
        double price = 0;
        for (int i = 0; i < priceArr.Length; i++)
        {
            if (i == 3)
                continue;
            if (Math.Abs(currentPrice - priceArr[i]) / currentPrice <= 0.005)
            {
                price = Math.Max(currentPrice, priceArr[i]);
            }
        }
        if (price == 0)
            price = currentPrice;
        return price;
    }

    public static DateTime GetLastTransactDate(DateTime currentDate, int days)
    {
        DateTime nowDate = currentDate;
        int i = 0;
        if (!Util.IsTransacDay(nowDate))
            i--;
        for (; i < days; i++)
        {
            nowDate = nowDate.AddDays(-1);
            if (!Util.IsTransacDay(nowDate))
                i--;
        }
        return nowDate;
    }
}