<%@ Page Language="C#" %>


<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");


    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime currentDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", DateTime.Now.ToShortDateString()));
        foreach (string gid in Util.GetAllGids())
        {
            Stock s = new Stock(gid);
            s.LoadKLineDay(rc);
            KLine.ComputeRSV(s.kLineDay);
            KLine.ComputeKDJ(s.kLineDay);
            KLine.ComputeMACD(s.kLineDay);
            if (s.kLineDay.Length <= 30)
            {
                continue;
            }
            if (currentDate == DateTime.Parse("1999-1-1"))
            {
                for (int i = 31; i < s.kLineDay.Length; i++)
                {
                    LogOverMa(s, i);
                }
            }
            else
            {
                int currentIndex = s.GetItemIndex(currentDate);
                if (currentIndex == -1)
                {
                    continue;
                }
                LogOverMa(s, currentIndex);
            }

        }
    }

    public void LogOverMa(Stock stock, int currentIndex)
    {
        double ma5 = stock.GetAverageSettlePrice(currentIndex, 5, 0);
        double ma10 = stock.GetAverageSettlePrice(currentIndex, 10, 0);
        double ma20 = stock.GetAverageSettlePrice(currentIndex, 20, 0);
        double ma30 = stock.GetAverageSettlePrice(currentIndex, 30, 0);
        double currentPrice = stock.kLineDay[currentIndex].endPrice;
        if (currentPrice > ma5 && currentPrice > ma10 && currentPrice > ma20 && currentPrice > ma30
            && stock.kLineDay[currentIndex - 1].d > stock.kLineDay[currentIndex - 1].k && stock.kLineDay[currentIndex - 1].k > stock.kLineDay[currentIndex - 1].j
            && stock.kLineDay[currentIndex].d < stock.kLineDay[currentIndex].k && stock.kLineDay[currentIndex].k < stock.kLineDay[currentIndex].j)
        {
            try
            {
                DBHelper.InsertData("alert_over_ma", new string[,] { {"alert_date", "datetime", stock.kLineDay[currentIndex].endDateTime.ToShortDateString() },
                                    {"gid", "varchar", stock.gid.Trim() } });
            }
            catch
            {

            }
        }
    }

</script>