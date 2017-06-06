using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Net;
using System.IO;
using System.Web.Script.Serialization;

/// <summary>
/// Summary description for Util
/// </summary>
public class Util
{
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

}