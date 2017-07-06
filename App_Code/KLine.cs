﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;
using System.Data.SqlClient;

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
    public double amount = 0;
    public double change = 0;

    public double increaseRateOpen = 0;
    public double increaseRateHighest = 0;
    public double increaseRateLowest = 0;
    public double increaseRateShake = 0;
    public double increaseRateSettle = 0;

    public double rsv = 0;
    public double k = 0;
    public double d = 0;
    public double j = 0;

    public KLine()
    {
        //
        // TODO: Add constructor logic here
        //
    }

    

    public DateTime endDateTime
    {
        get
        {
            DateTime endTime = startDateTime;
            switch (type.Trim())
            {
                case "day":
                    startDateTime = DateTime.Parse(startDateTime.ToShortDateString() + " 9:30");
                    endTime = DateTime.Parse(startDateTime.ToShortDateString() + " 15:00");
                    break;
                case "15min":
                    endTime = startDateTime.Add(new TimeSpan(0, 15, 0));
                    break;
                case "30min":
                    endTime = startDateTime.Add(new TimeSpan(0, 30, 0));
                    break;
                case "1hr":
                    endTime = startDateTime.Add(new TimeSpan(1, 0, 0));
                    break;
                case "1min":
                    endTime = startDateTime.AddMinutes(1);
                    break;
                default:
                    endTime = startDateTime;
                    break;
            }
            return endTime;
        }
    }

    public void Save()
    {
        DataTable dt = DBHelper.GetDataTable(" select * from " + gid.Trim() + "_k_line  where type = '" + type.Trim() 
            + "'  and  start_date = '" + startDateTime.ToString() + "'  ");
        if (dt.Rows.Count == 0)
        {
            DBHelper.InsertData(gid.Trim() + "_k_line", new string[,] {
                { "gid", "varchar", gid.Trim()},
                { "start_date", "datetime", startDateTime.ToString() },
                { "type", "varchar", type.Trim()},
                { "[open]", "float", startPrice.ToString()},
                { "settle", "float", endPrice.ToString()},
                { "highest", "float", highestPrice.ToString()},
                { "lowest", "float", lowestPrice.ToString()},
                { "volume", "int", volume.ToString()},
                { "amount", "float", amount.ToString()},
                { "ext_data", "varchar", ""}
            });
        }
        else
        {
            DBHelper.UpdateData(gid.Trim() + "_k_line", new string[,] {
                { "[open]", "float", startPrice.ToString()},
                { "settle", "float", endPrice.ToString()},
                { "highest", "float", highestPrice.ToString()},
                { "lowest", "float", lowestPrice.ToString()},
                { "volume", "int", volume.ToString()},
                { "amount", "float", amount.ToString()},
                { "ext_data", "varchar", ""}
            }, new string[,] {
                { "gid", "varchar", gid.Trim()},
                { "start_date", "datetime", startDateTime.ToString() },
                { "type", "varchar", type.Trim()}
            }, Util.conStr);
        }
        dt.Dispose();
    }

    public bool IsPositive
    {
        get
        {
            if (startPrice < endPrice)
                return true;
            else
                return false;
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
        //if (endDate >= DateTime.Parse(DateTime.Now.ToShortDateString()) && Util.IsTransacDay(endDate) 
        //    && kLineArr[kLineArr.Length - 1].startDateTime < endDate )
        if (endDate == DateTime.Parse(DateTime.Now.ToShortDateString()) && Util.IsTransacDay(endDate) 
            && kLineArr[kLineArr.Length - 1].startDateTime < endDate)
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
                if (k.endPrice==0)
                    k.endPrice = double.Parse(dt.Rows[0]["sell"].ToString());
                k.gid = stockCode;
                return k;
            }
            else
                return null;

        }
        else
            return null;
    }
/*
    public static void ComputeAndUpdateKLine(string gid, string type, DateTime start, DateTime end)
    {
        KLine[] kArr = TimeLine.CreateKLineArray(gid, type, TimeLine.GetTimeLineItem(gid, start, end));
        CreateKLineTable(gid);
        foreach (KLine k in kArr)
        {
            k.Save();
        }
    }
*/


    public static void CreateKLineTable(string gid)
    {
        string sql = "if not exists(select * from dbo.sysobjects where id = object_id(N'[dbo].[" + gid + "_k_line]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)   begin "
            + "CREATE TABLE[dbo].[" + gid + "_k_line] ("
            + " [gid] [varchar] (8) COLLATE Chinese_PRC_CI_AS NOT NULL , "
            + " [start_date] [datetime] NOT NULL , "
            + " [type][varchar](10) COLLATE Chinese_PRC_CI_AS NOT NULL, "

            + " [open] [float] NOT NULL, "

            + " [settle] [float] NOT NULL, "

            + " [highest] [float] NOT NULL, "

            + " [lowest] [float] NOT NULL, "

            + " [volume] [int] NOT NULL, "

            + " [amount] [float] NOT NULL, "

            + " [ext_data] [varchar] (2000) COLLATE Chinese_PRC_CI_AS NOT NULL, "

            + " [create_date] [datetime]     NOT NULL ) "
            + "   "
            + " ALTER TABLE [dbo].[" + gid + "_k_line] WITH NOCHECK ADD 	CONSTRAINT [PK_" + gid + "_k_line] PRIMARY KEY  CLUSTERED 	( [gid], [start_date],[type])  ON [PRIMARY]  "
            + " ALTER TABLE [dbo].[" + gid + "_k_line] ADD CONSTRAINT [DF_" + gid + "_k_line_create_date] DEFAULT (getdate()) FOR [create_date] end ";
        SqlConnection conn = new SqlConnection(Util.conStr);
        SqlCommand cmd = new SqlCommand(sql, conn);
        conn.Open();
        cmd.ExecuteNonQuery();
        conn.Close();
        cmd.Dispose();
        conn.Dispose();
    }

    public static double GetLowestPrice(KLine[] kArr)
    {
        double ret = 0;
        foreach (KLine k in kArr)
        {
            if (ret == 0)
            {
                ret = k.lowestPrice;
            }
            else
            {
                ret = Math.Min(ret, k.lowestPrice);
            }
        }
        return ret;
    }

    public static double GetHighestPrice(KLine[] kArr)
    {
        double ret = 0;
        foreach (KLine k in kArr)
        {
            ret = Math.Max(ret, k.highestPrice);
        }
        return ret;
    }

    public static KLine[] GetSubKLine(KLine[] kArr, int startIndex, int num)
    {
        if (startIndex + num > kArr.Length)
            return null;
        KLine[] subArr = new KLine[num];
        for (int i = 0; i < num; i++)
        {
            subArr[i] = kArr[startIndex + i];
        }
        return subArr;
    }
    

    public static KLine[] ComputeRSV(KLine[] kArr)
    {
        int valueN = 9;
        for (int i = valueN - 1; i < kArr.Length; i++)
        {
            KLine[] rsvArr = GetSubKLine(kArr, i - valueN + 1, valueN);
            double lowPrice = GetLowestPrice(rsvArr);
            double hiPrice = GetHighestPrice(rsvArr);
            kArr[i].rsv = 100 * (kArr[i].endPrice - lowPrice) / (hiPrice - lowPrice);
        }
        return kArr;
    }

    public static  KLine[] ComputeKDJ(KLine[] kArr)
    {
        int valueM1 = 3;
        int valueM2 = 3;
        for (int i = 0; i < kArr.Length; i++)
        {
            if (kArr[i].rsv == 0)
            {
                kArr[i].k = 50;
                kArr[i].d = 50;
                continue;
            }
            kArr[i].k = (kArr[i].rsv + (valueM1 - 1) * kArr[i - 1].k) / valueM1;
            kArr[i].d = (kArr[i].k + (valueM2 - 1) * kArr[i - 1].d) / valueM2;
            kArr[i].j = 3 * kArr[i].k - 2 * kArr[i].d;
        }
        return kArr;
    }

    public static void SearchKDJAlert(KLine[] kArr)
    {
        int unEffectValue = 5;
        for (int i = 0; i < kArr.Length; i++)
        {
            if (i > 0)
            {
                if (kArr[i].j >= kArr[i].k && kArr[i - 1].j <= kArr[i - 1].k && Math.Abs(kArr[i].j - 50) > unEffectValue && Math.Abs(kArr[i].k - 50) > unEffectValue)
                {
                    DBHelper.InsertData("kdj_alert", new string[,] {
                        { "gid", "varchar", kArr[i].gid.Trim()},
                        { "alert_time", "datetime", kArr[i].endDateTime.ToString()},
                        { "type", "varchar", kArr[i].type},
                        { "price", "float", kArr[i].endPrice.ToString()}
                    });
                }
            }
        }
    }

    

    /*
    public static double GetHighestPrice(string gid, DateTime startDate, DateTime endDate)
    {
        KLine[] kArr = GetKLineDayFromSohu(gid, startDate, endDate);
        double ret = 0;
        foreach (KLine k in kArr)
        {
            ret = Math.Max(ret, k.highestPrice);
        }
        return ret;
    }
    */

}