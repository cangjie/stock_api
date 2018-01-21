<%@ Page Language="C#" %>

<!DOCTYPE html>

<script runat="server">

    public string postedStr = "";

    protected void Page_Load(object sender, EventArgs e)
    {
        postedStr = (new System.IO.StreamReader(Request.InputStream)).ReadToEnd();
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <%=postedStr %>
    </div>
    </form>
</body>
</html>
