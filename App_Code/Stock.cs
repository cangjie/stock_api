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

    public Stock()
    {
        //
        // TODO: Add constructor logic here
        //
    }

    public Stock(string gid)
    {
        this.gid = gid;
        DataTable dt = DBHelper.GetDataTable(" select top 1 * from " + gid.Trim() + "_timeline order by ticktime desc ");
        if (dt.Rows.Count > 0)
            drLastTimeline = dt.Rows[0];
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
        int ret = -1;
        for (int i = kArr.Length - 1; i >= 0; i--)
        {
            if (kArr[i].startDateTime == currentDate)
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
}