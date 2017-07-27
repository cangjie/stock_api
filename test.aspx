<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">

    public static Queue queue = new Queue();

    protected void Page_Load(object sender, EventArgs e)
    {
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
