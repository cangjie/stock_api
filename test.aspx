 <%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        string[] gidArr = Util.GetAllGids();
        /*
        string[] gidArrNew = new string[3000];
        for (int i = 0; i < gidArrNew.Length; i++)
        {
            gidArrNew[i] = gidArr[i];
        }
        */
        CachedKLine[] clArr = Stock.GetKLineSetArray(gidArr, "day", 10);
        Stock[] sArr = new Stock[gidArr.Length];
        for (int i = 0; i < sArr.Length; i++)
        {
            sArr[i] = new Stock(gidArr[i]);
            sArr[i].LoadKLineDay();
        }


    }

</script>
