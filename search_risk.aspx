<%@ Page Language="C#" %>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", "2021-1-4"));
        DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", DateTime.Now.ToShortDateString()));
        string[] gidArr = Util.GetAllGids();
        foreach (string gid in gidArr)
        {
            Stock s = new Stock(gid);
            s.LoadKLineDay(Util.rc);
            int startIndex = s.GetItemIndex(startDate);
            if (startIndex < 16)
            {
                continue;
            }
            for (int i = startIndex; i < s.kLineDay.Length && s.kLineDay[i].endDateTime.Date <= endDate; i++)
            {
                double risk = KLine.ComputeRisk(s.kLineDay, i);
                try
                {
                    DBHelper.InsertData("risk", new string[,] {{"gid", "varchar", gid.Trim() },
                    {"alert_date", "datetime", s.kLineDay[i].endDateTime.ToShortDateString() },
                    {"risk", "float", Math.Round(risk, 2).ToString() } });

                }
                catch
                {

                }
            }
        }

    }
</script>
