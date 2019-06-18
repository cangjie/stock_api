<%@ Page Language="C#" %>
<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        string[] gidArr = Util.GetAllGids();
        string retGidArr = "";
        foreach (string gid in gidArr)
        {
            retGidArr = retGidArr + ", \"" + gid.Trim() + "\"";
        }
        string ret = "{\"gids\":[" + retGidArr.Remove(0, 1) + "]}";
        Response.Write(ret);
    }
</script>