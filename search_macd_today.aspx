<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime currentDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", DateTime.Now.ToShortDateString()));
        DataTable dt = DBHelper.GetDataTable(" select * from alert_predict_macd where valid = 0 and alert_date = '" + Util.GetLastTransactDate(currentDate, 1) + "' ");
        foreach (DataRow dr in dt.Rows)
        {
            DateTime lastDate = DateTime.Parse(dr["alert_date"].ToString());
            Stock s = new Stock(dr["gid"].ToString().Trim());
            double highPrice = 0;
            if (currentDate.Date == DateTime.Now.Date)
            {
                Core.Timeline[] timelineArr = Core.Timeline.LoadTimelineArrayFromRedis(s.gid, currentDate, rc);
                if (timelineArr.Length > 0)
                {
                    highPrice = timelineArr[timelineArr.Length - 1].todayHighestPrice;
                }
            }

            if (highPrice == 0)
            {
                s.LoadKLineDay(rc);
                int currentIndex = s.GetItemIndex(currentDate);
                if (currentIndex < 0)
                {
                    continue;
                }
                highPrice = s.kLineDay[currentIndex].highestPrice;
            }
            

            if (highPrice > double.Parse(dr["predict_macd_price"].ToString()))
            {
                try
                {
                    DBHelper.UpdateData("alert_predict_macd", new string[,] { { "valid", "int", "1" } },
                        new string[,] { { "alert_date", "datetime", lastDate.ToShortDateString() }, { "gid", "varchar", s.gid } }, Util.conStr);
                }
                catch
                {

                }
            }
        }
    }
</script>