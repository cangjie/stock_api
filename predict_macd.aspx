<%@ Page Language="C#" %>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime currentDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", DateTime.Now.ToShortDateString()));
        if (DateTime.Now.Hour < 15 && currentDate.ToShortDateString().Equals(DateTime.Now.ToShortDateString()))
        {
            currentDate = Util.GetLastTransactDate(currentDate, 1);
        }
        if (!Util.IsTransacDay(currentDate))
        {
            return;
        }
        int i = 0;
        foreach (string gid in Util.GetAllGids())
        {
            Stock stock = new Stock(gid);
            stock.LoadKLineDay(Util.rc);
            int currentIndex = stock.GetItemIndex(currentDate);
            if (currentIndex < 0)
            {
                continue;
            }
            KLine.ComputeMACD(stock.kLineDay);
            if (stock.kLineDay[currentIndex].macd >= 0)
            {
                continue;
            }
            KLine[] kArr = new KLine[currentIndex+1];
            for (int j = 0; j < currentIndex; j++)
            {
                kArr[j] = stock.kLineDay[j];
            }
            kArr[kArr.Length - 1] = new KLine();
            double endPrice = kArr[currentIndex-1].endPrice;
            double limitUpPrice = endPrice * 1.11;
            double limitDownPrice = endPrice * 0.89;
            bool haveCross = false;
            for (double predictPrice = limitDownPrice; predictPrice <= limitUpPrice; predictPrice = predictPrice + 0.01)
            {
                kArr[kArr.Length - 1].endPrice = predictPrice;
                KLine.ComputeMACD(kArr);
                if (kArr[kArr.Length - 1].macd > 0 && kArr[kArr.Length - 2].macd < 0)
                {
                    try
                    {
                        int k = DBHelper.InsertData("alert_predict_macd", new string[,] { {"alert_date", "datetime", currentDate.ToShortDateString() },
                    {"gid", "varchar", gid.Trim() }, {"predict_macd_price", "float", predictPrice.ToString() } });
                        if (k > 0)
                        {
                            haveCross = true;
                        }
                    }
                    catch
                    {

                    }
                }
                if (haveCross)
                {
                    break;
                }
            }

            i++;
        }
    }
</script>