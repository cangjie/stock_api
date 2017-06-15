using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;

/// <summary>
/// Summary description for KLine
/// </summary>
public class KLine
{
    public string type = "day";
    public DateTime startDateTime;
    
    public double startPrice = 0;
    public double endPrice = 0;
    public double highestPrice = 0;
    public double lowestPrice = 0;
    public string gid = "";
    public double deal = 0;
    public double volume = 0;
    public double change = 0;

    public KLine()
    {
        //
        // TODO: Add constructor logic here
        //
    }

    public int save()
    {
        return 0;
    }

    public DateTime endDateTime
    {
        get
        {
            DateTime endTime = startDateTime;
            switch (type.Trim())
            {
                case "day":
                    endTime = startDateTime;
                    break;
                default:
                    break;
            }
            return endTime;
        }
    }


    public static KLine[] GetKLine(string type, string gid, DateTime startDateTime, DateTime endDateTime)
    {
        KLine[] kLineArr = new KLine[0];
        switch (type.Trim())
        {
            case "day":
                kLineArr = GetKLineDayFromSohu(gid, startDateTime, endDateTime);
                break;
            default:
                break;
        }
        return kLineArr;
    }

    public static string GetKLineDayJSONFromSohu(string gid, DateTime startDate, DateTime endDate)
    {
        string code = gid.Replace("sh", "cn_").Replace("sz", "cn_");
        if (code.StartsWith("3"))
            code = "cn_" + code;
        string startDateStr = startDate.Year.ToString() + startDate.Month.ToString().PadLeft(2, '0') 
            + startDate.Day.ToString().PadLeft(2, '0');
        //endDate = endDate.AddDays(1);
        string endDateStr = endDate.Year.ToString() + endDate.Month.ToString().PadLeft(2, '0')
            + endDate.Day.ToString().PadLeft(2, '0');
        string urlStr = "http://q.stock.sohu.com/hisHq?code=" + code + "&start=" + startDateStr + "&end=" + endDateStr;       
        return Util.GetWebContent(urlStr);
    }

    public static KLine[] GetKLineDayFromSohu(string gid, DateTime startDate, DateTime endDate)
    {
        string kLineJsonStr = GetKLineDayJSONFromSohu(gid, startDate, endDate).Trim();
        if (kLineJsonStr.Trim().Equals("{}"))
            return new KLine[0];
        if (kLineJsonStr.StartsWith("["))
        {
            kLineJsonStr = kLineJsonStr.Remove(0, 1);
        }
        if (kLineJsonStr.EndsWith("]"))
        {
            kLineJsonStr = kLineJsonStr.Remove(kLineJsonStr.Length - 1, 1);
        }
        object[] oArr = Util.GetArrayFromJsonByKey(kLineJsonStr, "hq");
        KLine[] kLineArr = new KLine[oArr.Length];
        for (int i = 0; i < oArr.Length; i++ )
        {
            object[] kLineData = (object[])oArr[i];
            KLine kLine = new KLine();
            kLine.type = "day";
            kLine.startDateTime = DateTime.Parse(kLineData[0].ToString());
            kLine.startPrice = double.Parse(kLineData[1].ToString());
            kLine.endPrice = double.Parse(kLineData[2].ToString());
            kLine.highestPrice = double.Parse(kLineData[6].ToString());
            kLine.lowestPrice = double.Parse(kLineData[5].ToString());
            kLine.gid = gid.Trim();
            kLine.deal = double.Parse(kLineData[7].ToString());
            kLine.volume = double.Parse(kLineData[8].ToString());
            kLine.change = double.Parse(kLineData[9].ToString().Replace("%", ""));
            kLineArr[oArr.Length - 1 - i] = kLine;
        }
        if (endDate >= DateTime.Parse(DateTime.Now.ToShortDateString()) && Util.IsTransacDay(endDate) 
            && kLineArr[kLineArr.Length - 1].startDateTime < endDate )
        {
            KLine k = GetTodayKLine(gid);
            if (k!=null)
            {
                KLine[] kLineArrNew = new KLine[kLineArr.Length + 1];

                for (int i = 0; i < kLineArr.Length; i++)
                {
                    kLineArrNew[i] = kLineArr[i];
                }
                kLineArrNew[kLineArr.Length] = k;
                return kLineArrNew;
            }
            
        }
        return kLineArr;
    }

    public static KLine GetTodayKLine(string stockCode)
    {
        if (Util.IsTransacDay(DateTime.Now))
        {
            DateTime nowDate = DateTime.Parse(DateTime.Now.ToShortDateString());
            string sqlStr = " select  * from " + stockCode.Trim() + "_timeline  where ticktime >= '" + nowDate.ToShortDateString()
                + "' and ticktime < '" + nowDate.AddDays(1).ToShortDateString() + "' order by ticktime desc ";
            DataTable dt = DBHelper.GetDataTable(sqlStr);
            if (dt.Rows.Count > 1)
            {
                KLine k = new KLine();
                k.type = "day";
                k.startDateTime = nowDate;
                k.startPrice = double.Parse(dt.Rows[0]["open"].ToString());
                k.highestPrice = double.Parse(dt.Rows[0]["high"].ToString());
                k.lowestPrice = double.Parse(dt.Rows[0]["low"].ToString());
                k.endPrice = double.Parse(dt.Rows[0]["buy"].ToString());
                k.gid = stockCode;
                return k;
            }
            else
                return null;

        }
        else
            return null;
    }
     




}