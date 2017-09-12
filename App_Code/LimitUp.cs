using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

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

    public static int SaveLimitUp(string gid, DateTime date, double lastSettlePrice, double openPrice, double limitPrice)
    {
        try
        {
            DBHelper.UpdateData("limit_up",
                new string[,] { { "in_date", "int", "0" } },
                new string[,] { { "gid", "varchar", gid.Trim() }}, Util.conStr);
            return DBHelper.InsertData("limit_up", new string[,] {
                {"gid", "varchar", gid.Trim() },
                {"alert_date", "datetime", date.ToShortDateString() },
                {"last_settle_price", "float", lastSettlePrice.ToString() },
                {"open_price", "float", openPrice.ToString()},
                {"limit_price", "float", limitPrice.ToString() }
            });
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
}