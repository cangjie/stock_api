<%@ Page Language="C#" %>
<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        //DateTime currentDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", DateTime.Now.ToShortDateString()));

        //DateTime currentDate = DateTime.Parse("2018-8-24");

        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", DateTime.Now.ToShortDateString()));

        DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", DateTime.Now.ToShortDateString()));

        string[] gidArr = Util.GetAllGids();
        for (int i = 0; i < gidArr.Length; i++)
        {
            try
            {
                Stock s = new Stock(gidArr[i].Trim());
                s.LoadKLineDay();

                for (DateTime currentDate = startDate; currentDate <= endDate; currentDate = currentDate.AddDays(1))
                {
                    if (!Util.IsTransacDay(currentDate))
                    {
                        continue;
                    }

                    int currentIndex = s.GetItemIndex(currentDate);
                    if (currentIndex > 0)
                    {
                        if (s.kLineDay[currentIndex].endPrice == s.kLineDay[currentIndex].lowestPrice && s.kLineDay[currentIndex].lowestPrice <= s.kLineDay[currentIndex - 1].endPrice * (1 - 0.09))
                        {
                            try
                            {
                                DBHelper.InsertData("limit_down", new string[,] { { "gid", "varchar", s.gid.Trim() }, { "alert_date", "datetime", s.kLineDay[currentIndex].endDateTime.ToShortDateString() } });
                            }
                            catch
                            {

                            }
                        }
                    }
                }
            }
            catch
            { 
            
            }
        }

    }
</script>