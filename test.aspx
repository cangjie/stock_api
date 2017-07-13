<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">

    public static Queue queue = new Queue();

    protected void Page_Load(object sender, EventArgs e)
    {

        StockWatcher.WatchEachStock();
        Response.End();
        DateTime i = DateTime.Parse("2017-7-13"); 
        string gid = "sh600010";
        Stock s = new Stock(gid);
        s.kArr = KLine.GetLocalKLine(gid, "day");
        int idx = s.GetItemIndex(DateTime.Parse(i.ToShortDateString() + " 9:30"));
        Response.Write(idx);
    }


</script>
