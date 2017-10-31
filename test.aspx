﻿ <%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {

        string[] gidArr = Util.GetAllGids();
        foreach (string gid in gidArr)
        {
            Stock s = new Stock(gid);
            s.LoadKLineDay();
            if (s.kLineDay.Length < 9)
                continue;
            StockWatcher.SearchFolks(s.gid.Trim(), "day", s.kLineDay, s.kLineDay.Length - 1);
            int count = KLine.ComputeDeMarkValue(s.kLineDay, s.kLineDay.Length - 1);
            if (count != 0)
            {
                try
                {
                    DBHelper.InsertData("alert_demark", new string[,] {
                                {"gid", "varchar", s.gid.Trim() },
                                {"alert_time", "datetime", s.kLineDay[s.kLineDay.Length - 1].endDateTime.ToString() },
                                {"alert_type", "varchar", "day" },
                                {"value", "int", count.ToString() },
                                {"price", "float", s.kLineDay[s.kLineDay.Length - 1].endPrice.ToString() }
                            });
                }
                catch(Exception err)
                {
                    Console.WriteLine(err.ToString());
                }
            }

            /*
            for (int i = s.kLineDay.Length - 1; i >= 15; i--)
            {
                int count = KLine.ComputeDeMarkValue(s.kLineDay, i);
                if (count != 0)
                {
                    try
                    {
                        DBHelper.InsertData("alert_demark", new string[,] {
                            {"gid", "varchar", s.gid.Trim() },
                            {"alert_time", "datetime", s.kLineDay[i].endDateTime.ToString() },
                            {"alert_type", "varchar", "day" },
                            {"value", "int", count.ToString() },
                            {"price", "float", s.kLineDay[i].endPrice.ToString() }
                        });
                    }
                    catch(Exception err)
                    {
                        Console.WriteLine(err.ToString());
                    }
                }
                */
            /*
                            string count = KLine.ComputeDeMarkCount(s.kLineDay, i).Trim();
                            if (count.IndexOf("(") < 0 && !count.Equals("++") && !count.Equals("--"))
                            {
                                count = count.Replace("+", "");
                                try
                                {
                                    DBHelper.InsertData("alert_demark", new string[,] {
                                        {"gid", "varchar", s.gid.Trim() },
                                        {"alert_time", "datetime", s.kLineDay[i].endDateTime.ToString() },
                                        {"alert_type", "varchar", "day" },
                                        {"value", "int", int.Parse(count).ToString() },
                                        {"price", "float", s.kLineDay[i].endPrice.ToString() }
                                    });
                                }
                                catch(Exception err)
                                {
                                    Console.WriteLine(err.ToString());
                                }
                            }
            */
        }

    }


    /*
    Stock stock = new Stock("sh600138");
    stock.LoadKLineDay();
    KLine k = stock.kLineDay[stock.kLineDay.Length - 1];
    */
    //Stock.GetVolumeAndAmount("sh600138", DateTime.Parse("2017-10-20"));



    //Response.Write(k.volume);

    //StockWatcher.WatchKDJMACD();

    /*
            string[] gidArr = Util.GetAllGids();
            for (int i = 0; i < gidArr.Length; i++)
            {
                Stock stock = new Stock(gidArr[i].Trim());
                stock.LoadKLineDay();
                KLine.ComputeRSV(stock.kLineDay);
                KLine.ComputeKDJ(stock.kLineDay);
                KLine.ComputeMACD(stock.kLineDay);
                KLine.SearchMACDAlert(stock.kLineDay, stock.kLineDay.Length - 1);
                KLine.SearchKDJAlert(stock.kLineDay, stock.kLineDay.Length - 1);
            }
            */

</script>
