<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime currentDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", DateTime.Now.ToShortDateString()));
        currentDate = Util.GetLastTransactDate(currentDate, 10);
        DataTable dt = DBHelper.GetDataTable(" select distinct gid from limit_up where alert_date = '" + currentDate.ToShortDateString() + "' ");
        string retGidArr = "";
        foreach (DataRow dr in dt.Rows)
        {
            retGidArr = retGidArr + ", \"" + dr[0].ToString().Trim() + "\"";
        }
        string ret = "{\"gids\":[" + retGidArr.Remove(0, 1) + "]}";
        Response.Write(ret);
    }
</script>