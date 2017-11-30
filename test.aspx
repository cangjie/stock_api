 <%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        string[] gidArr = Util.GetAllGids();
        string[] gidArrNew = new string[600];
        for (int i = 0; i < gidArrNew.Length; i++)
        {
            gidArrNew[i] = gidArr[i];
        }
        CachedKLine[] clArr = Stock.GetKLineSetArray(gidArrNew, "day");
        Stock[] sArr = new Stock[gidArrNew.Length];
        for (int i = 0; i < sArr.Length; i++)
        {
            sArr[i] = new Stock(gidArrNew[i]);
            sArr[i].LoadKLineDay();
        }


    }

</script>
