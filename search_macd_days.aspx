<%@ Page Language="C#" %>


<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime start = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", DateTime.Now.ToShortDateString()));

        if (!Util.IsTransacDay(start))
        {
            start = Util.GetLastTransactDate(start, 1);
        }

        DateTime end = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", DateTime.Now.ToShortDateString()));
        if (!Util.IsTransacDay(end))
        {
            end = Util.GetLastTransactDate(end, 1);
        }
        int days = int.Parse(Util.GetSafeRequestValue(Request, "days", "20"));

        string[] gidArr = Util.GetAllGids();
        for (int i = 0; i < gidArr.Length; i++)
        {
            Stock s = new Stock(gidArr[i].Trim());
            s.LoadKLineDay(Util.rc);
            KLine.ComputeMACD(s.kLineDay);
            int startIndex = s.GetItemIndex(start);
            if (startIndex < 0)
            {
                continue;
            }
            int endIndex = s.GetItemIndex(end);
            if (endIndex < 0 || startIndex > endIndex)
            {
                continue;
            }
            for (int j = startIndex; j <= endIndex; j++)
            {
                int macdDays = s.macdDays(j);
                if (macdDays >= days)
                {
                    DBHelper.InsertData("alert_macd_days", new string[,] { {"alert_date", "datetime", s.kLineDay[j].endDateTime.ToShortDateString() },
                    {"gid", "varchar", s.gid }, {"days", "int", macdDays.ToString() } });

                }
            }
        }

    }
</script>
