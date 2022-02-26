<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        //DateTime currentDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", DateTime.Now.ToShortDateString()));

        //DateTime currentDate = DateTime.Parse("2018-8-24");

        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", DateTime.Now.ToShortDateString()));

        //startDate = DateTime.Parse("2022-2-25");

        DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", DateTime.Now.ToShortDateString()));



        for (DateTime i = endDate.Date; i >= startDate.Date; i = i.AddDays(-1))
        {
            if (Util.IsTransacDay(i))
            {
                DataTable dt = DBHelper.GetDataTable(" select * from limit_up where alert_date = '" + Util.GetLastTransactDate(i, 1).ToShortDateString() + "' ");
                foreach (DataRow dr in dt.Rows)
                {
                    Stock s = new Stock(dr["gid"].ToString());
                    s.LoadKLineDay(Util.rc);
                    int limitUpIndex = s.GetItemIndex(DateTime.Parse(dr["alert_date"].ToString()));
                    if (limitUpIndex < 0 || limitUpIndex >= s.kLineDay.Length - 1)
                    {
                        continue;
                    }
                    if (!s.IsLimitUp(limitUpIndex))
                    {
                        continue;
                    }
                    double currentVolume = s.kLineDay[limitUpIndex + 1].volume;
                    double limitUpVolume = s.kLineDay[limitUpIndex].volume;
                    int isLimutUp = s.IsLimitUp(limitUpIndex + 1) ? 1 : 0;
                    if (Math.Abs(currentVolume - limitUpVolume) / limitUpVolume <= 0.1)
                    {
                        DBHelper.InsertData("alert_limit", new string[,] { {"alert_date", "datetime", s.kLineDay[limitUpIndex + 1].endDateTime.ToShortDateString() },
                        {"gid", "varchar", s.gid.Trim() }, {"is_limit_up", "int", isLimutUp.ToString() } });
                    }
                }
            }
        }




    }
</script>