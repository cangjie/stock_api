<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>

<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");
    public static Stock[] sArr;

    protected void Page_Load(object sender, EventArgs e)
    {
        DataTable dt = DBHelper.GetDataTable(" select distinct gid from bottom_break_cross_3_line where settle_confirm = 0 ");
        sArr = new Stock[dt.Rows.Count];
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            sArr[i] = new Stock(dt.Rows[i][0].ToString().Trim());
            sArr[i].LoadKLineDay(rc);
        }
        dt.Dispose();
        dt = DBHelper.GetDataTable("  select * from bottom_break_cross_3_line where settle_confirm = 0  ");
        foreach (DataRow dr in dt.Rows)
        {
            Stock s = GetStock(dr["gid"].ToString().Trim());
            DateTime currentDate = DateTime.Parse(dr["suggest_date"].ToString().Trim());
            int currentIndex = s.GetItemIndex(currentDate);
            if (currentIndex < 0)
            {
                continue;
            }
            double line3Price = s.GetAverageSettlePrice(currentIndex, 3, 3);
            if (s.kLineDay[currentIndex].endPrice > line3Price)
            {
                Update(s.gid, currentDate);
            }
        }
    }

    public Stock GetStock(string gid)
    {
        Stock s = new Stock();
        foreach (Stock st in sArr)
        {
            if (st.gid.Trim().Equals(gid.Trim()))
            {
                s = st;
                break;
            }
        }
        return s;
    }

    public void Update(string gid, DateTime currentDate)
    {
        DBHelper.UpdateData("bottom_break_cross_3_line", new string[,] { { "settle_confirm", "int", "1" } },
            new string[,] { { "suggest_date", "datetime", currentDate.ToShortDateString() }, { "gid", "varchar", gid.Trim() } }, Util.conStr.Trim());
    }
</script>