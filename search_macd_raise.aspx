<%@ Page Language="C#" %>
<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime currentDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", DateTime.Now.ToShortDateString()));
        currentDate = DateTime.Parse("1999-1-1");
        DateTime startDate = currentDate;
        DateTime endDate = currentDate;
        if (currentDate == DateTime.Parse("1999-1-1"))
        {
            endDate = DateTime.Now;
        }
        foreach (string gid in Util.GetAllGids())
        {
            Stock s = new Stock(gid.Trim());
            s.LoadKLineDay(rc);
            for (DateTime i = startDate; i <= endDate; i = i.AddDays(1))
            {
                if (Util.IsTransacDay(i))
                {
                    try
                    {
                        int currentIndex = s.GetItemIndex(i);
                        if (currentIndex > 0)
                        {
                            double currentSettlePrice = s.kLineDay[currentIndex].endPrice;
                            s.kLineDay[currentIndex].endPrice = s.kLineDay[currentIndex].startPrice;
                            KLine.ComputeMACD(s.kLineDay);
                            if (s.kLineDay[currentIndex - 1].macd < 0 && s.kLineDay[currentIndex].macd > 0
                                && (currentSettlePrice - s.kLineDay[currentIndex - 1].endPrice) / s.kLineDay[currentIndex - 1].endPrice >= 0.06)
                            {
                                //log alert
                                DBHelper.InsertData("alert_macd_jump_empty", new string[,] { {"alert_date", "datetime", i.ToShortDateString() },
                                    {"gid", "varchar", s.gid.Trim() }, { "start_price", "float", s.kLineDay[currentIndex].startPrice.ToString()} });
                            }
                            s.kLineDay[currentIndex].endPrice = currentSettlePrice;
                        }
                    }
                    catch
                    {

                    }
                }
            }
        }
    }
</script>