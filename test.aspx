<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">

    public static Queue queue = new Queue();

    protected void Page_Load(object sender, EventArgs e)
    {
        DataTable dt = DBHelper.GetDataTable(" select [name]  from dbo.sysobjects where OBJECTPROPERTY(id, N'IsUserTable') = 1 and name like '%timeline'");
        SqlConnection conn = new SqlConnection(Util.conStr);
        SqlCommand cmd = new SqlCommand();
        conn.Open();
        cmd.Connection = conn;
        foreach (DataRow dr in dt.Rows)
        {
            string gid = dr[0].ToString().Replace("_timeline", "").Trim();
            cmd.CommandText = " drop table " + gid.Trim() + "_k_line ";
            try
            {
                cmd.ExecuteNonQuery();
            }
            catch(Exception err)
            {

            }
            
            KLine.CreateKLineTable(gid);
            for (DateTime i = DateTime.Parse("2017-6-16"); i <= DateTime.Parse("2017-7-6"); i = i.AddDays(1))
            {
                KLine[] kLine1Min = TimeLine.Create1MinKLine(gid, i);
                KLine[] kArr = TimeLine.AssembKLine("day", kLine1Min);
                foreach (KLine k in kArr)
                {

                    k.Save();
                }
                kArr = TimeLine.AssembKLine("1hr", kLine1Min);
                foreach (KLine k in kArr)
                {
                    k.Save();
                }
                kArr = TimeLine.AssembKLine("30min", kLine1Min);
                foreach (KLine k in kArr)
                {
                    k.Save();
                }
                kArr = TimeLine.AssembKLine("15min", kLine1Min);
                foreach (KLine k in kArr)
                {
                    k.Save();
                }
            }
        }
        conn.Close();
        cmd.Dispose();
        conn.Dispose();
        
</script>
