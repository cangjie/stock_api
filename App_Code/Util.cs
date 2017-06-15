using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Net;
using System.IO;
using System.Web.Script.Serialization;
using System.Collections;
using System.Data;

/// <summary>
/// Summary description for Util
/// </summary>
public class Util
{
    public static string conStr = System.Configuration.ConfigurationSettings.AppSettings["constr"].Trim();

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
        if ((date.DayOfWeek == DayOfWeek.Saturday) || (date.DayOfWeek == DayOfWeek.Saturday))
        {
            ret = false;
        }
        return ret;
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
        if (IsTransacDay(DateTime.Now))
        {
            RefreshSuggestStock(DateTime.Parse(DateTime.Now.ToShortDateString()));
        }
    }

    public static void RefreshSuggestStock(DateTime day)
    {
        /*
        DateTime start = day;
        DateTime end = day;
        DataTable dt = new DataTable();
        dt.Columns.Add("date");
        dt.Columns.Add("gid");
        dt.Columns.Add("name");
        dt.Columns.Add("settlement");
        dt.Columns.Add("avg3_yesterday");
        dt.Columns.Add("avg3_today");
        dt.Columns.Add("open");
        */
        //string[] stockListArr = Util.GetAllStockCode();
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
                        DBHelper.InsertData("suggest_stock", new string[,]{
                            { "suggest_date", "datetime", day.ToShortDateString() },
                            { "gid", "varchar", stock.Key.Trim()},
                            { "[name]", "varchar", stock.Value.Trim()},
                            { "settlement", "float", kArr[kArr.Length - 2].endPrice.ToString()},
                            { "[open]", "float", kArr[kArr.Length - 1].startPrice.ToString()},
                            { "avg_3_3_yesterday", "float", Compute_3_3_Price(kArr, kArr[kArr.Length - 2].startDateTime).ToString()},
                            { "avg_3_3_today", "float", Compute_3_3_Price(kArr, kArr[kArr.Length - 1].startDateTime).ToString()}
                        });
                    }
                    catch(Exception e)
                    {
                        
                    }
                    

                    
                    /*

                    DataRow dr = dt.NewRow();
                    double price_3_3_yesterday = Util.Compute_3_3_Price(kArr, kArr[kArr.Length - 2].startDateTime);
                    double price_3_3_today = Util.Compute_3_3_Price(kArr, kArr[kArr.Length - 1].startDateTime);
                    dr["date"] = day;
                    dr["gid"] = stock.Key.Trim();
                    dr["name"] = stock.Value.Trim();
                    dr["settlement"] = kArr[kArr.Length - 2].endPrice;
                    dr["avg3_yesterday"] = Compute_3_3_Price(kArr, kArr[kArr.Length - 2].startDateTime);
                    dr["avg3_today"] = Compute_3_3_Price(kArr, kArr[kArr.Length - 1].startDateTime);
                    dr["open"] = kArr[kArr.Length - 1].startPrice;
                    dt.Rows.Add(dr);
                    */
                }
            }
        }

    }

    public static KLine[] IsSuggest(DateTime day, string stockCode)
    {
        KLine[] kArr = KLine.GetKLine("day", stockCode, day.AddMonths(-1), day);
        if (kArr.Length < 6)
            return new KLine[0];
        double price_3_3_yesterday = Util.Compute_3_3_Price(kArr, kArr[kArr.Length - 2].startDateTime);
        double price_3_3_today = Util.Compute_3_3_Price(kArr, kArr[kArr.Length - 1].startDateTime);
        if (kArr[kArr.Length - 2].endPrice < price_3_3_yesterday
            && kArr[kArr.Length - 1].startPrice > kArr[kArr.Length - 2].endPrice
            && kArr[kArr.Length - 1].startPrice > price_3_3_today
            && kArr[kArr.Length - 2].endPrice != 0 && kArr[kArr.Length - 1].startPrice != 0
            )
        {
            return kArr;
        }
        return new KLine[0];
    }
}