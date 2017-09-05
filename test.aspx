<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">

    //public static Queue queue = new Queue();

    protected void Page_Load(object sender, EventArgs e)
    {
        //Stock stock = new Stock("sz300606");
        //stock.LoadKLineDay();
        //Response.Write("LastTrade:" + stock.LastTrade.ToString() + "<br/>end_price:" + stock.kLineDay[stock.kLineDay.Length - 1].endPrice);
        Util.RefreshTodayKLineMultiThread();
        //KLine.RefreshKLine("sz002726", DateTime.Parse(DateTime.Now.ToShortDateString()));
    }


</script>
