<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
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
        tKLineRefresher:<%=StockWatcher.tKLineRefresher.ThreadState.ToString() %><br />
        tRefreshUpdatedKLine:<%=StockWatcher.tRefreshUpdatedKLine.ThreadState.ToString() %><br />
        tLoadTodayKLine:<%=StockWatcher.tLoadTodayKLine.ThreadState.ToString() %><br />
        tWatchEachStock:<%=StockWatcher.tWatchEachStock.ThreadState.ToString() %><br />
        tLogQuota:<%=StockWatcher.tLogQuota.ThreadState.ToString() %><br />
    </div>
    </form>
</body>
</html>
