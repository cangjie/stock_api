<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<script runat="server">

    public static Queue queue = new Queue();

    protected void Page_Load(object sender, EventArgs e)
    {
        //KLine[] kArr = KLine.GetKLineDayFromSohu("sh600031", DateTime.Parse("2017-5-25"), DateTime.Parse("2017-6-1"));
        //Util.RefreshSuggestStockForToday();
        //Util.RefreshSuggestStock(DateTime.Parse("2017-6-13"));

        for (DateTime i = DateTime.Parse("2017-5-15"); i >= DateTime.Parse("2017-5-1"); i = i.AddDays(-1))
        {
            if (Util.IsTransacDay(i))
            {
                Util.RefreshSuggestStock(i);
                /*
                queue.Enqueue(i);
            ThreadStart ts = new ThreadStart(RunData);
            Thread t = new Thread(ts);
            t.Start();
                Thread.Sleep(1000);
                */
            }
            
        }
    }

    public void RunData()
    {
        DateTime currentDate = (DateTime)queue.Dequeue();
        Util.RefreshSuggestStock(currentDate);
    }
</script>
