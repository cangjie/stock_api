<%@ Page Language="C#" %>

<!DOCTYPE html>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {

    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        tRefreshUpdatedKLine:<%=StockWatcher.tRefreshUpdatedKLine.ThreadState.ToString() %>
    </div>
    </form>
</body>
</html>
