<%@ Page Language="C#" %>


<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", "2020-1-6"));
        string[] allGids = Util.GetAllGids();
        foreach (string gid in allGids)
        {
            try
            {
                Stock s = new Stock(gid);
                s.LoadKLineDay(Util.rc);
                int startIndex = s.GetItemIndex(startDate);
                if (startIndex < 1 || startIndex >= s.kLineDay.Length)
                {
                    continue;
                }
                for (int i = startIndex; i < s.kLineDay.Length; i++)
                {
                    double percent = (s.kLineDay[i].startPrice - s.kLineDay[i - 1].endPrice) / s.kLineDay[i - 1].endPrice;
                    if (percent >= 0.06)
                    {
                        DBHelper.InsertData("alert_open", new string[,] { {"alert_date", "datetime", s.kLineDay[i].startDateTime.ToShortDateString() },
                        {"gid", "varchar", s.gid }, {"change_percent", "float", percent.ToString() } });
                    }
                }
            }
            catch
            {

            }
        }
    }
</script>
