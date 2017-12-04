 <%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        Stock s = new Stock("sh600031");
        s.LoadKLineDay();
        StockWatcher.WriteKLineToFileCache(s.gid, s.kLineDay);

        //string[] gidArr = Util.GetAllGids();
        /*
        string[] gidArrNew = new string[3000];
        for (int i = 0; i < gidArrNew.Length; i++)
        {
            gidArrNew[i] = gidArr[i];
        }
        */
        //CachedKLine[] clArr = Stock.GetKLineSetArray(gidArr, "day", 500);
    }

</script>
