using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;
using System.Collections;

/// <summary>
/// Summary description for TimeLine
/// </summary>
public class TimeLine
{

    public TimeLineItem[] timeLineItemArray;

    public string gid = "";
    public string name = "";
    public double trade = 0;
    public double sell = 0;
    public double buy = 0;
    public double settle = 0;
    public double open = 0;
    public int volume = 0;
    public double amount = 0;
    public int volumeIncrease = 0;
    public double amountIncrease = 0;
    public int buy1 = 0;
    public double buy1Amount = 0;
    public int buy2 = 0;
    public double buy2Amount = 0;
    public int buy3 = 0;
    public double buy3Amount = 0;
    public int buy4 = 0;
    public double buy4Amount = 0;
    public int buy5 = 0;
    public double buy5Amount = 0;
    public int sell1 = 0;
    public double sell1Amount = 0;
    public int sell2 = 0;
    public double sell2Amount = 0;
    public int sell3 = 0;
    public double sell3Amount = 0;
    public int sell4 = 0;
    public double sell4Amount = 0;
    public int sell5 = 0;
    public double sell5Amount = 0;
    public DateTime tickTime;

    public TimeLine()
    {
        //
        // TODO: Add constructor logic here
        //
    }

    public KLine GetKLine(string type)
    {
        return new KLine();
    }

    public static TimeLine[] GetTimeLineItem(string gid, DateTime start, DateTime end)
    {
        DataTable dtTimeline = DBHelper.GetDataTable(" select * from  " + gid + "_timeline where ticktime >= '" + start.ToString() + "' and ticktime < '" + end.ToString() + "' order by ticktime ");
        DataTable dtNormal = DBHelper.GetDataTable(" select * from " + gid + "  where convert(datetime, [date] + ' ' + [time]) >='"
            + start.ToString() + "'  and  convert(datetime, [date] + ' ' + [time]) < '" + end.ToString() + "'  and 1 = 0 order by convert(datetime, [date] + ' ' + [time]) ");
        int timeLineCount = Math.Max(dtTimeline.Rows.Count, dtNormal.Rows.Count);
        TimeLine[] timeLineArray = new TimeLine[timeLineCount*2];
        int j = 0;
        for (int i = 0; i < timeLineCount; i++)
        {
            //timeLineArray[i] = new TimeLine();
            DateTime currentDateTimeLine = DateTime.Parse("2000-1-1");
            if (i < dtTimeline.Rows.Count)
            {
                currentDateTimeLine = DateTime.Parse(dtTimeline.Rows[i]["ticktime"].ToString());
            }
            DateTime currentDateTimeNormal = DateTime.Parse("2000-1-1");
            if (i < dtNormal.Rows.Count)
            {
                currentDateTimeNormal = DateTime.Parse(dtNormal.Rows[i]["date"].ToString() + " " + dtNormal.Rows[i]["time"].ToString());
            }
            if (currentDateTimeNormal == currentDateTimeLine && currentDateTimeLine != DateTime.Parse("2000-1-1"))
            {
                timeLineArray[j] = new TimeLine();
                timeLineArray[j].gid = gid;
                timeLineArray[j].name = dtNormal.Rows[i]["name"].ToString().Trim();
                timeLineArray[j].trade = double.Parse(dtTimeline.Rows[i]["trade"].ToString().Trim());
                timeLineArray[j].buy = double.Parse(dtTimeline.Rows[i]["buy"].ToString().Trim());
                timeLineArray[j].sell = double.Parse(dtTimeline.Rows[i]["sell"].ToString().Trim());
                timeLineArray[j].settle = double.Parse(dtTimeline.Rows[i]["settlement"].ToString().Trim());
                timeLineArray[j].open = double.Parse(dtTimeline.Rows[i]["open"].ToString().Trim());
                timeLineArray[j].volume = int.Parse(dtTimeline.Rows[i]["volume"].ToString().Trim());
                timeLineArray[j].amount = double.Parse(dtTimeline.Rows[i]["amount"].ToString().Trim());
                timeLineArray[j].buy1 = int.Parse(dtNormal.Rows[i]["buyOne"].ToString());
                timeLineArray[j].buy1Amount = double.Parse(dtNormal.Rows[i]["buyOnePri"].ToString());
                timeLineArray[j].buy2 = int.Parse(dtNormal.Rows[i]["buyTwo"].ToString());
                timeLineArray[j].buy2Amount = double.Parse(dtNormal.Rows[i]["buyTwoPri"].ToString());
                timeLineArray[j].buy3 = int.Parse(dtNormal.Rows[i]["buyThree"].ToString());
                timeLineArray[j].buy3Amount = double.Parse(dtNormal.Rows[i]["buyThreePri"].ToString());
                timeLineArray[j].buy4 = int.Parse(dtNormal.Rows[i]["buyFour"].ToString());
                timeLineArray[j].buy4Amount = double.Parse(dtNormal.Rows[i]["buyFourPri"].ToString());
                timeLineArray[j].buy5 = int.Parse(dtNormal.Rows[i]["buyFive"].ToString());
                timeLineArray[j].buy5Amount = double.Parse(dtNormal.Rows[i]["buyFivePri"].ToString());
                timeLineArray[j].sell1 = int.Parse(dtNormal.Rows[i]["sellOne"].ToString());
                timeLineArray[j].sell1Amount = int.Parse(dtNormal.Rows[i]["sellOnePri"].ToString());
                timeLineArray[j].sell2 = int.Parse(dtNormal.Rows[i]["sellTwo"].ToString());
                timeLineArray[j].sell2Amount = int.Parse(dtNormal.Rows[i]["sellTwoPri"].ToString());
                timeLineArray[j].sell3 = int.Parse(dtNormal.Rows[i]["sellThree"].ToString());
                timeLineArray[j].sell3Amount = int.Parse(dtNormal.Rows[i]["sellThreePri"].ToString());
                timeLineArray[j].sell4 = int.Parse(dtNormal.Rows[i]["sellFour"].ToString());
                timeLineArray[j].sell4Amount = int.Parse(dtNormal.Rows[i]["sellFourPri"].ToString());
                timeLineArray[j].sell5 = int.Parse(dtNormal.Rows[i]["sellFive"].ToString());
                timeLineArray[j].sell5Amount = int.Parse(dtNormal.Rows[i]["sellFivePri"].ToString());
                timeLineArray[j].tickTime = DateTime.Parse(dtTimeline.Rows[i]["ticktime"].ToString());
                if (j > 0)
                {
                    timeLineArray[j].volumeIncrease = timeLineArray[j].volume - timeLineArray[j - 1].volume;
                    timeLineArray[j].amountIncrease = timeLineArray[j].amount - timeLineArray[j - 1].amount;
                }
                j++;
            }
            else
            {
                if (currentDateTimeLine < currentDateTimeNormal)
                {
                    if (currentDateTimeLine != DateTime.Parse("2000-1-1"))
                    {
                        timeLineArray[j] = new TimeLine();
                        timeLineArray[j].gid = gid;
                        timeLineArray[j].name = dtTimeline.Rows[i]["name"].ToString().Trim();
                        timeLineArray[j].trade = double.Parse(dtTimeline.Rows[i]["trade"].ToString().Trim());
                        timeLineArray[j].buy = double.Parse(dtTimeline.Rows[i]["buy"].ToString().Trim());
                        timeLineArray[j].sell = double.Parse(dtTimeline.Rows[i]["sell"].ToString().Trim());
                        timeLineArray[j].settle = double.Parse(dtTimeline.Rows[i]["settlement"].ToString().Trim());
                        timeLineArray[j].open = double.Parse(dtTimeline.Rows[i]["open"].ToString().Trim());
                        timeLineArray[j].volume = int.Parse(dtTimeline.Rows[i]["volume"].ToString().Trim());
                        timeLineArray[j].amount = double.Parse(dtTimeline.Rows[i]["amount"].ToString().Trim());
                        timeLineArray[j].tickTime = DateTime.Parse(dtTimeline.Rows[i]["ticktime"].ToString());
                        if (j > 0)
                        {
                            timeLineArray[j].volumeIncrease = timeLineArray[j].volume - timeLineArray[j - 1].volume;
                            timeLineArray[j].amountIncrease = timeLineArray[j].amount - timeLineArray[j - 1].amount;
                            timeLineArray[j].buy1 = timeLineArray[j - 1].buy1;
                            timeLineArray[j].buy1Amount = timeLineArray[j - 1].buy1Amount;
                            timeLineArray[j].buy2 = timeLineArray[j - 1].buy2;
                            timeLineArray[j].buy2Amount = timeLineArray[j - 1].buy2Amount;
                            timeLineArray[j].buy3 = timeLineArray[j - 1].buy3;
                            timeLineArray[j].buy3Amount = timeLineArray[j - 1].buy3Amount;
                            timeLineArray[j].buy4 = timeLineArray[j - 1].buy4;
                            timeLineArray[j].buy4Amount = timeLineArray[j - 1].buy4Amount;
                            timeLineArray[j].buy5 = timeLineArray[j - 1].buy5;
                            timeLineArray[j].buy5Amount = timeLineArray[j - 1].buy5Amount;
                            timeLineArray[j].sell1 = timeLineArray[j - 1].sell1;
                            timeLineArray[j].sell1Amount = timeLineArray[j - 1].sell1Amount;
                            timeLineArray[j].sell2 = timeLineArray[j - 1].sell2;
                            timeLineArray[j].sell2Amount = timeLineArray[j - 1].sell2Amount;
                            timeLineArray[j].sell3 = timeLineArray[j - 1].sell3;
                            timeLineArray[j].sell3Amount = timeLineArray[j - 1].sell3Amount;
                            timeLineArray[j].sell4 = timeLineArray[j - 1].sell4;
                            timeLineArray[j].sell4Amount = timeLineArray[j - 1].sell4Amount;
                            timeLineArray[j].sell5 = timeLineArray[j - 1].sell5;
                            timeLineArray[j].sell5Amount = timeLineArray[j - 1].sell5Amount;

                        }
                        j++;
                    }
                    timeLineArray[j] = new TimeLine();
                    timeLineArray[j].gid = gid;
                    timeLineArray[j].name = dtNormal.Rows[i]["name"].ToString().Trim();
                    timeLineArray[j].trade = double.Parse(dtNormal.Rows[i]["nowPri"].ToString().Trim());
                    timeLineArray[j].buy = double.Parse(dtNormal.Rows[i]["competitivePri"].ToString().Trim());
                    timeLineArray[j].sell = double.Parse(dtNormal.Rows[i]["reservePri"].ToString().Trim());
                    timeLineArray[j].settle = double.Parse(dtNormal.Rows[i]["yestodEndPri"].ToString().Trim());
                    timeLineArray[j].open = double.Parse(dtNormal.Rows[i]["todayStartPri"].ToString().Trim());
                    timeLineArray[j].volume = int.Parse(dtNormal.Rows[i]["traNumber"].ToString().Trim());
                    timeLineArray[j].amount = double.Parse(dtNormal.Rows[i]["traAmount"].ToString().Trim());
                    timeLineArray[j].buy1 = int.Parse(dtNormal.Rows[i]["buyOne"].ToString());
                    timeLineArray[j].buy1Amount = double.Parse(dtNormal.Rows[i]["buyOnePri"].ToString());
                    timeLineArray[j].buy2 = int.Parse(dtNormal.Rows[i]["buyTwo"].ToString());
                    timeLineArray[j].buy2Amount = double.Parse(dtNormal.Rows[i]["buyTwoPri"].ToString());
                    timeLineArray[j].buy3 = int.Parse(dtNormal.Rows[i]["buyThree"].ToString());
                    timeLineArray[j].buy3Amount = double.Parse(dtNormal.Rows[i]["buyThreePri"].ToString());
                    timeLineArray[j].buy4 = int.Parse(dtNormal.Rows[i]["buyFour"].ToString());
                    timeLineArray[j].buy4Amount = double.Parse(dtNormal.Rows[i]["buyFourPri"].ToString());
                    timeLineArray[j].buy5 = int.Parse(dtNormal.Rows[i]["buyFive"].ToString());
                    timeLineArray[j].buy5Amount = double.Parse(dtNormal.Rows[i]["buyFivePri"].ToString());
                    timeLineArray[j].sell1 = int.Parse(dtNormal.Rows[i]["sellOne"].ToString());
                    timeLineArray[j].sell1Amount = double.Parse(dtNormal.Rows[i]["sellOnePri"].ToString());
                    timeLineArray[j].sell2 = int.Parse(dtNormal.Rows[i]["sellTwo"].ToString());
                    timeLineArray[j].sell2Amount = double.Parse(dtNormal.Rows[i]["sellTwoPri"].ToString());
                    timeLineArray[j].sell3 = int.Parse(dtNormal.Rows[i]["sellThree"].ToString());
                    timeLineArray[j].sell3Amount = double.Parse(dtNormal.Rows[i]["sellThreePri"].ToString());
                    timeLineArray[j].sell4 = int.Parse(dtNormal.Rows[i]["sellFour"].ToString());
                    timeLineArray[j].sell4Amount = double.Parse(dtNormal.Rows[i]["sellFourPri"].ToString());
                    timeLineArray[j].sell5 = int.Parse(dtNormal.Rows[i]["sellFive"].ToString());
                    timeLineArray[j].sell5Amount = double.Parse(dtNormal.Rows[i]["sellFivePri"].ToString());
                    timeLineArray[j].tickTime = DateTime.Parse(dtNormal.Rows[i]["date"].ToString() + " " + dtNormal.Rows[i]["time"].ToString());
                    if (j > 0)
                    {
                        timeLineArray[j].volumeIncrease = timeLineArray[j].volume - timeLineArray[j - 1].volume;
                        timeLineArray[j].amountIncrease = timeLineArray[j].amount - timeLineArray[j - 1].amount;
                    }
                    j++;
                }
                else
                {
                    if (currentDateTimeNormal < currentDateTimeLine )
                    {
                        if (currentDateTimeNormal != DateTime.Parse("2000-1-1"))
                        {
                            timeLineArray[j] = new TimeLine();
                            timeLineArray[j].gid = gid;
                            timeLineArray[j].name = dtNormal.Rows[i]["name"].ToString().Trim();
                            timeLineArray[j].trade = double.Parse(dtNormal.Rows[i]["nowPri"].ToString().Trim());
                            timeLineArray[j].buy = double.Parse(dtNormal.Rows[i]["competitivePri"].ToString().Trim());
                            timeLineArray[j].sell = double.Parse(dtNormal.Rows[i]["reservePri"].ToString().Trim());
                            timeLineArray[j].settle = double.Parse(dtNormal.Rows[i]["yestodEndPri"].ToString().Trim());
                            timeLineArray[j].open = double.Parse(dtNormal.Rows[i]["todayStartPri"].ToString().Trim());
                            timeLineArray[j].volume = int.Parse(dtTimeline.Rows[i]["traNumber"].ToString().Trim());
                            timeLineArray[j].amount = double.Parse(dtTimeline.Rows[i]["traAmount"].ToString().Trim());
                            timeLineArray[j].buy1 = int.Parse(dtNormal.Rows[i]["buyOne"].ToString());
                            timeLineArray[j].buy1Amount = double.Parse(dtNormal.Rows[i]["buyOnePri"].ToString());
                            timeLineArray[j].buy2 = int.Parse(dtNormal.Rows[i]["buyTwo"].ToString());
                            timeLineArray[j].buy2Amount = double.Parse(dtNormal.Rows[i]["buyTwoPri"].ToString());
                            timeLineArray[j].buy3 = int.Parse(dtNormal.Rows[i]["buyThree"].ToString());
                            timeLineArray[j].buy3Amount = double.Parse(dtNormal.Rows[i]["buyThreePri"].ToString());
                            timeLineArray[j].buy4 = int.Parse(dtNormal.Rows[i]["buyFour"].ToString());
                            timeLineArray[j].buy4Amount = double.Parse(dtNormal.Rows[i]["buyFourPri"].ToString());
                            timeLineArray[j].buy5 = int.Parse(dtNormal.Rows[i]["buyFive"].ToString());
                            timeLineArray[j].buy5Amount = double.Parse(dtNormal.Rows[i]["buyFivePri"].ToString());
                            timeLineArray[j].sell1 = int.Parse(dtNormal.Rows[i]["sellOne"].ToString());
                            timeLineArray[j].sell1Amount = double.Parse(dtNormal.Rows[i]["sellOnePri"].ToString());
                            timeLineArray[j].sell2 = int.Parse(dtNormal.Rows[i]["sellTwo"].ToString());
                            timeLineArray[j].sell2Amount = double.Parse(dtNormal.Rows[i]["sellTwoPri"].ToString());
                            timeLineArray[j].sell3 = int.Parse(dtNormal.Rows[i]["sellThree"].ToString());
                            timeLineArray[j].sell3Amount = double.Parse(dtNormal.Rows[i]["sellThreePri"].ToString());
                            timeLineArray[j].sell4 = int.Parse(dtNormal.Rows[i]["sellFour"].ToString());
                            timeLineArray[j].sell4Amount = double.Parse(dtNormal.Rows[i]["sellFourPri"].ToString());
                            timeLineArray[j].sell5 = int.Parse(dtNormal.Rows[i]["sellFive"].ToString());
                            timeLineArray[j].sell5Amount = double.Parse(dtNormal.Rows[i]["sellFivePri"].ToString());
                            timeLineArray[j].tickTime = DateTime.Parse(dtNormal.Rows[i]["date"].ToString() + " " + dtNormal.Rows[i]["time"].ToString());
                            if (j > 0)
                            {
                                timeLineArray[j].volumeIncrease = timeLineArray[j].volume - timeLineArray[j - 1].volume;
                                timeLineArray[j].amountIncrease = timeLineArray[j].amount - timeLineArray[j - 1].amount;
                            }
                            j++;
                        }
                    }
                    timeLineArray[j] = new TimeLine();
                    timeLineArray[j].gid = gid;
                    timeLineArray[j].name = dtTimeline.Rows[i]["name"].ToString().Trim();
                    timeLineArray[j].trade = double.Parse(dtTimeline.Rows[i]["trade"].ToString().Trim());
                    timeLineArray[j].buy = double.Parse(dtTimeline.Rows[i]["buy"].ToString().Trim());
                    timeLineArray[j].sell = double.Parse(dtTimeline.Rows[i]["sell"].ToString().Trim());
                    timeLineArray[j].settle = double.Parse(dtTimeline.Rows[i]["settlement"].ToString().Trim());
                    timeLineArray[j].open = double.Parse(dtTimeline.Rows[i]["open"].ToString().Trim());
                    timeLineArray[j].volume = int.Parse(dtTimeline.Rows[i]["volume"].ToString().Trim());
                    timeLineArray[j].amount = double.Parse(dtTimeline.Rows[i]["amount"].ToString().Trim());
                    timeLineArray[j].tickTime = DateTime.Parse(dtTimeline.Rows[i]["ticktime"].ToString());
                    if (j > 0)
                    {
                        timeLineArray[j].volumeIncrease = timeLineArray[j].volume - timeLineArray[j - 1].volume;
                        timeLineArray[j].amountIncrease = timeLineArray[j].amount - timeLineArray[j - 1].amount;
                        timeLineArray[j].buy1 = timeLineArray[j - 1].buy1;
                        timeLineArray[j].buy1Amount = timeLineArray[j - 1].buy1Amount;
                        timeLineArray[j].buy2 = timeLineArray[j - 1].buy2;
                        timeLineArray[j].buy2Amount = timeLineArray[j - 1].buy2Amount;
                        timeLineArray[j].buy3 = timeLineArray[j - 1].buy3;
                        timeLineArray[j].buy3Amount = timeLineArray[j - 1].buy3Amount;
                        timeLineArray[j].buy4 = timeLineArray[j - 1].buy4;
                        timeLineArray[j].buy4Amount = timeLineArray[j - 1].buy4Amount;
                        timeLineArray[j].buy5 = timeLineArray[j - 1].buy5;
                        timeLineArray[j].buy5Amount = timeLineArray[j - 1].buy5Amount;
                        timeLineArray[j].sell1 = timeLineArray[j - 1].sell1;
                        timeLineArray[j].sell1Amount = timeLineArray[j - 1].sell1Amount;
                        timeLineArray[j].sell2 = timeLineArray[j - 1].sell2;
                        timeLineArray[j].sell2Amount = timeLineArray[j - 1].sell2Amount;
                        timeLineArray[j].sell3 = timeLineArray[j - 1].sell3;
                        timeLineArray[j].sell3Amount = timeLineArray[j - 1].sell3Amount;
                        timeLineArray[j].sell4 = timeLineArray[j - 1].sell4;
                        timeLineArray[j].sell4Amount = timeLineArray[j - 1].sell4Amount;
                        timeLineArray[j].sell5 = timeLineArray[j - 1].sell5;
                        timeLineArray[j].sell5Amount = timeLineArray[j - 1].sell5Amount;

                    }
                    j++;
                }
            }
        }
        TimeLine[] timeLineRetArr = new TimeLine[j];
        for (int k = 0; k < j; k++)
        {
            timeLineRetArr[k] = timeLineArray[k];
        }
        return timeLineRetArr;
    }

    public static KLine[] AssembKLine(string type, KLine[] kArr)
    {
        int span = 15;
        switch (type)
        {
            case "15min":
                span = 15;
                break;
            case "30min":
                span = 30;
                break;
            case "1hr":
                span = 60;
                break;
            case "day":
                span = 240;
                break;
            default:
                break;
        }
        int kLineNum = (kArr.Length * span / span == kArr.Length) ? kArr.Length / span : 1 + kArr.Length / span;
        KLine[] newKArr = new KLine[kLineNum];
        for (int i = 0; i < kLineNum; i++)
        {
            newKArr[i] = new KLine();
            newKArr[i].gid = kArr[0].gid;
            newKArr[i].type = kArr[0].type;
            newKArr[i].startDateTime = DateTime.MinValue;
            newKArr[i].startPrice = 0;
            newKArr[i].endPrice = 0;
            newKArr[i].highestPrice = double.MinValue;
            newKArr[i].lowestPrice = double.MaxValue;
            newKArr[i].volume = 0;
            newKArr[i].amount = 0;
            for (int j = 0; j < span && (i * span + j) < kArr.Length; j++)
            {
                if (j == 0)
                {
                    newKArr[i].startDateTime = kArr[i * span + j].startDateTime;
                    newKArr[i].startPrice = kArr[i * span + j].startPrice;
                    
                }
                newKArr[i].highestPrice = Math.Max(newKArr[i].highestPrice, kArr[i * span + j].highestPrice);
                newKArr[i].lowestPrice = Math.Min(newKArr[i].lowestPrice, kArr[i * span + j].lowestPrice);
                newKArr[i].volume = newKArr[i].volume + kArr[i * span + j].volume;
                newKArr[i].amount = newKArr[i].amount + kArr[i * span + j].amount;
                if (j == span - 1 || i * span + j == kArr.Length - 1)
                {
                    newKArr[i].endPrice = kArr[i * span + j].endPrice;
                }
            }
        }
        return newKArr;
    }


    public static KLine[] Create1MinKLine(string gid, DateTime date)
    {
        if (!Util.IsTransacDay(DateTime.Parse(date.ToShortDateString())))
        {
            return new KLine[0];
        }
        DataTable dtTimeLine = DBHelper.GetDataTable(" select * from sh600031_timeline where ticktime > '"
            + date.ToShortDateString() + "' and ticktime < '" + date.AddDays(1).ToShortDateString() + "' order by ticktime ");
        DataTable dtNormal = DBHelper.GetDataTable(" select * from sh600031 where convert(datetime,[date]) = '" + date.ToShortDateString() + "' order by [time] ");

        DataRow[] drBeforeOpenArr = dtTimeLine.Select(" open = 0 ");
        foreach (DataRow drBeforeOpen in drBeforeOpenArr)
        {
            dtTimeLine.Rows.Remove(drBeforeOpen);
        }
        drBeforeOpenArr = dtNormal.Select(" todayStartPri = '0.000' ");
        foreach (DataRow drBeforeOpen in drBeforeOpenArr)
        {
            dtNormal.Rows.Remove(drBeforeOpen);
        }
        KLine[] kLineArr = new KLine[4 * 60];
        int j = 0;
        for (DateTime i = DateTime.Parse(date.ToShortDateString() + " 9:30"); 
            (i < DateTime.Parse(date.ToShortDateString() + " 15:00") && DateTime.Parse(i.ToShortDateString()) < DateTime.Parse(DateTime.Now.ToShortDateString()))
            || (DateTime.Parse(i.ToShortDateString()) == DateTime.Parse(DateTime.Now.ToShortDateString()) && i < DateTime.Parse(date.ToShortDateString() + " 15:00") && i < DateTime.Now) ; 
            i = i.AddMinutes(1))
        {
            if (i >= DateTime.Parse(i.ToShortDateString() + " 11:30") && i < DateTime.Parse(i.ToShortDateString() + " 13:00"))
                continue;
            kLineArr[j] = new KLine();
            kLineArr[j].gid = gid;
            kLineArr[j].type = "1min";
            kLineArr[j].startDateTime = i;
            DataRow[] drTimelineArr;
            DataRow[] drNormalArr;
            if (j == 0)
            {
                drTimelineArr = dtTimeLine.Select(" ticktime < '" + i.AddMinutes(1).ToString() + "'");
                drNormalArr = dtNormal.Select(" time < '" + i.AddMinutes(1).Hour.ToString().PadLeft(2, '0') 
                    + ":" + i.AddMinutes(1).Minute.ToString().PadLeft(2, '0') 
                    + ":" + i.AddMinutes(1).Second.ToString().PadLeft(2, '0') + "' ");
            }
            else
            {
                if ((i.Hour == 11 && i.Minute == 29) || (i.Hour == 14 && i.Minute == 59))
                {
                    drTimelineArr = dtTimeLine.Select(" ticktime >= '" + i.ToString() + "' and  ticktime < '" + i.AddMinutes(1).ToString() + "'");
                    drNormalArr = dtNormal.Select(" time >= '" + i.Hour.ToString().PadLeft(2, '0')
                        + ":" + i.Minute.ToString().PadLeft(2, '0')
                        + ":" + i.Second.ToString().PadLeft(2, '0') + "' and time <= '" + i.AddMinutes(1).Hour.ToString().PadLeft(2, '0')
                        + ":" + i.AddMinutes(1).Minute.ToString().PadLeft(2, '0')
                        + ":" + i.AddMinutes(1).Second.ToString().PadLeft(2, '0') + "' ");
                }
                else
                {
                    drTimelineArr = dtTimeLine.Select(" ticktime >= '" + i.ToString() + "' and  ticktime < '" + i.AddMinutes(1).ToString() + "'");
                    drNormalArr = dtNormal.Select(" time >= '" + i.Hour.ToString().PadLeft(2, '0')
                        + ":" + i.Minute.ToString().PadLeft(2, '0')
                        + ":" + i.Second.ToString().PadLeft(2, '0') + "' and time < '" + i.AddMinutes(1).Hour.ToString().PadLeft(2, '0')
                        + ":" + i.AddMinutes(1).Minute.ToString().PadLeft(2, '0')
                        + ":" + i.AddMinutes(1).Second.ToString().PadLeft(2, '0') + "' ");
                }
            }
            DataTable dtCurrentMin = new DataTable();
            dtCurrentMin.Columns.Add("price", Type.GetType("System.Double"));
            dtCurrentMin.Columns.Add("volume", Type.GetType("System.Int32"));
            dtCurrentMin.Columns.Add("amount", Type.GetType("System.Double"));
            dtCurrentMin.Columns.Add("ticktime", Type.GetType("System.DateTime"));
            foreach (DataRow dr in drTimelineArr)
            {
                DataRow drCurrentMin = dtCurrentMin.NewRow();
                drCurrentMin["price"] = double.Parse(dr["trade"].ToString());
                drCurrentMin["volume"] = int.Parse(dr["volume"].ToString());
                drCurrentMin["amount"] = double.Parse(dr["amount"].ToString());
                drCurrentMin["ticktime"] = DateTime.Parse(dr["ticktime"].ToString());
                dtCurrentMin.Rows.Add(drCurrentMin);
            }

            foreach (DataRow dr in drNormalArr)
            {
                DataRow drCurrentMin = dtCurrentMin.NewRow();
                drCurrentMin["price"] = double.Parse(dr["nowPri"].ToString());
                drCurrentMin["volume"] = int.Parse(dr["traNumber"].ToString());
                drCurrentMin["amount"] = double.Parse(dr["traAmount"].ToString());
                drCurrentMin["ticktime"] = DateTime.Parse(dr["date"].ToString() + " " + dr["time"].ToString());
                dtCurrentMin.Rows.Add(drCurrentMin);
            }

            DataRow[] drCurrentMinArr = dtCurrentMin.Select("", " ticktime ");
            if (drCurrentMinArr.Length > 0)
            {
                kLineArr[j].startPrice = double.Parse(drCurrentMinArr[0]["price"].ToString());
                kLineArr[j].endPrice = double.Parse(drCurrentMinArr[drCurrentMinArr.Length - 1]["price"].ToString());
                double maxPrice = 0;
                double minPrice = double.MaxValue;
                foreach (DataRow drMaxMin in drCurrentMinArr)
                {
                    maxPrice = Math.Max(maxPrice, double.Parse(drMaxMin["price"].ToString()));
                    minPrice = Math.Min(minPrice, double.Parse(drMaxMin["price"].ToString()));
                }
                kLineArr[j].highestPrice = maxPrice;
                kLineArr[j].lowestPrice = minPrice;
                if (j == 0)
                {
                    kLineArr[j].amount = double.Parse(drCurrentMinArr[drCurrentMinArr.Length - 1]["amount"].ToString());
                    kLineArr[j].volume = int.Parse(drCurrentMinArr[drCurrentMinArr.Length - 1]["volume"].ToString());
                }
                else
                {
                    kLineArr[j].amount = double.Parse(drCurrentMinArr[drCurrentMinArr.Length - 1]["amount"].ToString())
                        - kLineArr[j - 1].amount;
                    kLineArr[j].volume = int.Parse(drCurrentMinArr[drCurrentMinArr.Length - 1]["volume"].ToString())
                        - kLineArr[j - 1].volume;
                }
            }
            else
            {
                kLineArr[j].startPrice = kLineArr[j - 1].endPrice;
                kLineArr[j].endPrice = kLineArr[j].startPrice;
                kLineArr[j].highestPrice = kLineArr[j].startPrice;
                kLineArr[j].lowestPrice = kLineArr[j].startPrice;
                kLineArr[j].volume = 0;
                kLineArr[j].amount = 0;
            }
            j++;
            foreach (DataRow drDel in drTimelineArr)
                dtTimeLine.Rows.Remove(drDel);
            foreach (DataRow drDel in drNormalArr)
                dtNormal.Rows.Remove(drDel); 
        }
        if (j < 240)
        {
            KLine[] kArr = new KLine[j];
            for (int i = 0; i < kArr.Length; i++)
            {
                kArr[i] = kLineArr[i];
            }
            return kArr;
        }
        else
            return kLineArr;
    }


    public static KLine[] CreateKLineArray(string gid, string type, TimeLine[] timeLineArray)
    {
        DateTime startDateTime = timeLineArray[0].tickTime;

        if (startDateTime.Hour < 9 || (startDateTime.Hour == 9 && startDateTime.Minute < 30))
        {
            startDateTime = DateTime.Parse(startDateTime.ToShortDateString() + " 9:30");
        }

        TimeSpan ts = new TimeSpan();
        switch (type)
        {
            case "15min":
                ts = new TimeSpan(0, 15, 0);
                break;
            case "30min":
                ts = new TimeSpan(0, 30, 0);
                break;
            case "1hr":
                ts = new TimeSpan(1, 0, 0);
                break;
            default:
                ts = new TimeSpan(1, 0, 0, 0);
                break;
        }
        ArrayList kLineArr = new ArrayList();
        KLine k = new KLine();
        k.gid = gid.Trim();
        k.type = type;
        for (int i = 0; i < timeLineArray.Length; i++)
        {
            if (!Util.IsTransacDay(timeLineArray[i].tickTime))
            {
                startDateTime = timeLineArray[i].tickTime;
                continue;
            }
            if (timeLineArray[i].tickTime < startDateTime.Add(ts) && timeLineArray[i].tickTime >= startDateTime)
            {
                k.startDateTime = startDateTime;
                if (k.startPrice == 0)
                {
                    //if (type.Trim().Equals("day"))
                    //{
                        if (i > 0 && timeLineArray[i - 1].tickTime.ToShortDateString().Equals(timeLineArray[i].tickTime.ToShortDateString()))
                        {
                            k.startPrice = timeLineArray[i - 1].trade;
                            k.highestPrice = k.startPrice;
                            k.lowestPrice = k.startPrice;
                        }
                        else
                        {
                            k.startPrice = timeLineArray[i].trade;
                            k.highestPrice = k.startPrice;
                            k.lowestPrice = k.startPrice;
                        }
                    //}
                    //else
                    //{
                    //    k.startPrice = timeLineArray[i].trade;
                    //    k.highestPrice = k.startPrice;
                    //    k.lowestPrice = k.startPrice;
                    //}
                }
                    
                k.endPrice = timeLineArray[i].trade;
                k.highestPrice = Math.Max(k.highestPrice, timeLineArray[i].trade);
                k.lowestPrice = Math.Min(k.lowestPrice, timeLineArray[i].trade);
                k.volume = k.volume + timeLineArray[i].volumeIncrease;
                k.amount = k.amount + timeLineArray[i].amountIncrease;

            }
            else
            {
                if (timeLineArray[i].tickTime >= startDateTime.Add(ts))
                {
                    startDateTime = startDateTime.Add(ts);
                    if (!type.Trim().Equals("day") && !Util.IsTransacDay(startDateTime))
                    {
                        if (startDateTime.Hour == 11 || startDateTime.Hour == 12)
                            startDateTime = DateTime.Parse(startDateTime.ToShortDateString() + " 13:00");
                        if (startDateTime.Hour >= 15)
                        {
                            startDateTime = DateTime.Parse(startDateTime.AddDays(1).ToShortDateString() + " 9:30");
                            for (;!Util.IsTransacDay(DateTime.Parse(startDateTime.ToShortDateString()));)
                            {
                                startDateTime = DateTime.Parse(startDateTime.AddDays(1).ToShortDateString() + " 9:30");
                            }

                        }
                    }

                    i--;
                    if (Util.IsTransacDay(k.startDateTime))
                    {
                        k.endPrice = timeLineArray[i].trade;

                        k.highestPrice = Math.Max(k.highestPrice, timeLineArray[i].trade);
                        if (k.lowestPrice > 0)
                        {
                            k.lowestPrice = Math.Min(k.lowestPrice, timeLineArray[i].trade);
                        }
                        else
                        {
                            k.lowestPrice = timeLineArray[i].trade;
                        }
                        k.volume = k.volume + timeLineArray[i].volumeIncrease;
                        k.amount = k.amount + timeLineArray[i].amountIncrease;
                        kLineArr.Add(k);
                    }
                        
                    k = new KLine();
                    k.gid = gid;
                    k.type = type;
                    k.startDateTime = startDateTime;
                }
                continue;
            }
            
        }
        kLineArr.Add(k);
        KLine[] kLineArrRet = new KLine[kLineArr.Count];
        for (int i = 0; i < kLineArr.Count; i++)
        {
            kLineArrRet[i] = (KLine)kLineArr[i];
        }
        return kLineArrRet;
    }

    public static bool IsTimeLineItemArrayContinues(TimeLineItem[] timeLineItemArray)
    {
        return true;
    }


}

public struct TimeLineItem
{
    public DataRow _fileds;
}