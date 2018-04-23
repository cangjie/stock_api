 <%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        string[] gidArr = Util.GetAllGids();
        for (int i = 0; i < gidArr.Length; i++)
        {

            try
            {
                if (gidArr[i].Trim().Equals("sh600876"))
                {
                    string aa = "";
                }
                else
                {
                    continue;
                }
                Stock stock = new Stock(gidArr[i]);
                stock.LoadKLineDay();
                for (DateTime j = DateTime.Parse("2018-4-19"); j >= DateTime.Parse("2018-3-1"); j = j.AddDays(-1))
                {
                    if (Util.IsTransacDay(j))
                    {

                        int currentIndex = stock.GetItemIndex(j);
                        double ma5 = stock.GetAverageSettlePrice(currentIndex, 5, 0);
                        double ma10 = stock.GetAverageSettlePrice(currentIndex, 10, 0);
                        double ma20 = stock.GetAverageSettlePrice(currentIndex, 20, 0);
                        double ma30 = stock.GetAverageSettlePrice(currentIndex, 30, 0);
                        if (ma5 > ma10 && ma10 > ma20 && ma20 > ma30)
                        {
                            DBHelper.InsertData("alert_bull", new string[,] { {"alert_date", "datetime", j.ToShortDateString() },
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
