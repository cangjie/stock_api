<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">

    //public static Queue queue = new Queue();

    protected void Page_Load(object sender, EventArgs e)
    {
        Stock stock = new Stock("sz002698");
        stock.LoadKLineDay();
        KeyValuePair<string, double>[] quotaArr = stock.GetSortedQuota(stock.kLineDay.Length - 1);
        foreach (KeyValuePair<string, double> kvp in quotaArr)
        {
            string aa = "aa";
        }

        /*
        for (DateTime i = DateTime.Parse("2017-8-11"); i >= DateTime.Parse("2017-6-26"); i = i.AddDays(-1))
        {
            Stock.SearchBottomBreak3Line(i);
        }
        */
        /*
        string[] gidArr = Util.GetAllGids();
        for (int i = 0; i < gidArr.Length; i++)
        {
            KLine[] kArr = KLine.GetLocalKLine(gidArr[i], "day");
            
            if (kArr.Length > 2)
            {
                KLine.ComputeMACD(kArr);
                KLine.SearchMACDAlert(kArr, 2);
            }
            
        }*/
    }


</script>
