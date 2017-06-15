<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<script runat="server">

    public DateTime start = DateTime.Parse(DateTime.Now.ToShortDateString());
    public DateTime end = DateTime.Parse(DateTime.Now.ToShortDateString());
    public DataTable dt = new DataTable();
    public string[] stockListArr = Util.GetAllStockCode();

    protected void Page_Load(object sender, EventArgs e)
    {
        start = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", DateTime.Now.ToShortDateString()));
        end = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", DateTime.Now.ToShortDateString()));
        dt.Columns.Add("date");
        dt.Columns.Add("gid");
        dt.Columns.Add("settlement");
        dt.Columns.Add("ava3");
        dt.Columns.Add("open");
        dt.Columns.Add("highest_3d");
        dt.Columns.Add("highest_5d");

        //GetSuggest(start, "sz002579");

        for (DateTime i = end; i >= start; i = i.AddDays(-1))
        {
            if (Util.IsTransacDay(i))
            {
                foreach (string stockCode in stockListArr)
                {
                    //if (stockCode.Trim().Equals("sz0002579"))
                    DataRow dr = GetSuggest(i, stockCode);
                    if (dr != null)
                        dt.Rows.Add(dr);
                }
            }
        }

        string json = "{\"status\" :0, \"items\" : [";
        string itemsJson = "";
        foreach (DataRow dr in dt.Rows)
        {
            itemsJson = itemsJson + ((!itemsJson.Trim().Equals("")) ? ", " : "");
            string fieldJson = "";
            foreach (DataColumn dc in dt.Columns)
            {
                fieldJson = fieldJson
                    + (fieldJson.Trim().Equals("") ? "" : ", ")
                    + "\"" + dc.Caption.Trim() + "\": \"" + dr[dc].ToString().Trim() + "\"";
            }
            itemsJson = itemsJson + "{" + fieldJson.Trim() + "}";
        }
        json = json + itemsJson + "] }";
        Response.Write(json);
    }

    public DataRow GetSuggest(DateTime day, string stockCode)
    {
        KLine[] kArr = KLine.GetKLine("day", stockCode, day.AddMonths(-1), day);
        if (kArr.Length < 6)
            return null;
        double price_3_3_yesterday = Util.Compute_3_3_Price(kArr, kArr[kArr.Length - 2].startDateTime);
        double price_3_3_today = Util.Compute_3_3_Price(kArr, kArr[kArr.Length - 1].startDateTime);
        if (kArr[kArr.Length - 2].endPrice < price_3_3_yesterday
            && kArr[kArr.Length - 1].startPrice > kArr[kArr.Length - 2].endPrice
            && kArr[kArr.Length -1 ].startPrice > price_3_3_today 
            && kArr[kArr.Length - 2].endPrice != 0 && kArr[kArr.Length -1 ].startPrice !=0
            )
        {
            DataRow dr = dt.NewRow();
            dr["date"] = day;
            dr["gid"] = stockCode;
            dr["settlement"] = kArr[kArr.Length - 2].endPrice;
            dr["open"] = kArr[kArr.Length - 1].startPrice;
            dr["ava3"] = price_3_3_yesterday;
            dr["highest_3d"] = 0;
            dr["highest_5d"] = 0;
            return dr;
        }
        return null;
    }

</script>