<%@ Page Language="C#" %>

<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    protected void Page_Load(object sender, EventArgs e)
    {
        for (DateTime i = DateTime.Now.Date; i >= DateTime.Parse("2017-7-1"); i = i.AddDays(-1))
        {
            SearchBottom(i);
        }
    }

    public static void SearchBottom(DateTime currentDate)
    {
        if (!Util.IsTransacDay(currentDate))
        {
            return;
        }
        foreach (string gid in Util.GetAllGids())
        {
            Stock s = new Stock(gid);
            s.LoadKLineDay(rc);
            int currentIndex = s.GetItemIndex(currentDate);
            if (s.kLineDay[currentIndex - 2].lowestPrice > s.kLineDay[currentIndex - 1].lowestPrice
                && s.kLineDay[currentIndex].lowestPrice > s.kLineDay[currentIndex - 2].lowestPrice
                && s.kLineDay[currentIndex].endPrice > Math.Max(s.kLineDay[currentIndex - 1].highestPrice, s.kLineDay[currentIndex - 2].highestPrice)
                && s.kLineDay[currentIndex - 2].highestPrice > s.kLineDay[currentIndex - 1].highestPrice
                && s.kLineDay[currentIndex].startPrice < s.kLineDay[currentIndex].endPrice)
            {
                try
                {
                    DBHelper.InsertData("alert_bottom", new string[,] {
                        {"alert_date", "datetime", currentDate.ToShortDateString() }, {"gid", "varchar", gid },
                        { "type", "varchar", "day"}
                    });
                }
                catch
                {

                }
            }
        }
    }
</script>