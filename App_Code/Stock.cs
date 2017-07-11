using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;

/// <summary>
/// Summary description for Stock
/// </summary>
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

        kLineDay = LoadLocalKLine(gid, "day");
        kLineHour = LoadLocalKLine(gid, "1hr");
        kLineHalfHour = LoadLocalKLine(gid, "30min");
        kLineQuaterHour = LoadLocalKLine(gid, "15min");
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

    public int GetItemIndex(DateTime currentDate)
    {
        int k = -1;
        for (int i = 0; i < kArr.Length; i++)
        {
            if (kArr[i].startDateTime == currentDate)
            {
                k = i;
                break;
            }
        }
        return k;
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
        if (settle > 0 && open < avg3X3 && end > avg3X3 && ((end - open) / open) >= 0.5 && ((end - settle) / settle) <= 0.9)
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
        if (open < avg3X3 && end > avg3X3 )
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

    public double LastTrade
    {
        get
        {
            if (drLastTimeline != null)
            {
                return double.Parse(drLastTimeline["trade"].ToString().Trim());
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
                && DateTime.Parse(drLastTimeline["ticktime"].ToString()) >= DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30" ) )
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

    public double HighestPrice(DateTime currentDate, int days)
    {
        int currentDateIndex = GetKLineIndexForADay(currentDate);
        if (currentDateIndex < 0)
            return 0;
        double maxPrice = 0;
        for (int i = 0; i < days && currentDateIndex - i >=0 ; i++)
        {
            maxPrice = Math.Max(maxPrice, kArr[currentDateIndex-i].highestPrice);
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
        goldLineArray[3] = minPrice ;
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

    public static KLine[] LoadLocalKLine(string gid, string type)
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
            kArr[i].highestPrice = double.Parse(dt.Rows[i]["highest"].ToString());
            kArr[i].lowestPrice = double.Parse(dt.Rows[i]["lowest"].ToString());
            kArr[i].volume = int.Parse(dt.Rows[i]["volume"].ToString());
            kArr[i].amount = double.Parse(dt.Rows[i]["amount"].ToString());
        }
        return kArr;
    }

    public static double[] GetVolumeAndAmount(string gid, DateTime currentDate)
    {
       
        DataTable dtTimeline = DBHelper.GetDataTable(" select top 1 * from  " + gid.Trim() + "_timeline where ticktime <= '" + currentDate.ToString() + "' order by ticktime desc ");
        DataTable dtNormal = DBHelper.GetDataTable(" select top 1 * from  " + gid + " where convert(datetime, date + ' ' + time )  <= '" + currentDate.ToString() + "'  order by convert(datetime, date + ' ' + time ) desc   ");
        double volmue = 0;
        double amount = 0;
        if (dtTimeline.Rows.Count > 0)
        {
            volmue = double.Parse(dtTimeline.Rows[0]["volume"].ToString());
            amount = double.Parse(dtTimeline.Rows[0]["amount"].ToString());
        }
        if (dtNormal.Rows.Count > 0)
        {
            volmue = Math.Max(double.Parse(dtNormal.Rows[0]["traNumber"].ToString()), volmue);
            amount = Math.Max(double.Parse(dtNormal.Rows[0]["traAmount"].ToString()), amount);
        }
        return new double[] { volmue, amount };
    }
    
}