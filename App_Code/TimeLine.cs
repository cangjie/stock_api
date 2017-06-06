using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;

/// <summary>
/// Summary description for TimeLine
/// </summary>
public class TimeLine
{

    public TimeLineItem[] timeLineItemArray;

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

    public static TimeLineItem[] GetTimeLineItem(string gid, DateTime start, DateTime end)
    {
        return new TimeLineItem[0];
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