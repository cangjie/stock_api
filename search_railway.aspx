<%@ Page Language="C#" %>
<script runat="server">

    public DateTime startDate = DateTime.Parse("2021-1-1");

    protected void Page_Load(object sender, EventArgs e)
    {
        string[] gidArr = Util.GetAllGids();
        foreach (string gid in gidArr)
        {
            Stock s = new Stock(gid);
            s.LoadKLineDay(Util.rc);
            for (DateTime i = startDate.Date; i <= DateTime.Now.Date; i = i.AddDays(1))
            {
                if (Util.IsTransacDay(i))
                {
                    int currentIndex = s.GetItemIndex(i);
                    if (currentIndex < 2)
                    {
                        continue;
                    }
                    if ((s.kLineDay[currentIndex].endPrice - s.kLineDay[currentIndex - 1].endPrice) / s.kLineDay[currentIndex - 1].endPrice >= 0.07
                        && (s.kLineDay[currentIndex - 1].endPrice - s.kLineDay[currentIndex - 2].endPrice) / s.kLineDay[currentIndex - 2].endPrice <= -0.07)
                    {
                        try
                        {
                            DBHelper.InsertData("alert_railway", new string[,] { { "gid", "varchar", s.gid.Trim() }, { "alert_date", "datetime", i.ToShortDateString() } });
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