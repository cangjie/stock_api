<%@ Page Language="C#" %>

<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime currentDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", DateTime.Now.ToShortDateString()));
        //currentDate = DateTime.Parse("2019-4-3");
        //if (Util.IsTransacDay(currentDate))
        //    SearchBottom(currentDate);
        
        for (DateTime i = DateTime.Now.Date; i >= DateTime.Parse("2019-4-4"); i = i.AddDays(-1))
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
            if (currentIndex < 2)
            {
                continue;
            }
            if (s.kLineDay[currentIndex - 2].lowestPrice > s.kLineDay[currentIndex - 1].lowestPrice
                && s.kLineDay[currentIndex].lowestPrice > s.kLineDay[currentIndex - 2].lowestPrice
                && s.kLineDay[currentIndex].endPrice > Math.Max(s.kLineDay[currentIndex - 1].highestPrice, s.kLineDay[currentIndex - 2].highestPrice)
                && s.kLineDay[currentIndex - 2].highestPrice > s.kLineDay[currentIndex - 1].highestPrice
                && s.kLineDay[currentIndex].startPrice < s.kLineDay[currentIndex].endPrice
                //&& s.kLineDay[currentIndex - 1].endPrice < KLine.GetAverageSettlePrice(s.kLineDay, currentIndex - 1, 3, 3)
                //&& s.kLineDay[currentIndex - 2].endPrice < KLine.GetAverageSettlePrice(s.kLineDay, currentIndex - 2, 3, 3)
                )
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