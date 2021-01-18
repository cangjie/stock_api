<%@ Page Language="C#" %>


<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime currentDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", DateTime.Now.ToShortDateString()));

        string[] gidArr = Util.GetAllGids();
        foreach (string gid in gidArr)
        {
            Stock s = new Stock(gid);
            s.LoadKLineDay(Util.rc);
            KLine.ComputeMACD(s.kLineDay);

            for (DateTime i = currentDate; i <= DateTime.Now.Date; i = i.AddDays(1))
            {
                if (Util.IsTransacDay(i))
                {
                    int currentIndex = s.GetItemIndex(i);
                    if (currentIndex <= 0)
                    {
                        continue;
                    }
                    double currentLine3Price = s.GetAverageSettlePrice(currentIndex, 3, 3);
                    double currentLine5Price = s.GetAverageSettlePrice(currentIndex, 5, 5);
                    double lastLine3Price = s.GetAverageSettlePrice(currentIndex - 1, 3, 3);
                    double lastLine5Price = s.GetAverageSettlePrice(currentIndex - 1, 5, 5);
                    double currentMa5Price = s.GetAverageSettlePrice(currentIndex, 5, 0);
                    double lastMa5Price = s.GetAverageSettlePrice(currentIndex - 1, 5, 0);
                    //int macdDays = s.macdDays(currentIndex);
                    if (currentLine5Price < Math.Min(currentLine3Price, currentMa5Price)
                        && lastLine5Price < Math.Min(lastLine3Price, lastMa5Price)
                        && currentLine5Price > lastLine5Price
                        && lastMa5Price < lastLine3Price
                        && currentMa5Price > currentLine3Price)
                    {
                        try
                        {
                            DBHelper.InsertData("alert_ma5_line3_gold_cross", new string[,] {
                                {"alert_date", "datetime", s.kLineDay[currentIndex].endDateTime.ToShortDateString() },
                                {"gid", "varchar", s.gid.Trim() },
                                {"ma5", "float", currentMa5Price.ToString() },
                                {"line3", "float", currentLine3Price.ToString() },
                                {"line5", "float", currentLine5Price.ToString() }
                            });
                        }
                        catch
                        {

                        }
                    }
                }
            }
        }
    }
</script>