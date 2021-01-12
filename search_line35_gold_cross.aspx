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
                    int macdDays = s.macdDays(currentIndex);
                    if (lastLine3Price <= lastLine5Price && currentLine3Price > currentLine5Price && macdDays > 0)
                    {
                        try
                        {
                            DBHelper.InsertData("alert_line35_gold_cross", new string[,] {
                                {"alert_date", "datetime", s.kLineDay[currentIndex].endDateTime.ToShortDateString() },
                                {"gid", "varchar", s.gid.Trim() },
                                {"macd_days", "int", macdDays.ToString() }
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