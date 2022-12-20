using System;
using System.Collections;
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
    public double turnOver = 0;

    public double increaseRateOpen = 0;
    public double increaseRateHighest = 0;
    public double increaseRateLowest = 0;
    public double increaseRateShake = 0;
    public double increaseRateSettle = 0;

    public double rsv = 0;
    public double k = 0;
    public double d = 0;
    public double j = 0;
    public double dif = 0;
    public double dea = 0;
    public double macd = 0;
    //public double typ = 0;
    public double cci = 0;

    

    public double[] boll = new double[] { 0, 0, 0 };

    public double dd = 0;

    public double width = 0;

    public static DataTable currentKLineTable = new DataTable();


    //public double ma = 0;

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
                case "60min":
                    endTime = startDateTime.Add(new TimeSpan(1, 0, 0));
                    break;
                case "1min":
                    endTime = startDateTime.AddMinutes(1);
                    break;
                case "month":
                    endTime = startDateTime.AddMonths(1).AddDays(-1);
                    break;
                case "week":
                    for (int i = 1; i <= 4; i++)
                    {
                        endTime = startDateTime.AddDays(i);
                        if (!Util.IsTransacDay(endTime))
                        {
                            endTime = endTime.AddDays(-1);
                            break;
                        }

                    }
                    endTime = endTime.Date.AddHours(15);
                    break;
                default:
                    endTime = startDateTime;
                    break;
            }
            return endTime;
        }
    }

    public double VirtualVolume
    {
        get
        {
            double virtualVolume = volume;
            if (DateTime.Now.Date == startDateTime.Date)
            {
                TimeSpan totalTranTime = new TimeSpan(4, 0, 0);
                TimeSpan currentTimeSpan;
                if (DateTime.Now <= DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30"))
                {
                    virtualVolume = 0;
                }
                else if (DateTime.Now <= DateTime.Parse(DateTime.Now.ToShortDateString() + " 11:30"))
                {
                    currentTimeSpan = DateTime.Now - DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30");
                    virtualVolume = volume / ((double)currentTimeSpan.TotalMinutes / (double)totalTranTime.TotalMinutes);
                }
                else if (DateTime.Now <= DateTime.Parse(DateTime.Now.ToShortDateString() + " 13:00"))
                {
                    virtualVolume = volume * 2;
                }
                else if (DateTime.Now <= DateTime.Parse(DateTime.Now.ToShortDateString() + " 15:00"))
                {
                    currentTimeSpan = new TimeSpan(2, 0, 0) + (DateTime.Now - DateTime.Parse(DateTime.Now.ToShortDateString() + " 13:00"));
                    virtualVolume = volume / ((double)currentTimeSpan.TotalMinutes / (double)totalTranTime.TotalMinutes);
                }
            }
            return virtualVolume;
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
                { "ext_data", "varchar", ""},
                { "create_date", "datetime", DateTime.Now.ToString()}
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
                { "ext_data", "varchar", ""},
                { "create_date", "datetime", DateTime.Now.ToString()},
            }, new string[,] {
                { "gid", "varchar", gid.Trim()},
                { "start_date", "datetime", startDateTime.ToString() },
                { "type", "varchar", type.Trim()}
            }, Util.conStr);
        }
        dt.Dispose();
    }

    public static string cacheStatus = "idle";

    public void SaveCache()
    {
        //cacheStatus = "busy";
        DBHelper.DeleteData("cache_k_line_day", new string[,] { { "gid", "varchar", gid.Trim() }, { "start_date", "datetime", startDateTime.ToString() } }, Util.conStr);
        try
        {

            DBHelper.InsertData("cache_k_line_day", new string[,] {
                { "gid", "varchar", gid.Trim()},
                { "start_date", "datetime", startDateTime.ToString() },
                { "[open]", "float", startPrice.ToString()},
                { "settle", "float", endPrice.ToString()},
                { "highest", "float", highestPrice.ToString()},
                { "lowest", "float", lowestPrice.ToString()},
                { "volume", "int", volume.ToString()},
                { "amount", "float", amount.ToString()}
            });

        }
        catch (Exception err)
        {

        }
        //cacheStatus = "idle";
    }

    public DateTime HighestTime
    {
        get
        {
            DataTable dtHighest = DBHelper.GetDataTable(" select max(trade) from  " + gid.Trim() + "_timeline where ticktime >= '" + startDateTime.ToShortDateString()
                + "'  and ticktime < '" + startDateTime.ToShortDateString() + " 23:59:59' ");
            if (dtHighest.Rows.Count == 0)
                return DateTime.MinValue;
            try
            {
                double highestPrice = double.Parse(dtHighest.Rows[0][0].ToString());
                dtHighest = DBHelper.GetDataTable(" select top 1 ticktime from " + gid.Trim() + "_timeline where trade = " + highestPrice.ToString() + " and ticktime >= '"
                    + startDateTime.ToShortDateString() + "'  and ticktime < '" + startDateTime.ToShortDateString() + " 23:59:59' order by ticktime ");
                if (dtHighest.Rows.Count == 0)
                    return DateTime.MinValue;
                return DateTime.Parse(dtHighest.Rows[0][0].ToString());
            }
            catch
            {
                return DateTime.MinValue;
            }
        }
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

    public bool IsCrossStar
    {
        get
        {
            if (Math.Abs(startPrice - endPrice) / startPrice < 0.01)
            {
                return true;
            }
            return false;
        }
    }

    public double EntityHighPrice
    {
        get
        {
            return Math.Max(startPrice, endPrice);
        }
    }

    public double EntityLowPrice
    {
        get
        {
            return Math.Min(startPrice, endPrice);
        }
    }

    public bool HaveMast
    {
        get
        {
            bool value = false;
            if (highestPrice - Math.Max(startPrice, endPrice) > 1.5 * (Math.Min(startPrice, endPrice) - lowestPrice) &&
                highestPrice - Math.Max(startPrice, endPrice) > 1.5 * Math.Abs(startPrice - endPrice))
                value = true;
            return value;
        }
    }

    public bool HaveTail
    {
        get
        {
            bool value = false;
            if (Math.Min(startPrice, endPrice) - lowestPrice > 1.5 * (highestPrice - Math.Max(startPrice, endPrice)) &&
                Math.Min(startPrice, endPrice) - lowestPrice > 1.5 * Math.Abs(startPrice - endPrice))
                value = true;
            return value;
        }
    }

    public double IOVolumeDiff
    {
        get
        {
            double ret = 0;
            DataTable dt = DBHelper.GetDataTable(" select * from io_volume where gid = '" + gid.Trim() + "' and trans_date_time = '" + endDateTime.ToShortDateString() + "' ");
            if (dt.Rows.Count == 1)
            {
                double inVolume = double.Parse(dt.Rows[0]["in_volume"].ToString());
                double outVolume = double.Parse(dt.Rows[0]["out_volume"].ToString());
                ret = (outVolume - inVolume) / inVolume;
            }
            dt.Dispose();
            return ret;
        }
    }

    public double TurnOverRate
    {
        get
        {
            double rate = 0;
            DataTable dt = DBHelper.GetDataTable(" select * from turnover where gid = '" + gid.Trim() + "' and alert_date = '"
                + startDateTime.Date.ToShortDateString() + "' ");
            if (dt.Rows.Count > 0)
            {
                rate = double.Parse(dt.Rows[0]["turnover_rate"].ToString());
            }
            else
            {
                Stock s = new Stock(gid.Trim());
                double total = s.TotalStockCount(startDateTime.Date);
                if (total == 0)
                {
                    rate = 0;
                }
                else
                {
                    rate = VirtualVolume / total;
                }
                
            }
            dt.Dispose();
            return rate;
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
        for (int i = 0; i < oArr.Length; i++)
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
        if (endDate == DateTime.Parse(DateTime.Now.ToShortDateString()) && Util.IsTransacDay(endDate)
            && kLineArr[kLineArr.Length - 1].startDateTime < endDate)
        {
            KLine k = GetTodayKLine(gid);
            if (k != null)
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
                if (k.endPrice == 0)
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

    public static double ComputeLc(KLine[] kArr, int index)
    {
        if (index <= 0)
        {
            return -1;
        }
        return kArr[index - 1].endPrice;
    }

    public static double GetLowestPrice(KLine[] kArr, int index, int days)
    {
        double lowestPrice = double.MaxValue;
        for (int i = 0; i < days; i++)
        {
            lowestPrice = Math.Min(kArr[index - i].lowestPrice, lowestPrice);
        }
        return lowestPrice;
    }
    /*
    public static double GetHighestPrice(KLine[] kArr, int index, int days)
    {
        double highestPrice = double.MinValue;
        for (int i = 0; i < days; i++)
        {
            highestPrice = Math.Max(kArr[index - i].lowestPrice, highestPrice);
        }
        return highestPrice;
    }
    */
    public static double ComputeRisk(KLine[] kArr, int index)
    {
        if (index < 0)
            return -100;
        if (kArr.Length <= index)
            return -100;

        double risk = 0;
        double rsi1U = (Math.Max(kArr[index].endPrice - kArr[index - 1].endPrice, 0)
            + Math.Max(kArr[index - 1].endPrice - kArr[index - 2].endPrice, 0)
            + Math.Max(kArr[index - 2].endPrice - kArr[index - 3].endPrice, 0))/3;
        double rsi1L = (Math.Abs(kArr[index].endPrice - kArr[index - 1].endPrice)
            + Math.Abs(kArr[index - 1].endPrice - kArr[index - 2].endPrice)
            + Math.Abs(kArr[index - 2].endPrice - kArr[index - 3].endPrice)) / 3;
        double rsi1 = rsi1U / rsi1L * 100;

        double rsi2U = (Math.Max(kArr[index].endPrice - kArr[index - 1].endPrice, 0)
            + Math.Max(kArr[index - 1].endPrice - kArr[index - 2].endPrice, 0)
            + Math.Max(kArr[index - 2].endPrice - kArr[index - 3].endPrice, 0)
            + Math.Max(kArr[index - 3].endPrice - kArr[index - 4].endPrice, 0)
            + Math.Max(kArr[index - 4].endPrice - kArr[index - 5].endPrice, 0)) / 5;
        double rsi2L = (Math.Abs(kArr[index].endPrice - kArr[index - 1].endPrice)
            + Math.Abs(kArr[index - 1].endPrice - kArr[index - 2].endPrice)
            + Math.Abs(kArr[index - 2].endPrice - kArr[index - 3].endPrice)
            + Math.Abs(kArr[index - 3].endPrice - kArr[index - 4].endPrice)
            + Math.Abs(kArr[index - 4].endPrice - kArr[index - 5].endPrice)) / 5;
        double rsi2 = rsi2U / rsi2L * 100;

        double rsi3U = (Math.Max(kArr[index].endPrice - kArr[index - 1].endPrice, 0)
            + Math.Max(kArr[index - 1].endPrice - kArr[index - 2].endPrice, 0)
            + Math.Max(kArr[index - 2].endPrice - kArr[index - 3].endPrice, 0)
            + Math.Max(kArr[index - 3].endPrice - kArr[index - 4].endPrice, 0)
            + Math.Max(kArr[index - 4].endPrice - kArr[index - 5].endPrice, 0)
            + Math.Max(kArr[index - 5].endPrice - kArr[index - 6].endPrice, 0)
            + Math.Max(kArr[index - 6].endPrice - kArr[index - 7].endPrice, 0)
            + Math.Max(kArr[index - 7].endPrice - kArr[index - 8].endPrice, 0)) / 8;
        double rsi3L = (Math.Abs(kArr[index].endPrice - kArr[index - 1].endPrice)
            + Math.Abs(kArr[index - 1].endPrice - kArr[index - 2].endPrice)
            + Math.Abs(kArr[index - 2].endPrice - kArr[index - 3].endPrice)
            + Math.Abs(kArr[index - 3].endPrice - kArr[index - 4].endPrice)
            + Math.Abs(kArr[index - 4].endPrice - kArr[index - 5].endPrice)
            + Math.Abs(kArr[index - 5].endPrice - kArr[index - 6].endPrice)
            + Math.Abs(kArr[index - 6].endPrice - kArr[index - 7].endPrice)
            + Math.Abs(kArr[index - 7].endPrice - kArr[index - 8].endPrice)) / 8;
        double rsi3 = rsi3U / rsi3L * 100;
        double rsi = 0.5 * rsi1 + 0.31 * rsi2 + 0.19 * rsi3;
        /*
        double wave1 = (100 * (kArr[index].endPrice - GetLowestPrice(kArr, index, 8)) / (GetHighestPrice(kArr, index, 8) - GetLowestPrice(kArr, index, 8))
            + 100 * (kArr[index-1].endPrice - GetLowestPrice(kArr, index-1, 8)) / (GetHighestPrice(kArr, index-1, 8) - GetLowestPrice(kArr, index-1, 8)) 
            + 100 * (kArr[index - 2].endPrice - GetLowestPrice(kArr, index - 2, 8)) / (GetHighestPrice(kArr, index - 2, 8) - GetLowestPrice(kArr, index - 2, 8))) / 3;
        double wave1L = 
        */

        double wave1 = (100 * (kArr[index].endPrice - GetLowestPrice(kArr, index, 8)) / (GetHighestPrice(kArr, index, 8) - GetLowestPrice(kArr, index, 8))
            + 100 * (kArr[index - 1].endPrice - GetLowestPrice(kArr, index - 1, 8)) / (GetHighestPrice(kArr, index - 1, 8) - GetLowestPrice(kArr, index - 1, 8))
            + 100 * (kArr[index - 2].endPrice - GetLowestPrice(kArr, index - 2, 8)) / (GetHighestPrice(kArr, index - 2, 8) - GetLowestPrice(kArr, index - 2, 8))) / 3;
        double wave2 = (100 * (kArr[index].endPrice - GetLowestPrice(kArr, index, 8)) / (GetHighestPrice(kArr, index, 8) - GetLowestPrice(kArr, index, 8))
            + 100 * (kArr[index - 1].endPrice - GetLowestPrice(kArr, index - 1, 8)) / (GetHighestPrice(kArr, index - 1, 8) - GetLowestPrice(kArr, index - 1, 8))
            + 100 * (kArr[index - 2].endPrice - GetLowestPrice(kArr, index - 2, 8)) / (GetHighestPrice(kArr, index - 2, 8) - GetLowestPrice(kArr, index - 2, 8))
            + 100 * (kArr[index - 3].endPrice - GetLowestPrice(kArr, index - 3, 8)) / (GetHighestPrice(kArr, index - 3, 8) - GetLowestPrice(kArr, index - 3, 8))
            + 100 * (kArr[index - 4].endPrice - GetLowestPrice(kArr, index - 4, 8)) / (GetHighestPrice(kArr, index - 4, 8) - GetLowestPrice(kArr, index - 4, 8))) / 5;
        double wave3 = (100 * (kArr[index].endPrice - GetLowestPrice(kArr, index, 8)) / (GetHighestPrice(kArr, index, 8) - GetLowestPrice(kArr, index, 8))
            + 100 * (kArr[index - 1].endPrice - GetLowestPrice(kArr, index - 1, 8)) / (GetHighestPrice(kArr, index - 1, 8) - GetLowestPrice(kArr, index - 1, 8))
            + 100 * (kArr[index - 2].endPrice - GetLowestPrice(kArr, index - 2, 8)) / (GetHighestPrice(kArr, index - 2, 8) - GetLowestPrice(kArr, index - 2, 8))
            + 100 * (kArr[index - 3].endPrice - GetLowestPrice(kArr, index - 3, 8)) / (GetHighestPrice(kArr, index - 3, 8) - GetLowestPrice(kArr, index - 3, 8))
            + 100 * (kArr[index - 4].endPrice - GetLowestPrice(kArr, index - 4, 8)) / (GetHighestPrice(kArr, index - 4, 8) - GetLowestPrice(kArr, index - 4, 8))
            + 100 * (kArr[index - 5].endPrice - GetLowestPrice(kArr, index - 5, 8)) / (GetHighestPrice(kArr, index - 5, 8) - GetLowestPrice(kArr, index - 5, 8))
            + 100 * (kArr[index - 6].endPrice - GetLowestPrice(kArr, index - 6, 8)) / (GetHighestPrice(kArr, index - 6, 8) - GetLowestPrice(kArr, index - 6, 8))
            + 100 * (kArr[index - 7].endPrice - GetLowestPrice(kArr, index - 7, 8)) / (GetHighestPrice(kArr, index - 7, 8) - GetLowestPrice(kArr, index - 7, 8))
            ) / 8;


        double wave = 0.5 * wave1 + 0.31 * wave2 + 0.19 * wave3;

        risk = 0.5 * wave + 0.5 * rsi;

        //double rsi1 = 
        return risk;
    }

    public static double ComputeMacdDegree(KLine[] kArr, int index)
    {
        if (index < 0)
            return -100;
        if (kArr.Length <= index)
            return -100;

        int minMacdIndex = index;
        double minMacd = kArr[index].macd;
        for (int i = index - 1; kArr[i].macd < 0 && i >= 0; i--)
        {
            if (minMacd >= kArr[i].macd)
            {
                minMacd = kArr[i].macd;
                minMacdIndex = i;
            }
        }
        if (index - minMacdIndex > 0)
            return (kArr[index].macd - minMacd) / ((double)(index - minMacdIndex));
        else
            return 0;
    }

    public static double ComputeKdjDegree(KLine[] kArr, int index)
    {
        if (index < 0)
            return -100;
        double minJ = kArr[index].j;
        int minJIndex = index;
        int crossTimes = 0;
        for (int i = index - 1; crossTimes <= 1 && i >= 0; i--)
        {
            if ((kArr[i].d > kArr[i].k && kArr[i].k > kArr[i].j && kArr[i + 1].j > kArr[i + 1].k && kArr[i + 1].k > kArr[i + 1].d)
                || (kArr[i].d < kArr[i].k && kArr[i].k < kArr[i].j && kArr[i + 1].j < kArr[i + 1].k && kArr[i + 1].k < kArr[i + 1].d))
            {
                crossTimes++;
            }
            if (minJ >= kArr[i].j)
            {
                minJ = kArr[i].j;
                minJIndex = i;
            }
        }
        if (index - minJIndex > 0)
        {
            return kArr[index].j - minJ / (double)(index - minJIndex);
        }
        else
        {
            return 0;
        }
    }

    public static int Above3LineDays(Stock s, int index)
    {
        int days = 0;
        if (s.kLineDay[index].endPrice <= s.GetAverageSettlePrice(index, 3, 3))
        {
            return -1;
        }
        for (int i = index - 1; i >= 0 && s.kLineDay[i].endPrice > s.GetAverageSettlePrice(index, 3, 3); i--)
        {
            days++;
        }
        return days;
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

    public static void ComputeRSV(KLine[] kArr)
    {
        int valueN = 8;
        for (int i = valueN - 1; i < kArr.Length; i++)
        {
            KLine[] rsvArr = GetSubKLine(kArr, i - valueN + 1, valueN);
            double lowPrice = GetLowestPrice(rsvArr);
            double hiPrice = GetHighestPrice(rsvArr);
            kArr[i].rsv = 100 * (kArr[i].endPrice - lowPrice) / (hiPrice - lowPrice);
        }

    }

    public static void ComputeKDJ(KLine[] kArr)
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
    }

    public static double ema(double[] xArr, int currentIndex, int n)
    {
        try
        {
            if (currentIndex == 0)
                return xArr[currentIndex];
            else
            {
                try
                {
                    return (xArr[currentIndex] * 2 + ema(xArr, currentIndex - 1, n) * (double)(n - 1)) / (double)(n + 1);
                }
                catch
                {
                    return xArr[currentIndex];
                }
            }
        }
        catch
        {
            return xArr[0];
        }
    }

    public static void ComputeMACD(KLine[] kArr)
    {
        int shortDays = 8;
        int longDays = 17;
        int midDays = 9;



        double[] endPirceArr = new double[kArr.Length];
        double[] difArr = new double[kArr.Length];

        for (int i = 0; i < kArr.Length; i++)
        {
            endPirceArr[i] = kArr[i].endPrice;
            difArr[i] = 0;
        }

        for (int i = 1; i < kArr.Length; i++)
        {
            try
            {
                kArr[i].dif = ema(endPirceArr, i, shortDays) - ema(endPirceArr, i, longDays);
                difArr[i] = kArr[i].dif;
                kArr[i].dea = ema(difArr, i, midDays);
                kArr[i].macd = (kArr[i].dif - kArr[i].dea) * 2;
            }
            catch
            {
                break;
            }
        }
    }

    public static double ComputeDMP(KLine[] kArr, int index)
    {
        if (index <= 18 || kArr.Length <= index)
        {
            return 0;
        }
        double dmp = 0;
        KLine.ComputeMACD(kArr);
        double tempPrice = kArr[index].endPrice;
        if (kArr[index].macd == 0)
        {
            dmp = kArr[index].endPrice;
        }
        else if (kArr[index].macd > 0)
        {
            for (; kArr[index].macd > 0 && kArr[index].endPrice > 0; kArr[index].endPrice = kArr[index].endPrice - 0.01)
            {
                KLine.ComputeMACD(kArr);
                if (kArr[index].macd <= 0)
                {
                    dmp = kArr[index].endPrice;
                    break;
                }
            }
        }
        else if (kArr[index].macd < 0)
        {
            for (; kArr[index].macd < 0 && kArr[index].endPrice < 9999; kArr[index].endPrice = kArr[index].endPrice + 0.01)
            {
                KLine.ComputeMACD(kArr);
                if (kArr[index].macd >= 0)
                {
                    dmp = kArr[index].endPrice;
                    break;
                }
            }
        }
        kArr[index].endPrice = tempPrice;
        KLine.ComputeMACD(kArr);
        return dmp;
    }

    public static double GetMACDFolkPrice(KLine[] kArr, int index)
    {
        KLine[] kArrNew = new KLine[kArr.Length];
        for (int i = 0; i < kArr.Length; i++)
        {
            kArrNew[i] = new KLine();
            kArrNew[i].startPrice = kArr[i].startPrice;
            kArrNew[i].endPrice = kArr[i].endPrice;
            kArrNew[i].lowestPrice = kArr[i].lowestPrice;
            kArrNew[i].highestPrice = kArr[i].highestPrice;
        }
        if (!StockWatcher.IsMacdFolk(kArr, index))
            return 0;
        double settle = kArrNew[index].endPrice;
        double folkPrice = 0;
        for (kArrNew[index].endPrice = kArrNew[index].lowestPrice;
             kArrNew[index].endPrice <= kArrNew[index].highestPrice;
             kArrNew[index].endPrice = kArrNew[index].endPrice + 0.01)
        {
            KLine.ComputeMACD(kArrNew);
            if (kArrNew[index - 1].macd < 0 && kArrNew[index].macd >= 0)
            {
                folkPrice = kArrNew[index].endPrice;
                break;
            }

        }
        return folkPrice;
    }

    public double TYP
    {
        get
        {
            return (highestPrice + lowestPrice + endPrice) / 3;
        }
    }

    public static void ComputeCci(KLine[] kArr)
    {
        int n = 14;
        if (kArr.Length < n)
            return;
        for (int i = kArr.Length - 1; i >= n; i--)
        {
            KLine k = kArr[i];
            //k.typ = (k.highestPrice + k.lowestPrice + k.endPrice) / 3;
            double avgNTyp = 0;
            for (int j = i; j > i - n && j >= 0; j--)
            {
                avgNTyp = avgNTyp + kArr[j].TYP;
            }
            avgNTyp = avgNTyp / n;

            double aveDevValue = 0;

            for (int j = i; j > i - n && j >= 0; j--)
            {
                aveDevValue = aveDevValue + Math.Abs(kArr[j].TYP - avgNTyp);
            }
            aveDevValue = aveDevValue / n;
            kArr[i].cci = (kArr[i].TYP - avgNTyp) / (0.015 * aveDevValue);
        }

    }

    public static void SearchMACDAlert(KLine[] kArr)
    {
        SearchMACDAlert(kArr, 1);

    }


    public static void SearchMACDAlert(KLine[] kArr, int startIndex)
    {
        for (int i = startIndex; i < kArr.Length; i++)
        {
            if (StockWatcher.IsMacdFolk(kArr, i))
            {
                try
                {
                    double macdPrice = KLine.GetMACDFolkPrice(kArr, i);
                    if (macdPrice > 0)
                    {
                        StockWatcher.LogMacd(kArr[i].gid.Trim(), "day", kArr[i].endDateTime,
                            macdPrice, kArr[i].dif, kArr[i].dea, kArr[i].macd);
                    }
                }
                catch
                {

                }

            }
        }
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
                    try
                    {

                        DBHelper.InsertData("kdj_alert", new string[,] {
                            { "gid", "varchar", kArr[i].gid.Trim()},
                            { "alert_time", "datetime", kArr[i].endDateTime.ToString()},
                            { "type", "varchar", kArr[i].type},
                            { "price", "float", kArr[i].endPrice.ToString()}
                        });
                    }
                    catch
                    {

                    }
                }
            }
        }
    }

    public static void SearchKDJAlert(KLine[] kArr, int startIndex)
    {
        for (int i = startIndex; i < kArr.Length; i++)
        {
            if (i > 0)
            {
                if (StockWatcher.IsKdjFolk(kArr, startIndex))
                {
                    try
                    {
                        StockWatcher.LogKdj(kArr[i].gid.Trim(), "day", kArr[i].endDateTime, kArr[i].endPrice, kArr[i].k, kArr[i].d, kArr[i].j);
                    }
                    catch
                    {

                    }
                }
            }
        }
    }

    public static int GetStartIndexForDay(KLine[] kArr, DateTime currentDate)
    {
        int index = -1;
        for (int i = kArr.Length - 1; i >= 0; i--)
        {
            if (kArr[i].startDateTime <= currentDate)
            {
                index = i;
                break;
            }
        }
        return index;
    }

    public static KLine[] GetLocalKLine(string gid, string type)
    {
        DataTable dt = DBHelper.GetDataTable(" select * from " + gid.Trim() + "_k_line where type = '" + type + "' order by start_date ");
        KLine[] kArr = new KLine[dt.Rows.Count];
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            kArr[i] = new KLine();
            kArr[i].gid = gid.Trim();
            kArr[i].type = type.Trim();
            kArr[i].startPrice = double.Parse(dt.Rows[i]["open"].ToString().Trim());
            kArr[i].endPrice = double.Parse(dt.Rows[i]["settle"].ToString().Trim());
            kArr[i].highestPrice = double.Parse(dt.Rows[i]["highest"].ToString().Trim());
            kArr[i].lowestPrice = double.Parse(dt.Rows[i]["lowest"].ToString().Trim());
            kArr[i].volume = int.Parse(dt.Rows[i]["volume"].ToString().Trim());
            kArr[i].amount = double.Parse(dt.Rows[i]["amount"].ToString().Trim());
            kArr[i].startDateTime = DateTime.Parse(dt.Rows[i]["start_date"].ToString().Trim());
        }
        return kArr;
    }

    public static KLine GetTodayLocalKLine(string gid, string type)
    {
        DataTable dt = DBHelper.GetDataTable(" select top 1 * from " + gid.Trim() + "_k_line where type = '"
            + type + "' and  start_date > '" + DateTime.Now.ToShortDateString() + "' ");
        KLine k = new KLine();
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            k.gid = gid.Trim();
            k.type = type.Trim();
            k.startPrice = double.Parse(dt.Rows[i]["open"].ToString().Trim());
            k.endPrice = double.Parse(dt.Rows[i]["settle"].ToString().Trim());
            k.highestPrice = double.Parse(dt.Rows[i]["highest"].ToString().Trim());
            k.lowestPrice = double.Parse(dt.Rows[i]["lowest"].ToString().Trim());
            k.volume = int.Parse(dt.Rows[i]["volume"].ToString().Trim());
            k.amount = double.Parse(dt.Rows[i]["amount"].ToString().Trim());
            k.startDateTime = DateTime.Parse(dt.Rows[i]["start_date"].ToString().Trim());
        }
        return k;
    }

    public static KLine[] LoadTodaysKLine()
    {
        string[] gidArr = Util.GetAllGids();
        string sql = "";
        foreach (string gid in gidArr)
        {
            string subSql = " select top 1 * from  " + gid + "_k_line where type = 'day' and start_date > '" + DateTime.Now.ToShortDateString() + "' ";
            sql = sql + (sql.Trim().Equals("") ? "" : " union ") + subSql;
        }
        DataTable dt = DBHelper.GetDataTable(sql);
        KLine[] currentKLineArray = new KLine[dt.Rows.Count];
        return currentKLineArray;
    }

    public static void RefreshKLine(string gid, DateTime currentDate)
    {
        KLine.CreateKLineTable(gid);
        KLine[] kArr1Min = TimeLine.Create1MinKLine(gid, DateTime.Parse(currentDate.ToShortDateString()));
        KLine[] kArr = TimeLine.AssembKLine("day", kArr1Min);
        foreach (KLine k in kArr)
        {
            k.Save();
            k.SaveCache();
        }
        kArr = TimeLine.AssembKLine("1hr", kArr1Min);
        foreach (KLine k in kArr)
        {
            k.Save();
        }

        /*
        kArr = TimeLine.AssembKLine("30min", kArr1Min);
        foreach (KLine k in kArr)
        {
            k.Save();
        }
        kArr = TimeLine.AssembKLine("15min", kArr1Min);
        foreach (KLine k in kArr)
        {
            k.Save();
        }
        */
    }

    public static void SearchKDJAlert(string gid, string type, DateTime currentDate)
    {
        KLine[] kArr = GetLocalKLine(gid, type);
        ComputeRSV(kArr);
        ComputeKDJ(kArr);
        int index = GetStartIndexForDay(kArr, DateTime.Parse(currentDate.ToShortDateString()));
        SearchKDJAlert(kArr, index);

    }

    public static int GetBottomDeep(KLine[] kArr, int currentIndex)
    {
        int ret = 0;
        for (int i = currentIndex; i > 0 && currentIndex < kArr.Length; i--)
        {
            if (kArr[i - 1].endPrice >= kArr[i].endPrice)
            {
                ret++;

            }
            else
            {
                break;
            }
        }

        return ret;
    }

    public static double GetAverageSettlePrice(KLine[] kArr, int index, int itemsCount, int displacement)
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

    public static int GetLastDeMarkBuyPointIndex(KLine[] kArr, int index)
    {
        int newIndex = 0;
        for (int i = index; i >= 9; i--)
        {
            if (ComputeDeMarkValue(kArr, i) == -9)
            {
                newIndex = i;
                break;
            }
        }
        return newIndex;
    }

    public static int ComputeDeMarkValue(KLine[] kArr, int index)
    {
        if (index < 12)
            return 0;
        int deMarkValue = 0;
        bool isRaise = false;
        if (kArr[index].endPrice > kArr[index - 4].endPrice)
            isRaise = true;
        for (int i = 0; i < 9; i++)
        {
            if (kArr[index - i].endPrice > kArr[index - i - 4].endPrice && isRaise)
            {
                deMarkValue++;
            }
            else if (kArr[index - i].endPrice < kArr[index - i - 4].endPrice && !isRaise)
            {
                deMarkValue++;
            }
            else
            {
                break;
            }
        }
        return isRaise ? deMarkValue : deMarkValue * -1;

    }

    public static string ComputeDeMarkCount(KLine[] kArr, int index)
    {
        ArrayList countQ = new ArrayList();
        string retValue = "";
        for (int i = index; i >= 13; i--)
        {
            int deMarkValue = ComputeDeMarkValue(kArr, i);
            if (Math.Abs(deMarkValue) == 9)
            {
                bool buyStruct = deMarkValue < 0;
                int count = 0;
                for (int j = i; j <= index; j++)
                {

                    if (buyStruct)
                    {
                        if (kArr[j].endPrice <= kArr[j - 2].lowestPrice && count <= 11)
                        {
                            count++;
                            countQ.Add(j);
                            retValue = (-1 * count).ToString();
                        }
                        else if (count >= 12 && kArr[j].endPrice <= kArr[j - 2].lowestPrice)
                        {
                            if (kArr[j].lowestPrice <= kArr[(int)countQ[8]].endPrice)
                            {
                                count++;
                                retValue = (-1 * count).ToString();
                            }
                            else
                            {

                                retValue = "--";
                            }
                        }
                        else
                        {
                            retValue = "-(" + count.ToString() + ")";
                        }
                    }
                    else
                    {
                        if (kArr[j].endPrice >= kArr[j - 2].highestPrice && count <= 11)
                        {
                            count++;
                            countQ.Add(j);
                            retValue = "+" + count.ToString();
                        }
                        else if (count >= 12 && kArr[j].endPrice >= kArr[j - 2].highestPrice)
                        {
                            if (kArr[j].highestPrice >= kArr[(int)countQ[8]].endPrice)
                            {
                                count++;
                                retValue = "+" + count.ToString();
                            }
                            else
                            {

                                retValue = "++";
                            }

                        }
                        else
                        {
                            retValue = "+(" + count.ToString() + ")";
                        }
                    }
                }
                break;
            }

        }
        return retValue;
    }

    public static bool IsCross3Line(KLine[] kArr, int index)
    {
        bool ret = false;
        if (kArr[index].endPrice > GetAverageSettlePrice(kArr, index, 3, 3)
            && (kArr[index].startPrice <= GetAverageSettlePrice(kArr, index, 3, 3) || kArr[index - 1].endPrice <= GetAverageSettlePrice(kArr, index - 1, 3, 3)))
        {
            ret = true;
        }
        return ret;
    }

    public static bool IsCros3LineTwice(KLine[] kArr, int index, int days)
    {
        bool ret = false;
        try
        {
            for (int i = index - 1; i >= index - days; i--)
            {
                ret = ret || IsCross3Line(kArr, i);
                if (ret)
                {
                    break;
                }
            }
        }
        catch
        {

        }
        return ret && IsCross3Line(kArr, index);

    }

    public static bool IsJumpHigh(KLine[] kArr, int index)
    {
        if (index <= 0)
            return false;
        double macdPrice = KLine.GetMACDFolkPrice(kArr, index - 1);
        if (macdPrice <= 0)
            return false;
        if (kArr[index].startPrice > macdPrice)
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    public static double GetHighestPrice(KLine[] kArr, int index, int days)
    {
        double highestPrice = 0;
        for (int i = 0; i < days && index - i >= 0; i++)
        {
            highestPrice = Math.Max(kArr[index - i].highestPrice, highestPrice);
        }
        return highestPrice;
    }

    public static double ComputeSTD(KLine[] kArr, int index, int n)
    {
        double squareS = 0;
        for (int i = 0; i < n; i++)
        {
            double z = (kArr[index - i].endPrice - GetAverageSettlePrice(kArr, index - 1, n, 0));
            squareS = squareS + z * z;
        }
        squareS = squareS / n;
        return Math.Sqrt(squareS);
    }

    public static double[] ComputeBoll(KLine[] kArr, int index, int n)
    {
        if (kArr.Length > n && index > n)
        {
            double std = ComputeSTD(kArr, index, n);

            double ma = GetAverageSettlePrice(kArr, index, n, 0);

            return new double[] { ma + std * 2, ma, ma - std * 2 };
        }
        return new double[] { 0, 0, 0 };
    }

    public static double ComputeBB(KLine[] kArr, int index, int n)
    {
        double[] boll = ComputeBoll(kArr, index, n);
        if (boll[0] - boll[2] == 0)
        {
            return 0;
        }
        else
        {
            return (kArr[index].endPrice - boll[1]) / ComputeSTD(kArr, index, n);
        }
    }

    public static double ComputeBBWidth(KLine[] kArr, int index, int n)
    {
        double[] boll = ComputeBoll(kArr, index, n);
        return (boll[0] - boll[2]) / GetAverageSettlePrice(kArr, index, n, 0);
    }
}