<%@ Page Language="C#" %>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime startDate = DateTime.Parse("2022-4-11").Date;
        startDate = Util.GetLastTransactDate(startDate, 1);
        DateTime endDate =  DateTime.Parse("2022-5-17").Date;

        //endDate = Util.GetLastTransactDate(endDate, 1);
        double targetWidth = 0.3;
        string[] gidArr = Util.GetAllGids();
        for (int i = 0; i < gidArr.Length; i++)
        {
            Stock s = new Stock(gidArr[i]);
            s.LoadKLineDay(Util.rc);
            int startIndex = s.GetItemIndex(startDate);
            int endIndex = s.GetItemIndex(endDate);
            if (startIndex <= 5 || endIndex <= startIndex || endIndex <= 5)
            {
                continue;
            }
            int upCross3LineIndex = 0;
            int highIndex = 0;
            double highPrice = 0;
            for (int j = startIndex; j <= endIndex; j++)
            {
                if (s.kLineDay[j - 1].endPrice <= s.GetAverageSettlePrice(j - 1, 3, 3) && s.kLineDay[j].endPrice > s.GetAverageSettlePrice(j, 3, 3) && upCross3LineIndex == 0)
                {
                    upCross3LineIndex = j;
                }
                if (s.kLineDay[j - 1].endPrice >= s.GetAverageSettlePrice(j - 1, 3, 3) && s.kLineDay[j].endPrice < s.GetAverageSettlePrice(j, 3, 3) && upCross3LineIndex > 0)
                {
                    double width = (highPrice - s.kLineDay[upCross3LineIndex].endPrice) / s.kLineDay[upCross3LineIndex].endPrice;
                    if (width >= targetWidth)
                    {
                        DBHelper.InsertData("big_rise", new string[,] { { "start_date", "datetime", s.kLineDay[upCross3LineIndex].endDateTime.ToShortDateString()},
                        {"gid", "varchar", s.gid.Trim() }, {"high_date", "datetime", s.kLineDay[highIndex].endDateTime.ToShortDateString() },
                        { "width", "float", width.ToString()} });
                        
                    }
                    upCross3LineIndex = 0;
                    highIndex = 0;
                    highPrice = 0;
                    continue;
                }

                if (highPrice < s.kLineDay[j].endPrice && upCross3LineIndex > 0)
                {
                    highPrice = s.kLineDay[j].endPrice;
                    highIndex = j;
                }
            }

        }
    }
</script>