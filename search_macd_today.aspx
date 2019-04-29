<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime currentDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", DateTime.Now.ToShortDateString()));
        DataTable dt = DBHelper.GetDataTable(" select * from alert_predict_macd where alert_date = '" + Util.GetLastTransactDate(currentDate, 1) + "' ");
        foreach (DataRow dr in dt.Rows)
        {
            currentDate = DateTime.Parse(dr["alert_date"].ToString());
            Stock s = new Stock(dr["gid"].ToString().Trim());
            s.LoadKLineDay(rc);
            int currentIndex = s.GetItemIndex(currentDate);
            if (currentIndex < 0)
            {
                continue;
            }
            if (s.kLineDay[currentIndex].highestPrice > double.Parse(dr["predict_macd_price"].ToString()))
            {
                try
                {
                    DBHelper.UpdateData("alert_predict_macd", new string[,] { { "valid", "int", "1" } },
                        new string[,] { { "alert_date", "datetime", currentDate.ToShortDateString() }, { "gid", "varchar", s.gid } }, Util.conStr);
                }
                catch
                {

                }
            }
        }
    }
</script>