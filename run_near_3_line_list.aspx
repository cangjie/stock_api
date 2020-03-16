<%@ Page Language="C#" %>


<script runat="server">

    public Stock[] sArr;

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", DateTime.Now.ToLongDateString()));
        DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", DateTime.Now.ToLongDateString()));
        string[] gidArr = Util.GetAllGids();
        sArr = new Stock[gidArr.Length];
        for (int i = 0; i < gidArr.Length; i++)
        {
            sArr[i] = new Stock(gidArr[i].Trim());
            sArr[i].LoadKLineDay(Util.rc);
        }
        for (DateTime i = startDate; i <= endDate; i = i.AddDays(1))
        {
            if (Util.IsTransacDay(i))
            {
                GetData(i);
            }
        }
    }

    public void GetData(DateTime currentDate)
    {
        for (int i = 0; i < sArr.Length; i++)
        {
            Stock s = sArr[i];
            int currentIndex = s.GetItemIndex(currentDate);
            if (currentIndex <= 10)
            {
                continue;
            }
            double prev3Line = s.GetAverageSettlePrice(currentIndex - 1, 3, 3);
            double current3Line = s.GetAverageSettlePrice(currentIndex, 3, 3);
            double next3Line = s.GetAverageSettlePrice(currentIndex + 1, 3, 3);
            double afterNext3Line = s.GetAverageSettlePrice(currentIndex + 2, 3, 3);
            if (!(prev3Line <= current3Line && current3Line <= next3Line && next3Line <= afterNext3Line))
            {
                continue;
            }
            if (s.kLineDay[currentIndex].endPrice <= current3Line || s.kLineDay[currentIndex].lowestPrice >= current3Line * 1.01)
            {
                continue;
            }

            int highestIndex = 0;
            double highestPrice = 0;
            int lowestIndex = 0;
            double lowestPrice = double.MaxValue;
            int cross3LineTimes = 0;
            int limitUpNum = 0;
            for (int j = currentIndex; cross3LineTimes < 2 && j >= 0; j--)
            {

                if (cross3LineTimes == 0)
                {
                    if (s.kLineDay[j].highestPrice > highestPrice)
                    {
                        highestIndex = j;
                        highestPrice = s.kLineDay[j].highestPrice;
                    }
                    if (s.kLineDay[j].endPrice < s.GetAverageSettlePrice(j, 3, 3))
                    {
                        cross3LineTimes++;
                    }
                }
                if (cross3LineTimes == 1)
                {
                    if (s.kLineDay[j].lowestPrice < lowestPrice)
                    {
                        lowestIndex = j;
                        lowestPrice = s.kLineDay[j].lowestPrice;
                    }
                    if (s.kLineDay[j].endPrice > s.GetAverageSettlePrice(j, 3, 3))
                    {
                        cross3LineTimes++;
                    }
                }
            }
            for (int j = lowestIndex; j <= highestIndex; j++)
            {
                if (s.IsLimitUp(j))
                {
                    limitUpNum++;
                }
            }
            if (limitUpNum >= 2)
            {
                try
                {
                    DBHelper.InsertData("alert_near_3_line_list", new string[,] {
                        {"alert_date", "datetime", currentDate.ToShortDateString() },
                        {"gid", "varchar", s.gid.Trim() },
                        {"highest_date", "datetime", s.kLineDay[highestIndex].endDateTime.ToShortDateString() },
                        {"highest_price", "float", highestPrice.ToString() },
                        {"lowest_date", "datetime", s.kLineDay[lowestIndex].endDateTime.ToShortDateString() },
                        {"lowest_price", "float", lowestPrice.ToString() },
                        {"line3_price", "float", current3Line.ToString() },
                        {"settle_price", "float", s.kLineDay[currentIndex].endPrice.ToString() },
                        {"current_low_price", "float", s.kLineDay[currentIndex].lowestPrice.ToString() },
                        {"limit_up_num", "int", limitUpNum.ToString() }
                    });
                }
                catch(Exception msg)
                {
                    System.Diagnostics.Debug.WriteLine(msg.ToString());
                }
            }
        }
    }
</script>