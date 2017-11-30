﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;
using System.Text.RegularExpressions;
using System.Collections;
/// <summary>
/// Summary description for Stock
/// </summary>
/// 

public struct CachedKLine
{
    public string gid;
    public string type;
    public DateTime lastUpdate;
    public KLine[] kLine;
}

public class Stock
{
    public string gid = "";

    public KLine[] kArr;

    public DataRow drLastTimeline;

    public double shakeRate = 0.02;

    public KLine[] kLineDay;

    public KLine[] kLineHour;

    public KLine[] kLineHalfHour;

    public KLine[] kLineQuaterHour;

    public static ArrayList kLineCache = new ArrayList();

    public Stock()
    {
        //
        // TODO: Add constructor logic here
        //
    }

    public Stock(string gid)
    {
        this.gid = gid;
        DataTable dt = DBHelper.GetDataTable(" select top 1 * from " + gid.Trim() + "_timeline where trade > 0   order by ticktime desc ");
        if (dt.Rows.Count > 0)
            drLastTimeline = dt.Rows[0];
    }

    public void LoadKLineDay()
    {
        kLineDay = LoadLocalKLine(gid, "day");
        kArr = kLineDay;
    }

    public string Name
    {
        get
        {
            string ret = "";
            DataTable dt = DBHelper.GetDataTable(" select top 1 [name] from " + gid.Trim() + "_timeline ");
            if (dt.Rows.Count > 0)
            {
                ret = dt.Rows[0][0].ToString().Trim();
            }
            dt.Dispose();
            return ret;
        }
    }

    public double GetAverageSettlePrice(int index, int itemsCount, int displacement)
    {
        if (index - displacement - itemsCount + 1 < 0)
            return 0;
        double sum = 0;
        for (int i = 0; i < itemsCount; i++)
        {
            sum = sum + kArr[index - displacement - i].endPrice;
        }
        return sum / itemsCount;
    }

    public int GetItemIndex(DateTime currentDate)
    {
        if (currentDate.Hour == 0 && currentDate.Minute == 0)
        {
            currentDate = DateTime.Parse(currentDate.ToShortDateString() + " 9:30");
        }
        int k = -1;
        for (int i = kArr.Length - 1; i >= 0; i--)
        {
            DateTime startDateTime = kArr[i].startDateTime;
            if (startDateTime.Hour == 0 && startDateTime.Minute == 0)
                startDateTime = DateTime.Parse(startDateTime.ToShortDateString() + " 9:30");
            if (startDateTime == currentDate
                || (kArr[i].type.Trim().Equals("day") && startDateTime.ToShortDateString().Equals(currentDate.ToShortDateString())))
            {
                k = i;
                break;
            }
        }
        return k;
    }

    public static int GetItemIndex(KLine[] kArr, DateTime currentDateTime)
    {
        int ret = -1;
        for (int i = kArr.Length - 1; i >= 0; i--)
        {
            if (kArr[i].endDateTime == currentDateTime)
            {
                ret = i;
                break;
            }
        }
        return ret;
    }

    public static int GetItemIndex(DateTime currentDateTime, KLine[] kArr)
    {
        int index = -1;
        DateTime indexDate = currentDateTime;
        for (; !Util.IsTransacDay(indexDate) || !Util.IsTransacTimeReally(indexDate); indexDate = indexDate.AddMinutes(-1))
        {

        }
        for (int i = kArr.Length - 1; i >= 0; i--)
        {
            if (kArr[i].startDateTime <= indexDate && kArr[i].endDateTime > indexDate)
            {
                index = i;
                break;
            }
        }
        return index;
    }

    public bool IsCross3Line(int index, string type)
    {
        bool ret = false;
        KLine[] kArr = kLineDay;
        if (index < kArr.Length && index > 5)
        {
            double lastDay3LinePrice = GetAverageSettlePrice(index - 1, 3, 3);
            double currentDay3LinePrice = GetAverageSettlePrice(index, 3, 3);
            if ((kArr[index - 1].endPrice < lastDay3LinePrice && kArr[index].startPrice > currentDay3LinePrice)
                || (kArr[index].startPrice < currentDay3LinePrice && kArr[index].highestPrice > currentDay3LinePrice))
            {
                ret = true;
            }
        }
        return ret;
    }

    public double LastTrade
    {
        get
        {
            DateTime currentDate = DateTime.Now;
            double ret = 0;
            DataTable dtTimeline = DBHelper.GetDataTable(" select top 1 * from  " + gid.Trim() + "_timeline where ticktime <= '" + currentDate.ToString() + "' order by ticktime desc ");
            DataTable dtNormal = DBHelper.GetDataTable(" select top 1 * from  " + gid + " where convert(datetime, date + ' ' + time )  <= '" + currentDate.ToString() + "'  order by convert(datetime, date + ' ' + time ) desc   ");
       
            DateTime timeLineTick = DateTime.Parse(DateTime.Now.ToShortDateString());
            DateTime normalTick = DateTime.Parse(DateTime.Now.ToShortDateString());
            if (dtTimeline.Rows.Count > 0)
            {
                timeLineTick = DateTime.Parse(dtTimeline.Rows[0]["ticktime"].ToString());

            }
            if (dtNormal.Rows.Count > 0)
            {
                normalTick = DateTime.Parse(dtNormal.Rows[0]["date"].ToString() + " " + dtNormal.Rows[0]["time"].ToString());
            }
            if (normalTick > timeLineTick)
            {
                ret = double.Parse(dtNormal.Rows[0]["nowPri"].ToString());
            }
            else
            {
                if (dtTimeline.Rows.Count > 0)
                {
                    ret = double.Parse(dtTimeline.Rows[0]["trade"].ToString());
                }
            }
            return ret;




            /*
            if (drLastTimeline != null)
            {
                return double.Parse(drLastTimeline["trade"].ToString().Trim());
            }
            else
                return 0;
                */
        }
    }

    public int GoingDows3LineCount(int index)
    {
        int count = 0;
        for (int i = index; i > 5; i--)
        {
            double current3LinePrice = GetAverageSettlePrice(i, 3, 3);
            double last3LinePrice = GetAverageSettlePrice(i - 1, 3, 3);
            if (current3LinePrice < last3LinePrice)
            {
                count++;
            }
            else
            {
                break;
            }
        }
        return count;
    }

    public int Under3LineKLines(int index)
    {
        int count = 0;
        for (int i = index - 1; i > 5; i--)
        {
            double current3LinePrice = GetAverageSettlePrice(i - 1, 3, 3);
            if (kArr[i-1].startPrice < current3LinePrice && kArr[i-1].endPrice < current3LinePrice)
            {
                count++;
            }
            else
            {
                break;
            }
        }
        return count;
    }

    public int macdDays(int index)
    {
        int days = -1;
        KLine.ComputeMACD(kLineDay);
        for (int i = index; i > 0; i--)
        {
            if (kLineDay[i].macd >= 0)
            {
                days++;
            }
            else
            {
                break;
            }
        }

        return days;
    }

    public static int macdItems(int index, KLine[] kArr)
    {
        int itmes = -1;
        KLine.ComputeMACD(kArr);
        for (int i = index; i > 0; i--)
        {
            if (kArr[i].macd >= 0)
            {
                itmes++;
            }
            else
            {
                break;
            }
        }

        return itmes;
    }

    public int kdjDays(int index)
    {
        int days = -1;
        KLine.ComputeRSV(kLineDay);
        KLine.ComputeKDJ(kLineDay);
        for (int i = index; i > 0; i--)
        {
            if (StockWatcher.IsKdjFolk(kLineDay, i))
            {
                days++;
                break;
            }
            else if (kLineDay[i].j > kLineDay[i].k && kLineDay[i].k > kLineDay[i].d)
            {
                days++;
            }
            else
            {
                break;
            }
        }
        return days;
    }

    public static CachedKLine GetKLineInCache(string gid, string type)
    {
        CachedKLine kLine = new CachedKLine();
        kLine.gid = "";
        try
        {
            for (int i = 0; i < kLineCache.Count; i++)
            {
                CachedKLine cachedKLine = (CachedKLine)kLineCache[i];
                if (cachedKLine.gid.Trim().Equals(gid) && cachedKLine.type.Trim().Equals(type))
                {
                    kLine = cachedKLine;
                    break;
                }
            }
        }
        catch
        {

        }
        return kLine;
    }

    public static CachedKLine[] GetKLineSetArray(string[] gidArr, string type, int groupSize)
    {
        ArrayList retArrayList = new ArrayList();
        int currentIndex = 0;
        for (int i = 0; i < gidArr.Length; i++)
        {
            
            if (((i + 1) / groupSize) * groupSize == i + 1)
            {
                currentIndex = i;
                string[] subGidArr = new string[groupSize];
                for (int j = 0; j < groupSize; j++)
                {
                    subGidArr[j] = gidArr[i - j];
                }
                CachedKLine[] cacheArr = GetKLineSetArray(subGidArr, type);
                for (int j = 0; j < cacheArr.Length; j++)
                {
                    retArrayList.Add(cacheArr[j]);
                }
            }
            if (i == gidArr.Length - 1)
            {
                string[] subGidArr = new string[gidArr.Length - currentIndex - 1];
                for (int j = 0; j < subGidArr.Length; j++)
                {
                    subGidArr[j] = gidArr[currentIndex + 1 + j];
                }
                CachedKLine[] cacheArr = GetKLineSetArray(subGidArr, type);
                for (int j = 0; j < cacheArr.Length; j++)
                {
                    retArrayList.Add(cacheArr[j]);
                }
            }
        }

        CachedKLine[] ret = new CachedKLine[retArrayList.Count];
        for (int i = 0; i < ret.Length; i++)
        {
            ret[i] = (CachedKLine)retArrayList[i];
        }
        return ret;
    }

    public static CachedKLine[] GetKLineSetArray(string[] gidArr, string type)
    {
        CachedKLine[] retArr = new CachedKLine[gidArr.Length];
        ArrayList inCacheGids = new ArrayList();
        ArrayList outOfCacheGids = new ArrayList();
        foreach (string gid in gidArr)
        {
            CachedKLine cachedKLine = GetKLineInCache(gid, type);
            if (!cachedKLine.gid.Trim().Equals(""))
            {
                inCacheGids.Add(cachedKLine);
            }
            else
            {
                outOfCacheGids.Add(gid);
            }
        }
        CachedKLine[] cachedKLineArrInCache = new CachedKLine[inCacheGids.Count];
        for (int i = 0; i < inCacheGids.Count; i++)
        {
            cachedKLineArrInCache[i] = (CachedKLine)inCacheGids[i];
        }
        UpdateCachedKLine(cachedKLineArrInCache);
        string[] gidArrOutOfCache = new string[outOfCacheGids.Count];
        for (int i = 0; i < gidArrOutOfCache.Length; i++)
        {
            gidArrOutOfCache[i] = outOfCacheGids[i].ToString();
        }
        CachedKLine[] cachedKLineArrOutOfCache = CreateCachedKLineArray(gidArrOutOfCache, type);
        CachedKLine[] totalCache = new CachedKLine[cachedKLineArrInCache.Length + cachedKLineArrOutOfCache.Length];
        for (int k = 0; k < totalCache.Length; k++)
        {
            if (k < cachedKLineArrInCache.Length)
            {
                totalCache[k] = cachedKLineArrInCache[k];
            }
            else
            {
                totalCache[k] = cachedKLineArrOutOfCache[k - cachedKLineArrInCache.Length];
            }
        }
        UpdateStockCache(totalCache);
        return totalCache;
    }

    public static void UpdateStockCache(CachedKLine[] cArr)
    {
        for (int i = 0; i < cArr.Length; i++)
        {
            bool exists = false;
            for (int j = 0; j < kLineCache.Count; j++)
            {
                CachedKLine c = (CachedKLine)kLineCache[j];
                if (c.gid.Trim().Equals(cArr[i].gid.Trim()) && c.type.Trim().Equals(cArr[i].type.Trim()))
                {
                    kLineCache[j] = cArr[i];
                    exists = true;
                    break;
                }
            }
            if (!exists)
            {
                kLineCache.Add(cArr[i]);
            }
        }
    }


    public static CachedKLine[] CreateCachedKLineArray(string[] gidArr, string type)
    {
        if (gidArr.Length == 0)
            return new CachedKLine[0];
        CachedKLine[] cArr = new CachedKLine[gidArr.Length];
        string sql = "";
        for (int i = 0; i < gidArr.Length; i++)
        {
            string subSql = " select * from " + gidArr[i].Trim() + "_k_line where [type] = '" + type.Trim() + "' ";
            sql = sql + (sql.Trim().Equals("") ? "" : " union ") + subSql;
        }
        DataTable dt = DBHelper.GetDataTable(sql);
        for (int i = 0; i < gidArr.Length; i++)
        {
            cArr[i] = new CachedKLine();
            cArr[i].gid = gidArr[i].Trim();
            cArr[i].type = type.Trim();
            DataRow[] drArr = dt.Select("gid = '" + gidArr[i].Trim() + "' ", " start_date ");
            KLine[] kArr = new KLine[drArr.Length];
            for (int j = 0; j < drArr.Length; j++)
            {
                kArr[j] = new KLine();
                kArr[j].gid = drArr[j]["gid"].ToString().Trim();
                kArr[j].type = drArr[j]["type"].ToString().Trim();
                kArr[j].startDateTime = DateTime.Parse(drArr[j]["start_date"].ToString());
                kArr[j].startPrice = double.Parse(drArr[j]["open"].ToString());
                kArr[j].endPrice = double.Parse(drArr[j]["settle"].ToString());
                kArr[j].highestPrice = double.Parse(drArr[j]["highest"].ToString());
                kArr[j].lowestPrice = double.Parse(drArr[j]["lowest"].ToString());
                kArr[j].volume = double.Parse(drArr[j]["volume"].ToString());
                kArr[j].amount = double.Parse(drArr[j]["amount"].ToString());
            }
            cArr[i].kLine = kArr;
            cArr[i].lastUpdate = DateTime.Now;
        }
        return cArr;
    }

    public static void UpdateCachedKLine(CachedKLine[] cachedKLineArr)
    {
        if (cachedKLineArr.Length > 0)
        {
            string type = cachedKLineArr[0].type.Trim();
            string sql = "";
            foreach (CachedKLine c in cachedKLineArr)
            {
                if (c.kLine.Length > 0)
                {
                    string subSql = " select  * from  " + c.gid.Trim() + "_k_line where [type] = '" + type.Trim() + "' and start_date >= '" + c.kLine[c.kLine.Length - 1].startDateTime.ToString() + "' ";
                    sql = sql + (sql.Trim().Equals("") ? "" : " union ") + subSql;
                }
            }
            DataTable dt = DBHelper.GetDataTable(sql);
            for (int i = 0; i < cachedKLineArr.Length; i++)
            {
                CachedKLine c = cachedKLineArr[i];
                c.kLine = MergeSortedDataRowsToKLineArray(dt.Select(" gid = '" + c.gid.Trim() + "' ", " start_date "), c.kLine);
            }
        }
    }

    public static KLine[] MergeSortedDataRowsToKLineArray(DataRow[] drArr, KLine[] kArr)
    {
        int startIndex = 0;
        if (drArr.Length <= 0)
            return new KLine[0];
        for (int i = 0; i < kArr.Length; i++)
        {
            if (kArr[i].startDateTime == DateTime.Parse(drArr[0]["start_date"].ToString().Trim()))
            {
                startIndex = i;
                break;
            }
        }
        int newArrayLength = kArr.Length + (drArr.Length - (kArr.Length - startIndex));
        if (newArrayLength == kArr.Length)
        {
            for (int i = startIndex; i < kArr.Length; i++)
            {
                kArr[i].startDateTime = DateTime.Parse(drArr[i - startIndex]["start_date"].ToString());
                kArr[i].startPrice = double.Parse(drArr[i - startIndex]["open"].ToString());
                kArr[i].endPrice = double.Parse(drArr[i - startIndex]["settle"].ToString());
                kArr[i].highestPrice = double.Parse(drArr[i - startIndex]["highest"].ToString());
                kArr[i].lowestPrice = double.Parse(drArr[i - startIndex]["lowest"].ToString());
                kArr[i].volume = double.Parse(drArr[i - startIndex]["volume"].ToString());
                kArr[i].amount = double.Parse(drArr[i - startIndex]["amount"].ToString());
            }
            return kArr;
        }
        else
        {
            KLine[] newKArr = new KLine[newArrayLength];
            for (int i = 0; i < newKArr.Length; i++)
            {
                if (i < startIndex)
                {
                    newKArr[i] = kArr[i];
                }
                else
                {
                    if (i == startIndex)
                    {
                        newKArr[i] = kArr[i];
                    }
                    else
                    {
                        newKArr[i] = new KLine();
                    }
                    newKArr[i].gid = drArr[i - startIndex]["gid"].ToString().Trim();
                    newKArr[i].type = drArr[i - startIndex]["type"].ToString().Trim();
                    newKArr[i].startDateTime = DateTime.Parse(drArr[i - startIndex]["start_date"].ToString());
                    newKArr[i].startPrice = double.Parse(drArr[i - startIndex]["open"].ToString());
                    newKArr[i].endPrice = double.Parse(drArr[i - startIndex]["settle"].ToString());
                    newKArr[i].highestPrice = double.Parse(drArr[i - startIndex]["highest"].ToString());
                    newKArr[i].lowestPrice = double.Parse(drArr[i - startIndex]["lowest"].ToString());
                    newKArr[i].volume = double.Parse(drArr[i - startIndex]["volume"].ToString());
                    newKArr[i].amount = double.Parse(drArr[i - startIndex]["amount"].ToString());
                }
            }
            return newKArr;
        }
    }


    public static KLine[] LoadLocalKLine(string gid, string type)
    {
        try
        {
            CachedKLine cachedKLine = LoadLocalKLineFromCache(gid, type);
            KLine[] kArr = cachedKLine.kLine;
            if (cachedKLine.gid.Trim().Equals(""))
            {
                kArr = LoadLocalKLineFromDB(gid, type);
                SaveLocalKLineToCache(gid, type, kArr);
            }
            /*
            else
            {
                if ((Util.IsTransacDay(cachedKLine.lastUpdate) && Util.IsTransacTime(cachedKLine.lastUpdate)) || DateTime.Now - cachedKLine.lastUpdate > new TimeSpan(1, 0, 0, 0))
                {
                    KLine[] kArrLatest = LoadLocalKLineFromDB(gid, type, kArr[kArr.Length - 1].startDateTime);
                    KLine[] kArrNew = new KLine[kArr.Length + kArrLatest.Length - 1];
                    for (int i = 0; i < kArr.Length; i++)
                    {
                        kArrNew[i] = kArr[i];
                    }
                    for (int i = 0; i < kArrLatest.Length; i++)
                    {
                        kArrNew[i + kArr.Length - 1] = kArrLatest[i];
                    }
                    kArr = kArrNew;
                    SaveLocalKLineToCache(gid, type, kArr);
                }
            }
            */
            return kArr;
        }
        catch(Exception err)
        {
            return LoadLocalKLineFromDB(gid, type);
        }
        
    }

    public static CachedKLine LoadLocalKLineFromCache(string gid, string type)
    {
        //KLine[] retKLineArr  = new KLine[0];
        CachedKLine ret = new CachedKLine();
        ret.gid = "";
        for(int i = 0; i < kLineCache.Count; i++)
        //foreach (object o in kLineCache)
        {
            CachedKLine kLine = (CachedKLine)kLineCache[i];
            if (kLine.type.Trim().Equals(type.Trim()) && kLine.gid.Trim().Equals(gid.Trim()))
            {
                ret = kLine;
                break;
            } 
        }
        return ret;
    }

    public static void SaveLocalKLineToCache(string gid, string type, KLine[] kLineArr)
    {
        bool exsitsInCache = false;
        for(int i = 0; i < kLineCache.Count; i++)
        //foreach (object o in kLineCache)
        {
            CachedKLine kLine = (CachedKLine)kLineCache[i];
            if (kLine.type.Trim().Equals(type.Trim()) && kLine.gid.Trim().Equals(gid.Trim()))
            {
                exsitsInCache = true;
                kLine.lastUpdate = DateTime.Now;
                kLine.kLine = kLineArr;
                break;
            }
        }
        if (!exsitsInCache)
        {
            CachedKLine kLineObject = new CachedKLine();
            kLineObject.gid = gid.Trim();
            kLineObject.type = type.Trim();
            kLineObject.kLine = kLineArr;
            kLineObject.lastUpdate = DateTime.Now;
            kLineCache.Add(kLineObject);
        }
    }


    public static KLine[] LoadLocalKLineFromDB(string gid, string type)
    {
        DataTable dt = DBHelper.GetDataTable(" select * from " + gid.Trim() + "_k_line where  type = '" + type + "' order by start_date ");
        KLine[] kArr = new KLine[dt.Rows.Count];
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            kArr[i] = new KLine();
            kArr[i].gid = gid.Trim();
            kArr[i].startDateTime = DateTime.Parse(dt.Rows[i]["start_date"].ToString());
            kArr[i].type = type.Trim();
            kArr[i].startPrice = double.Parse(dt.Rows[i]["open"].ToString());
            kArr[i].endPrice = double.Parse(dt.Rows[i]["settle"].ToString());
            if (type.Trim().Equals("day") 
                && kArr[i].startDateTime.ToShortDateString().Equals(DateTime.Now.ToShortDateString()))
            {
                Stock stock = new Stock(gid.Trim());
                kArr[i].endPrice = stock.LastTrade;
            }
            kArr[i].highestPrice = double.Parse(dt.Rows[i]["highest"].ToString());
            kArr[i].lowestPrice = double.Parse(dt.Rows[i]["lowest"].ToString());
            kArr[i].volume = int.Parse(dt.Rows[i]["volume"].ToString());
            kArr[i].amount = double.Parse(dt.Rows[i]["amount"].ToString());
        }
        return kArr;
    }



    public static KLine[] LoadLocalKLineFromDB(string gid, string type, DateTime startDate)
    {
        DataTable dt = DBHelper.GetDataTable(" select * from " + gid.Trim() + "_k_line where   type = '" + type 
            + "' and start_date >= '" + startDate.ToString() + "'  order by start_date ");
        KLine[] kArr = new KLine[dt.Rows.Count];
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            kArr[i] = new KLine();
            kArr[i].gid = gid.Trim();
            kArr[i].startDateTime = DateTime.Parse(dt.Rows[i]["start_date"].ToString());
            kArr[i].type = type.Trim();
            kArr[i].startPrice = double.Parse(dt.Rows[i]["open"].ToString());
            kArr[i].endPrice = double.Parse(dt.Rows[i]["settle"].ToString());
            if (type.Trim().Equals("day")
                && kArr[i].startDateTime.ToShortDateString().Equals(DateTime.Now.ToShortDateString()))
            {
                Stock stock = new Stock(gid.Trim());
                kArr[i].endPrice = stock.LastTrade;
            }
            kArr[i].highestPrice = double.Parse(dt.Rows[i]["highest"].ToString());
            kArr[i].lowestPrice = double.Parse(dt.Rows[i]["lowest"].ToString());
            kArr[i].volume = int.Parse(dt.Rows[i]["volume"].ToString());
            kArr[i].amount = double.Parse(dt.Rows[i]["amount"].ToString());
        }
        return kArr;
    }

    public static void SearchBottomBreak3Line(DateTime currentDate)
    {
        if (!Util.IsTransacDay(currentDate))
            return;
        string[] gidArr = Util.GetAllGids();
        foreach (string gid in gidArr)
        {
            Stock stock = new Stock(gid);
            stock.LoadKLineDay();
            int currentIndex = stock.GetItemIndex(currentDate);
            if (currentIndex < 6)
                continue;
            if (stock.IsCross3Line(currentIndex, "day"))
            {
                int goingDown3LineCount = stock.GoingDows3LineCount(currentIndex);
                int under3LineCount = stock.Under3LineKLines(currentIndex);
                try
                {
                    DBHelper.InsertData("bottom_break_cross_3_line", new string[,] {
                    { "gid", "varchar", gid},
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

    public double GetMaPressure(int index, double price)
    {
        KeyValuePair<string, double>[] quotaArr = GetSortedQuota(index);
        double pressure = 0;
        for (int i = 0; i < quotaArr.Length; i++)
        {
            if (quotaArr[i].Value > price)
            {
                pressure = quotaArr[i].Value;
                break;
            }
        }
        return pressure;
    }

    public double GetMaPressure(int index)
    {
        double pressure = 0;
        KeyValuePair<string, double>[] quotaArr = GetSortedQuota(index);
        for (int i = quotaArr.Length - 1; i >= 0; i--)
        {
            if (quotaArr[i].Key.Trim().Equals("end_price"))
            {
                if (i == quotaArr.Length - 1)
                {
                    pressure = quotaArr[i].Value * 1.5;
                }
                else
                {
                    pressure = quotaArr[i + 1].Value;
                }
                break;
            }
        }
        return pressure;
        /*
        double[] maArr = new double[4];
        double[] maPressureArr = new double[4];
        double currentPrice = kArr[index].endPrice;

        maArr[0] = GetAverageSettlePrice(index, 5, 0);
        maArr[1] = GetAverageSettlePrice(index, 10, 0);
        maArr[2] = GetAverageSettlePrice(index, 20, 0);
        maArr[3] = GetAverageSettlePrice(index, 60, 0);
        for (int i = 0; i < maArr.Length; i++)
        {
            maPressureArr[i] = maArr[i] - currentPrice >=0 ? maArr[i] - currentPrice : double.MaxValue;
        }

        int minIndex = 0;
        double minValue = double.MaxValue;
        for (int i = 0; i < maPressureArr.Length; i++)
        {
            if (maPressureArr[i] <= minValue)
            {
                minValue = maPressureArr[i];
                minIndex = i;
            }
        }
        return maArr[minIndex] > kArr[index].endPrice ? maArr[minIndex] : 0;
        */
    }

    public double GetMaSupport(int index, double price)
    {
        KeyValuePair<string, double>[] quotaArr = GetSortedQuota(index);
        double support = 0;
        for (int i = 0; i < quotaArr.Length; i++)
        {
            if (quotaArr[i].Value < price)
            {
                support = quotaArr[i].Value;
                break;
            }
        }
        return support;
    }

    public double GetMaSupport(int index)
    {
        KeyValuePair<string, double>[] quotaArr = GetSortedQuota(index);
        double support = 0;
        for (int i = 0; i < quotaArr.Length; i++)
        {
            if (quotaArr[i].Key.Trim().Equals("end_price"))
            {
                if (i == 0)
                {
                    support = 0;
                }
                else
                {
                    support = quotaArr[i - 1].Value;
                }
            }
        }
        return support;
        /*
        double[] maArr = new double[4];
        double[] maSupportArr = new double[4];
        double currentPrice = kArr[index].endPrice;

        maArr[0] = GetAverageSettlePrice(index, 5, 0);
        maArr[1] = GetAverageSettlePrice(index, 10, 0);
        maArr[2] = GetAverageSettlePrice(index, 20, 0);
        maArr[3] = GetAverageSettlePrice(index, 60, 0);
        for (int i = 0; i < maArr.Length; i++)
        {
            maSupportArr[i] = currentPrice - maArr[i]   > 0 ? currentPrice - maArr[i]   : double.MaxValue;
        }

        int minIndex = 0;
        double minValue = double.MaxValue;
        for (int i = 0; i < maSupportArr.Length; i++)
        {
            if (maSupportArr[i] <= minValue)
            {
                minValue = maSupportArr[i];
                minIndex = i;
            }
        }
        return maArr[minIndex] < kArr[index].endPrice ? maArr[minIndex]: 0;
        */
    }

    public KeyValuePair<string, double>[] GetSortedQuota(int index)
    {
        KeyValuePair<string, double>[] quotaArr = new KeyValuePair<string, double>[5];
        quotaArr[0] = new KeyValuePair<string, double>("lowest_price", kArr[index].lowestPrice);
        quotaArr[1] = new KeyValuePair<string, double>("3_line_price", GetAverageSettlePrice(index, 3, 3));
        quotaArr[2] = new KeyValuePair<string, double>("ma6", GetAverageSettlePrice(index, 6, 0));
        quotaArr[3] = new KeyValuePair<string, double>("ma12", GetAverageSettlePrice(index, 12, 0));
        quotaArr[4] = new KeyValuePair<string, double>("ma24", GetAverageSettlePrice(index, 24, 0));
        string tempKey = "";
        double tempValue = 0;

        bool exchanged = true;
        for (; exchanged;)
        {
            exchanged = false;
            for (int i = 0; i < quotaArr.Length - 1 ; i++)
            {
                if (quotaArr[i].Value > quotaArr[i + 1].Value)
                {
                    tempKey = quotaArr[i].Key.Trim();
                    tempValue = quotaArr[i].Value;
                    quotaArr[i] = quotaArr[i + 1];
                    quotaArr[i + 1] = new KeyValuePair<string, double>(tempKey, tempValue);
                    exchanged = true;
                }
            }
        }
        return quotaArr;
    }

    public bool IsLimitUp(int index)
    {
        if (index > 1)
        {
            if ((kLineDay[index].endPrice - kLineDay[index - 1].endPrice )/ kLineDay[index - 1].endPrice > 0.095 
                && kLineDay[index - 1].endPrice == kLineDay[index - 1].highestPrice)
            {
                return true;
            }
        }
        return false;
    }
    
    ////////////////////////////////////////////////////////////////////////
    //old members//
    ////////////////////////////////////////////////////////////////////////

    public void ComputeIncreasement()
    {
        for (int i = 1; i < kArr.Length; i++)
        {
            kArr[i].increaseRateOpen = (kArr[i].startPrice - kArr[i - 1].endPrice) / kArr[i - 1].endPrice;
            kArr[i].increaseRateHighest = (kArr[i].highestPrice - kArr[i - 1].endPrice) / kArr[i - 1].endPrice;
            kArr[i].increaseRateLowest = (kArr[i].lowestPrice - kArr[i - 1].endPrice) / kArr[i - 1].endPrice;
            kArr[i].increaseRateSettle = (kArr[i].endPrice - kArr[i - 1].endPrice) / kArr[i - 1].endPrice;
            kArr[i].increaseRateShake = Math.Abs(kArr[i].increaseRateHighest - kArr[i].increaseRateLowest);
        }
    }

    public int GetKLineIndexForADay(DateTime currentDate)
    {
        if (kArr == null)
            return -1;
        int ret = -1;
        for (int i = kArr.Length - 1; i >= 0; i--)
        {
            if (kArr[i].startDateTime <= currentDate)
            {
                ret = i;
                break;
            }
        }
        return ret;
    }


    public bool IsOver3X3(DateTime currentDate)
    {
        bool ret = false;
        int dateIndex = GetItemIndex(currentDate);
        if (dateIndex < 5)
            return false;
        double open = kArr[dateIndex].startPrice;
        double end = kArr[dateIndex].endPrice;
        double settle = 0;
        try
        {
            settle = kArr[dateIndex - 1].endPrice;
        }
        catch
        {

        }
        double avg3X3 = GetAverageSettlePrice(dateIndex, 3, 3);
        if (settle > 0 && open < avg3X3 && end > avg3X3)
        {
            ret = true;
        }
        return ret;
    }

    public bool IsGrowHighThan3X3(DateTime currentDate)
    {
        bool ret = false;
        int dateIndex = GetItemIndex(currentDate);
        if (dateIndex < 5)
            return false;
        double open = kArr[dateIndex].startPrice;
        double end = kArr[dateIndex].endPrice;
        double settle = 0;
        try
        {
            settle = kArr[dateIndex - 1].endPrice;
        }
        catch
        {

        }
        double avg3X3 = GetAverageSettlePrice(dateIndex, 3, 3);
        if (open < avg3X3 && end > avg3X3)
        {
            ret = true;
        }
        return ret;
    }

    public bool IsCross3X3(DateTime currentDate)
    {
        int dateIndex = GetItemIndex(currentDate);
        if (dateIndex == -1)
            return false;
        if (dateIndex < 5)
            return false;
        double yesterday3X3Price = GetAverageSettlePrice(dateIndex - 1, 3, 3);
        double today3X3Price = GetAverageSettlePrice(dateIndex, 3, 3);
        double yesterdaySettlePrice = kArr[dateIndex - 1].endPrice;
        double todayOpenPrice = kArr[dateIndex].startPrice;
        if (yesterdaySettlePrice < yesterday3X3Price && todayOpenPrice > today3X3Price
            && todayOpenPrice > yesterdaySettlePrice && todayOpenPrice != 0 && yesterdaySettlePrice != 0)
            return true;
        else
            return false;
    }

    public bool IsCross3X3Twice(DateTime currentDate, int days)
    {
        int dateIndex = GetItemIndex(currentDate);
        if (dateIndex == -1)
            return false;
        if (dateIndex < 5)
            return false;
        if (!IsCross3X3(currentDate))
            return false;
        bool ret = false;
        for (int i = 0; i < days; i++)
        {
            if (IsCross3X3(kArr[dateIndex - i - 1].startDateTime))
            {
                ret = true;
                break;
            }
        }
        return ret;
    }



    public bool IsOverFlowYesterday(DateTime currentDate, double percent)
    {
        int dateIndex = GetItemIndex(currentDate);
        if (dateIndex == -1)
            return false;
        if (dateIndex < 2)
            return false;
        if (kArr[dateIndex - 1].IsPositive
            && ((kArr[dateIndex - 1].endPrice - kArr[dateIndex - 2].endPrice) / kArr[dateIndex - 2].endPrice >= percent))
            return true;
        else
            return false;
    }

    public double yesterdayPositiveRate(DateTime currentDate)
    {
        int dateIndex = GetItemIndex(currentDate);
        if (dateIndex == -1)
            return 0;
        if (dateIndex < 2)
            return 0;
        if (!kArr[dateIndex - 1].IsPositive)
            return 0;
        double rate = (kArr[dateIndex - 1].endPrice - kArr[dateIndex - 2].endPrice) / kArr[dateIndex - 2].endPrice;
        if (rate <= 0)
            return 0;
        else
            return rate;
    }

    public double LastBuy
    {
        get
        {
            if (drLastTimeline != null)
            {
                return double.Parse(drLastTimeline["buy"].ToString().Trim());
            }
            else
                return 0;
        }
    }

    public double LastSell
    {
        get
        {
            if (drLastTimeline != null)
            {
                return double.Parse(drLastTimeline["sell"].ToString().Trim());
            }
            else
                return 0;
        }
    }

    

    public bool IsAtBuyPoint
    {
        get
        {
            bool ret = false;
            if (drLastTimeline != null
                && DateTime.Parse(drLastTimeline["ticktime"].ToString()) >= DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30"))
            {
                if (double.Parse(drLastTimeline["high"].ToString()) * (1 - shakeRate) > double.Parse(drLastTimeline["trade"].ToString()))
                    ret = true;
            }
            return ret;
            /*
            bool ret = false;
            KLine lastKLine = kArr[kArr.Length - 1];
            if (DateTime.Parse(DateTime.Now.ToShortDateString()) == lastKLine.startDateTime)
            {
                if (lastKLine.endPrice < lastKLine.highestPrice * (1 - shakeRate))
                    ret = true;
            }
            return ret;
            */
        }
    }

    public bool IsAtSellPoint
    {
        get
        {
            bool ret = false;
            if (drLastTimeline != null
                && DateTime.Parse(drLastTimeline["ticktime"].ToString()) >= DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30"))
            {
                if (double.Parse(drLastTimeline["low"].ToString()) * (1 + shakeRate) < double.Parse(drLastTimeline["trade"].ToString()))
                    ret = true;
            }
            /*
            KLine lastKLine = kArr[kArr.Length - 1];
            if (DateTime.Parse(DateTime.Now.ToShortDateString()) == lastKLine.startDateTime)
            {
                if (lastKLine.endPrice > lastKLine.lowestPrice * (1 + shakeRate))
                    ret = true;
            }
            */
            return ret;
        }
    }
    public static double[] GetVolumeAndAmount(string gid, DateTime currentDate)
    {
        if (currentDate.ToShortTimeString().Equals("0:00"))
        {
            currentDate = currentDate.AddHours(16);
        }

        DataTable dtTimeline = DBHelper.GetDataTable(" select top 1 * from  " + gid.Trim() + "_timeline where ticktime <= '" + currentDate.ToString() + "' order by ticktime desc ");
        DataTable dtNormal = DBHelper.GetDataTable(" select top 1 * from  " + gid + " where convert(datetime, date + ' ' + time )  <= '" + currentDate.ToString() + "'  order by convert(datetime, date + ' ' + time ) desc   ");
        double volmue = 0;
        double amount = 0;
        DateTime timeLineTick = DateTime.Parse(DateTime.Now.ToShortDateString());
        DateTime normalTick = DateTime.Parse(DateTime.Now.ToShortDateString());
        if (dtTimeline.Rows.Count > 0)
        {
            //volmue = double.Parse(dtTimeline.Rows[0]["volume"].ToString());
            //amount = double.Parse(dtTimeline.Rows[0]["amount"].ToString());
            timeLineTick = DateTime.Parse(dtTimeline.Rows[0]["ticktime"].ToString());
            
        }
        if (dtNormal.Rows.Count > 0)
        {
            //volmue = Math.Max(double.Parse(dtNormal.Rows[0]["traNumber"].ToString()), volmue);
            //amount = Math.Max(double.Parse(dtNormal.Rows[0]["traAmount"].ToString()), amount);
            normalTick = DateTime.Parse(dtNormal.Rows[0]["date"].ToString() + " " + dtNormal.Rows[0]["time"].ToString());
        }
        if (normalTick > timeLineTick)
        {
            volmue = Math.Max(double.Parse(dtNormal.Rows[0]["traNumber"].ToString()), volmue);
            amount = Math.Max(double.Parse(dtNormal.Rows[0]["traAmount"].ToString()), amount);
        }
        else
        {
            if (dtTimeline.Rows.Count > 0)
            {
                volmue = double.Parse(dtTimeline.Rows[0]["volume"].ToString());
                amount = double.Parse(dtTimeline.Rows[0]["amount"].ToString());
            }
        }


        return new double[] { volmue, amount };
    }

    public double HighestPrice(DateTime currentDate, int days)
    {
        int currentDateIndex = GetKLineIndexForADay(currentDate);
        if (currentDateIndex < 0)
            return 0;
        double maxPrice = 0;
        for (int i = 0; i < days && currentDateIndex - i >= 0; i++)
        {
            maxPrice = Math.Max(maxPrice, kArr[currentDateIndex - i].highestPrice);
        }
        return maxPrice;
    }
 

    public double LowestPrice(DateTime currentDate, int days)
    {
        int currentDateIndex = GetKLineIndexForADay(currentDate);
        if (currentDateIndex < 0)
            return 0;
        double minPrice = double.MaxValue;
        for (int i = 0; i < days && currentDateIndex - i >= 0; i++)
        {
            minPrice = Math.Min(minPrice, kArr[currentDateIndex - i].lowestPrice);
        }
        return minPrice;
    }

    public static double[] GetGoldLineArray(double minPrice, double maxPrice)
    {
        double[] goldLineArray = new double[13];
        goldLineArray[0] = maxPrice - (maxPrice - minPrice) * 2;
        goldLineArray[1] = maxPrice - (maxPrice - minPrice) * 1.618;
        goldLineArray[2] = maxPrice - (maxPrice - minPrice) * 1.382;
        goldLineArray[3] = minPrice;
        goldLineArray[4] = maxPrice - (maxPrice - minPrice) * 0.809;
        goldLineArray[5] = maxPrice - (maxPrice - minPrice) * 0.618;
        goldLineArray[6] = maxPrice - (maxPrice - minPrice) * 0.382;
        goldLineArray[7] = maxPrice - (maxPrice - minPrice) * 0.236;
        goldLineArray[8] = maxPrice;
        goldLineArray[9] = minPrice + (maxPrice - minPrice) * 1.382;
        goldLineArray[10] = minPrice + (maxPrice - minPrice) * 1.618;
        goldLineArray[11] = minPrice + (maxPrice - minPrice) * 2;
        return goldLineArray;
    }

    public static double GetPressure(double currentPrice, double minPrice, double maxPrice)
    {
        double[] goldArr = GetGoldLineArray(minPrice, maxPrice);
        for (int i = 0; i < goldArr.Length - 1; i++)
        {
            if (goldArr[i] < currentPrice && goldArr[i + 1] > currentPrice)
            {
                return goldArr[i + 1];
            }
        }
        return 0;
    }

    public static double GetSupport(double currentPrice, double minPrice, double maxPrice)
    {
        double[] goldArr = GetGoldLineArray(minPrice, maxPrice);
        for (int i = 0; i < goldArr.Length - 1; i++)
        {
            if (goldArr[i] < currentPrice && goldArr[i + 1] > currentPrice)
            {
                return goldArr[i];
            }
        }
        return 0;
    }


}


