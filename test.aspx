 <%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        string[] gidArr = Util.GetAllGids();
        int i = 0;
        foreach (string gid in gidArr)
        {
            DataTable dt = DBHelper.GetDataTable(" select top 1 * from  " + gid.Trim() + "_timeline where ticktime > '2018-3-20' and ticktime < '2018-3-20 9:40' order by ticktime ");
            if (dt.Rows.Count > 0)
            {
                double low = double.Parse(dt.Rows[0]["low"].ToString());
                double open = double.Parse(dt.Rows[0]["open"].ToString());
                if ((open - low)/open > 0.02)
                {
                    Response.Write(gid + "<br/>");
                }
            }
            i++;
        }
    }

</script>
