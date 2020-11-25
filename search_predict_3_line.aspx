<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("52.82.51.144");

    public static ArrayList gidArr = new ArrayList();

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime startDate = GetStartDate();
        for(DateTime i = startDate; i <= DateTime.Now.Date; i = i.AddDays(1))
        {
            if (Util.IsTransacDay(i))
            {
                //SearchReverse(i);
                Search3Line(i);
            }
        }
    }

    public void Search3Line(DateTime currentDate)
    {
        foreach (string gid in Util.GetAllGids())
        {
            Stock stock = GetStock(gid);
            if (stock == null && currentDate != DateTime.Now.Date)
            {
                stock = new Stock(gid);
                stock.LoadKLineDay(rc);
                gidArr.Add(stock);
            }
            int currentIndex = stock.GetItemIndex(currentDate);
            if (currentIndex < 6)
            {
                continue;
            }
            double today3Line = stock.GetAverageSettlePrice(currentIndex, 3, 3);
            double next3Line = (stock.kLineDay[currentIndex - 1].endPrice + stock.kLineDay[currentIndex - 2].endPrice
                + stock.kLineDay[currentIndex - 3].endPrice) / 3;

            if (stock.kLineDay[currentIndex].endPrice >= today3Line)
            {
                continue;
            }
            if ((next3Line - stock.kLineDay[currentIndex].endPrice) / stock.kLineDay[currentIndex].endPrice > 0.095)
            {
                continue;
            }
            int below3LineDays = 1;
            for (; stock.kLineDay[currentIndex - below3LineDays].endPrice < stock.GetAverageSettlePrice(currentIndex - below3LineDays, 3, 3); below3LineDays++)
            {

            }
            if (below3LineDays < 5)
            {
                continue;
            }
            try
            {
                DBHelper.InsertData("alert_predict_3_line", new string[,] {
                    {"alert_date", "datetime", currentDate.ToShortDateString() },
                    {"gid", "varchar", gid.Trim() },
                    {"under_3_line_days", "float",  below3LineDays.ToString()},
                    {"next_3_line_price", "float", next3Line.ToString() }
                });
            }
            catch
            {

            }
        }
    }

    public static Stock GetStock(string gid)
    {
        Stock s = new Stock();
        bool found = false;
        foreach (object o in gidArr)
        {
            if (((Stock)o).gid.Trim().Equals(gid))
            {
                found = true;
                s = (Stock)o;
                break;
            }
        }
        if (found)
        {
            return s;
        }
        else
        {
            return null;
        }
    }

    public DateTime GetStartDate()
    {
        DateTime startDate = DateTime.Parse("2017-9-1");
        if (!Util.GetSafeRequestValue(Request, "date", "").Equals(""))
        {
            try
            {
                startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", ""));
                if (startDate == DateTime.Parse("1900-1-1"))
                {
                    startDate = DateTime.Now.Date;
                }
            }
            catch
            {

            }
        }
        //startDate = DateTime.Parse("2019-6-11");
        return startDate;
    }


</script>