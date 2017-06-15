<%@ Page Language="C#" %>
<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        //KLine[] kArr = KLine.GetKLineDayFromSohu("sh600031", DateTime.Parse("2017-5-25"), DateTime.Parse("2017-6-1"));
        Util.RefreshSuggestStockForToday();
        //Util.RefreshSuggestStock(DateTime.Parse("2017-6-14"));
    }
</script>
