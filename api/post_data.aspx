<%@ Page Language="C#" %>
<script runat="server">

    public string postedStr = "";

    protected void Page_Load(object sender, EventArgs e)
    {
        postedStr = (new System.IO.StreamReader(Request.InputStream)).ReadToEnd();
        Response.Write(postedStr);
    }
</script>