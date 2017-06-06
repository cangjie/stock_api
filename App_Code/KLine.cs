using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

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
        return kLineArr;
    }




}