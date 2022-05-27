<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime startDate = DateTime.Parse("2022-3-15").Date;
        startDate = Util.GetLastTransactDate(startDate, 1);
        DateTime endDate =  DateTime.Parse("2022-5-17").Date;
        //endDate = Util.GetLastTransactDate(endDate, 1);

        startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", DateTime.Now.ToShortDateString()));

        if (!Util.IsTransacDay(startDate))
        {
            Response.End();
        }

        endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", startDate.ToShortDateString()));
        if (!Util.IsTransacDay(endDate))
        {
            endDate = Util.GetLastTransactDate(endDate, 1);
        }


        double targetWidth = 0.3;

        string[] gidArr = Util.GetAllGids();

        for (int i = 0; i < gidArr.Length; i++)
        {
            Stock s = new Stock(gidArr[i]);
            s.LoadKLineDay(Util.rc);
            int startIndex = s.GetItemIndex(startDate);
            int endIndex = s.GetItemIndex(endDate);
            if (startIndex <= 5 || endIndex < startIndex || endIndex <= 5)
            {
                continue;
            }

            for (int j = startIndex; j <= endIndex; j++)
            {
                if (s.kLineDay[j].endPrice > s.GetAverageSettlePrice(j, 3, 3))
                {
                    int lowIndex = -1;
                    double lowPrice = GetFirstLowestPrice(s.kLineDay, j, out lowIndex);
                    if (lowIndex >= 0)
                    {
                        double highPrice = s.kLineDay[j].highestPrice;
                        double width = (highPrice - lowPrice) / lowPrice;
                        if (width > targetWidth)
                        {
                            int cross3LineTimes = 0;
                            for (int k = lowIndex + 1; k <= j; k++)
                            {
                                if (s.kLineDay[k - 1].endPrice <= s.GetAverageSettlePrice(k - 1, 3, 3)
                                    && s.kLineDay[k].endPrice > s.GetAverageSettlePrice(k, 3, 3))
                                {
                                    cross3LineTimes++;
                                }
                            }
                            if (cross3LineTimes == 1)
                            {
                                DataTable dt = DBHelper.GetDataTable(" select * from alert_big_rise where gid = '" + s.gid.Trim() + "' and low_date = '"
                                    + s.kLineDay[lowIndex].endDateTime.ToShortDateString() + "' and alert_date < '" + s.kLineDay[j].endDateTime.ToShortDateString() + "' ");
                                if (dt.Rows.Count == 0)
                                {
                                    DBHelper.InsertData("alert_big_rise", new string[,] {{"alert_date", "datetime", s.kLineDay[j].endDateTime.ToShortDateString() },
                                        {"gid", "varchar", s.gid.Trim() }, {"low_date", "datetime", s.kLineDay[lowIndex].endDateTime.ToShortDateString() },
                                        {"low_price", "float", s.kLineDay[lowIndex].lowestPrice.ToString() }, {"high_price", "float", s.kLineDay[j].highestPrice.ToString() } });
                                }
                                dt.Dispose();

                            }


                        }

                    }


                }
            }
        }
    }
    public static double GetFirstLowestPrice(KLine[] kArr, int index, out int lowestIndex)
    {
        double ret = double.MaxValue;
        int find = 0;
        lowestIndex = 0;
        for (int i = index - 1; i > 0 && find < 2; i--)
        {
            double line3Pirce = KLine.GetAverageSettlePrice(kArr, i, 3, 3);
            ret = Math.Min(ret, kArr[i].lowestPrice);
            if (ret == kArr[i].lowestPrice)
            {
                lowestIndex = i;
            }
            if (kArr[i].endPrice < line3Pirce)
            {
                find = 1;
            }
            if (kArr[i].lowestPrice >= line3Pirce && find == 1)
            {
                find = 2;
            }
        }
        return ret;
    }
</script>