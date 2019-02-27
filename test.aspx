 <%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {




        //StockWatcher.SendAlertMessage("oeC_l1Zn1ineEuGmDl6hgE5ixPCw", "sh600031", "三一重工", 10, "bull");

        Response.Write(Stock.GetCurrentKLineEndDateTime(DateTime.Now, 30).ToString());


        Response.End();

        foreach (object o in StockWatcher.WatchEachStockRunLog)
        {
            Response.Write(o.ToString() + "<br/>");
        }
        Response.End();



        string[] gidArr = Util.GetAllGids();
        for (int i = 0; i < gidArr.Length; i++)
        {

            try
            {

                Stock stock = new Stock(gidArr[i]);
                stock.LoadKLineDay();
                for (DateTime j = DateTime.Parse("2018-4-27"); j >= DateTime.Parse("2018-3-1"); j = j.AddDays(-1))
                {
                    if (Util.IsTransacDay(j))
                    {

                        int currentIndex = stock.GetItemIndex(j);
                        double ma5 = stock.GetAverageSettlePrice(currentIndex, 5, 0);
                        double ma10 = stock.GetAverageSettlePrice(currentIndex, 10, 0);
                        double ma20 = stock.GetAverageSettlePrice(currentIndex, 20, 0);
                        double ma30 = stock.GetAverageSettlePrice(currentIndex, 30, 0);


                        double minMa = Math.Min(ma5, ma10);
                        minMa = Math.Min(minMa, ma20);
                        minMa = Math.Min(minMa, ma30);
                        double maxMa = Math.Max(ma5, ma10);
                        maxMa = Math.Max(maxMa, ma20);
                        maxMa = Math.Max(maxMa, ma30);

                        if (stock.kLineDay[currentIndex].startPrice < minMa && stock.kLineDay[currentIndex].highestPrice > maxMa)
                        {
                            DBHelper.InsertData("alert_top", new string[,] { {"alert_date", "datetime", j.ToShortDateString() },
                                {"gid", "varchar", stock.gid.Trim() } });
                        }
                    }
                }
            }
            catch
            {

            }


        }

    }

</script>
