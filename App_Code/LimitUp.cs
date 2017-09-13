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
}