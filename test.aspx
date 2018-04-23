 <%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {

        DBHelper.InsertData("alert_bull", new string[,] { {"alert_date", "datetime", DateTime.Now.ToShortDateString() },
                                    {"gid", "varchar", "sh600031"} });
        Response.End();
        Response.Write(Util.GetLastTransactDate(DateTime.Now.Date, 1).ToShortDateString() + "<br/>"
            + Util.GetLastTransactDate(DateTime.Now.Date, 2).ToShortDateString() + "<br/>"
            + Util.GetLastTransactDate(DateTime.Now.Date, 3).ToShortDateString() + "<br/>"
            + Util.GetLastTransactDate(DateTime.Now.Date, 4).ToShortDateString() + "<br/>"
            + Util.GetLastTransactDate(DateTime.Now.Date, 5).ToShortDateString() + "<br/>");
        Response.End();

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
