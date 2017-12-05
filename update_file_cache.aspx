<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<!DOCTYPE html>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        ThreadStart ts = new ThreadStart(StockWatcher.WriteAllKLineToFileCache);
        Thread t = new Thread(ts);
        t.Start();
    }

    
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
    
    </div>
    </form>
</body>
</html>
