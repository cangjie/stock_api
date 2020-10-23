using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Collections;

/// <summary>
/// LimitUpVolumeReduce 的摘要说明
/// </summary>
public class LimitUpVolumeReduce
{
    public ArrayList gidArr = new ArrayList();
    public LimitUpVolumeReduce()
    {
        //
        // TODO: 在此处添加构造函数逻辑
        //
    }

    public DataTable GetAllSignalList(DateTime start, DateTime end)
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.DateTime"));
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("信号");
        dt.Columns.Add("缩量");
        dt.Columns.Add("买入");
        dt.Columns.Add("1日", Type.GetType("System.Double"));
        dt.Columns.Add("2日", Type.GetType("System.Double"));
        dt.Columns.Add("3日", Type.GetType("System.Double"));
        dt.Columns.Add("4日", Type.GetType("System.Double"));
        dt.Columns.Add("5日", Type.GetType("System.Double"));
        dt.Columns.Add("总计", Type.GetType("System.Double"));

        DataTable dtOri = DBHelper.GetDataTable(" select  alert_date, gid from limit_up_volume_reduce "
            + " where alert_date >= '" + Util.GetLastTransactDate(start, 5).ToShortDateString() + "' and alert_date <= '" 
            + end.ToShortDateString() + "'  order by alert_date desc ");

        foreach (DataRow drOri in dtOri.Rows)
        {
            string sigal = "";
            try
            {
                Stock s = GetStock(drOri["gid"].ToString().Trim());
                int currentIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
                if (currentIndex < 2)
                {
                    continue;
                }

                if (currentIndex + 1 >= s.kLineDay.Length)
                {
                    continue;
                }

                if (s.kLineDay[currentIndex].volume > s.kLineDay[currentIndex - 1].volume)
                {
                    continue;
                }

                double high = Math.Max(s.kLineDay[currentIndex].highestPrice, s.kLineDay[currentIndex - 1].highestPrice);
                double low = Math.Min(s.kLineDay[currentIndex].lowestPrice, s.kLineDay[currentIndex - 1].lowestPrice);
                double f3 = high - (high - low) * 0.382;
                double f5 = high - (high - low) * 0.618;
                int buyIndex = currentIndex;

                if (s.kLineDay[currentIndex].lowestPrice < f5 && s.kLineDay[currentIndex].endPrice > f5 && !s.IsLimitUp(currentIndex - 2))
                {
                    sigal = "F5";
                }
                else if (s.kLineDay[currentIndex].lowestPrice < f3 && s.kLineDay[currentIndex].endPrice > f3 && !s.IsLimitUp(currentIndex - 2))
                {
                    sigal = "F3";
                }
                double current3Line = s.GetAverageSettlePrice(currentIndex, 3, 3);
                double next3Line = s.GetAverageSettlePrice(currentIndex + 1, 3, 3);
                if (s.kLineDay[currentIndex].lowestPrice < current3Line && s.kLineDay[currentIndex].endPrice > current3Line)
                {
                    sigal = sigal + "3⃣️";
                }
                if (s.kLineDay[currentIndex + 1].lowestPrice < next3Line && s.kLineDay[currentIndex + 1].endPrice > next3Line)
                {
                    buyIndex = currentIndex + 1;
                    if (sigal.IndexOf("3⃣️") < 0)
                    {
                        sigal = sigal + "3⃣️";
                    }
                }
                if (s.kLineDay[currentIndex + 1].endPrice > high )
                {
                    buyIndex = currentIndex + 1;
                    sigal = sigal + "<a title=\"新高\" >📈</a>";
                }
                if (s.kLineDay[currentIndex].startPrice > s.kLineDay[currentIndex - 1].endPrice
                    && s.kLineDay[currentIndex].endPrice > s.kLineDay[currentIndex - 1].endPrice)
                {
                    sigal = sigal + "🐴";
                }
                if (s.IsLimitUp(currentIndex - 2))
                {
                    sigal = sigal + "<a title=\"连板\" >🚩</a>";
                }
                if (s.kLineDay[buyIndex].startDateTime.Date >= start && s.kLineDay[buyIndex].startDateTime.Date <= end  && !sigal.Trim().Equals("") 
                    && dt.Select(" 日期 = '" + s.kLineDay[currentIndex + 2].startDateTime.Date.ToShortDateString() 
                    + "' and 代码 = '" + s.gid.Trim() + "' ").Length == 0 && !s.IsLimitUp(buyIndex) )
                {
                    DataRow dr = dt.NewRow();
                    dr["日期"] = s.kLineDay[buyIndex].startDateTime.Date;
                    dr["代码"] = s.gid.Trim();
                    dr["名称"] = s.Name.Trim();
                    dr["信号"] = sigal.Trim();
                    dr["缩量"] = Math.Round(100 * s.kLineDay[currentIndex].volume / s.kLineDay[currentIndex - 1].volume, 2).ToString() + "%";
                    double buyPrice = s.kLineDay[buyIndex].endPrice;
                    dr["买入"] = Math.Round(buyPrice, 2).ToString();

                    double maxPrice = 0;
                    for (int i = 1; i <= 5; i++)
                    {
                        if (buyIndex + i < s.kLineDay.Length)
                        {
                            maxPrice = Math.Max(maxPrice, s.kLineDay[buyIndex + i].highestPrice);
                            double rate = (s.kLineDay[buyIndex + i].highestPrice - buyPrice) / buyPrice;
                            dr[i.ToString() + "日"] = rate;
                        }
                        else
                        {
                            dr[i.ToString() + "日"] = double.MinValue;
                        }
                    }
                    double allRate = (maxPrice - buyPrice) / buyPrice;
                    if (buyIndex + 5 < s.kLineDay.Length)
                    {
                        dr["总计"] = allRate;
                    }
                    else
                    {
                        dr["总计"] = double.MinValue;
                    }
                    
                    dt.Rows.Add(dr);
                }
            }
            catch
            {

            }
        }



        return dt;
    }

    public Stock GetStock(string gid)
    {
        Stock s = new Stock();
        bool found = false;
        foreach (object o in gidArr)
        {
            if (((Stock)o).gid.Trim().Equals(gid))
            {
                found = true;
                s = (Stock)o;
                break;
            }
        }
        if (!found)
        {
            s = new Stock(gid);
            s.LoadKLineDay(Util.rc);
            gidArr.Add(s);
        }
        return s;
    }

}