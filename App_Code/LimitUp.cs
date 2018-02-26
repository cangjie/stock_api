using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;
/// <summary>
/// Summary description for LimitUp
/// </summary>
public class LimitUp
{
    public static int inDateDays = 8;

    public LimitUp()
    {
        //
        // TODO: Add constructor logic here
        //
    }



    public static int SaveLimitUp(string gid, DateTime date, double lastSettlePrice, double openPrice, double limitPrice, double volume)
    {
        try
        {
            DBHelper.UpdateData("limit_up",
                new string[,] { { "in_date", "int", "0" } },
                new string[,] { { "gid", "varchar", gid.Trim() }}, Util.conStr);
            int i = DBHelper.UpdateData("limit_up",
                new string[,] { { "in_date", "int", "1" } },
                new string[,] { { "gid", "varchar", gid.Trim() }, { "alert_date", "datetime", date.ToShortDateString() } }, 
                Util.conStr);
            if (i == 0)
            {
                return DBHelper.InsertData("limit_up", new string[,] {
                    {"gid", "varchar", gid.Trim() },
                    {"alert_date", "datetime", date.ToShortDateString() },
                    {"last_settle_price", "float", lastSettlePrice.ToString() },
                    {"open_price", "float", openPrice.ToString()},
                    {"limit_price", "float", limitPrice.ToString() },
                    {"volume", "float", volume.ToString() }
                });
            }
            else
            {
                return i;
            }
        }
        catch(Exception e)
        {
            Console.WriteLine(e.ToString());
            return 0;
        }
    }

    public static int SetLimitUpOutOfDate(string gid, DateTime date)
    {
        try
        {
            return DBHelper.UpdateData("limit_up", 
                new string[,] { { "in_date", "int", "0" } }, 
                new string[,] { { "gid", "varchar", gid.Trim() }, {"alert_date", "datetime", date.ToShortDateString() } }, Util.conStr);
        }
        catch
        {
            return 0;
        }
    }

    public static DataTable GetLimitUpListBeforeADay(DateTime date)
    {
        DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up where alert_date < '" + date.ToShortDateString()
            + "'  and alert_date > '" + date.AddDays(-15).ToShortDateString() + "'  order by alert_date desc ");
        DataTable dt = new DataTable();
        dt.Columns.Add("alert_date", Type.GetType("System.DateTime"));
        dt.Columns.Add("gid", Type.GetType("System.String"));
        for (int i = 0; i < dtOri.Rows.Count; i++)
        {
            Stock s = new Stock(dtOri.Rows[i]["gid"].ToString().Trim());
            s.LoadKLineDay();
            int currentIndex = s.GetItemIndex(DateTime.Parse(date.ToShortDateString()));
            int alertIndex = s.GetItemIndex(DateTime.Parse(dtOri.Rows[i]["alert_date"].ToString()));
            if (currentIndex - alertIndex <= LimitUp.inDateDays)
            {
                DataRow[] drArr = dt.Select(" gid = '" + s.gid + "' ");
                if (drArr.Length == 0)
                {
                    DataRow dr = dt.NewRow();
                    dr["alert_date"] = dtOri.Rows[i]["alert_date"];
                    dr["gid"] = dtOri.Rows[i]["gid"];
                    dt.Rows.Add(dr);
                }
            }
        }
        dtOri.Dispose();
        return dt;
    }

    public static void SearchCrossStar(Stock stock, DateTime limitUpDate)
    {
        
        if (DateTime.Parse(limitUpDate.AddDays(1).ToShortDateString()) == DateTime.Parse(DateTime.Now.ToShortDateString()))
        {
            if (DateTime.Now <= DateTime.Parse(DateTime.Now.ToShortDateString() + " 14:40"))
            {
                return;
            }
        }
        int kLineLength = stock.kLineDay.Length - 1;
        if (stock.kLineDay[kLineLength].endDateTime.AddMinutes(-20) < DateTime.Now 
            && stock.kLineDay[kLineLength].endDateTime.ToShortDateString().Equals(DateTime.Now.ToShortDateString()))
        {
            kLineLength++;
        }

        int limitUpIndex = stock.GetItemIndex(limitUpDate);
        
        for (int i = limitUpIndex + 1; i < kLineLength && i <= limitUpIndex + inDateDays; i++)
        {
            double startPrice = stock.kLineDay[i].startPrice;
            double endPrice = stock.kLineDay[i].endPrice;
            double volume = stock.kLineDay[i].volume;
            double maxVolume = GetEffectMaxLimitUpVolumeBeforeACertainDate(stock, DateTime.Parse(stock.kLineDay[i].startDateTime.ToShortDateString()));
            if (Math.Abs(endPrice - startPrice) / startPrice < 0.015  && volume / maxVolume < 0.5)
            {
                try
                {
                    DBHelper.InsertData("cross_star_list", new string[,] {
                        {"alert_date", "datetime",  stock.kLineDay[i].startDateTime.ToShortDateString()},
                        {"gid", "varchar", stock.gid },
                        {"limit_up_date", "datetime", limitUpDate.ToShortDateString() },
                        {"open_price", "float", startPrice.ToString() },
                        {"settle_price", "float", endPrice.ToString() },
                        {"highest_price", "float", stock.kLineDay[i].highestPrice.ToString() },
                        {"lowest_price", "float", stock.kLineDay[i].lowestPrice.ToString() },
                        {"volume", "float", volume.ToString() }
                    });
                }
                catch(Exception e)
                {
                    Console.WriteLine(e.ToString());
                }
            }
        }
    }

    public static double GetEffectMaxLimitUpVolumeBeforeACertainDate(Stock stock, DateTime date)
    {
        double maxVolume = 0;
        DataTable dt = DBHelper.GetDataTable(" select * from limit_up where  gid = '" + stock.gid + "'  and alert_date > '" + date.AddMonths(-1) + "' ");
        int certainIndex = stock.GetItemIndex(date);
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            int currentIndex = stock.GetItemIndex(DateTime.Parse(dt.Rows[i]["alert_date"].ToString()));
            if (certainIndex - currentIndex <= inDateDays)
            {
                maxVolume = Math.Max(maxVolume, double.Parse(dt.Rows[i]["volume"].ToString()));
            }
        }
        return maxVolume;
    }
}