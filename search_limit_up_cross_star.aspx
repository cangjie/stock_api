<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    

    public static Stock[] gidArr;

    protected void Page_Load(object sender, EventArgs e)
    {
        FillStockArr();
        DataTable dt = DBHelper.GetDataTable(" select * from limit_up order by alert_date ");
        foreach (DataRow dr in dt.Rows)
        {
            Stock s = GetStock(dr["gid"].ToString());
            if (s.kLineDay == null)
            {
                continue;
            }
            DateTime currentDate = DateTime.Parse(dr["alert_date"].ToString());
            try
            {
                if (IsCrossStar(currentDate, s))
                {
                    DBHelper.UpdateData("limit_up", new string[,] { { "next_day_cross_star_un_limit_up", "int", "1" } },
                        new string[,] { { "gid", "varchar", s.gid.Trim() }, { "alert_date", "datetime", currentDate.ToShortDateString() } }, Util.conStr);
                }
            }
            catch
            {

            }
        }
    }

    public bool IsCrossStar(DateTime currentDate, Stock s)
    {
        int currentIndex = s.GetItemIndex(currentDate);
        if (currentIndex + 1 >= s.kLineDay.Length)
        {
            return false;
        }
        if (s.kLineDay[currentIndex + 1].endPrice == s.kLineDay[currentIndex + 1].highestPrice
            && s.kLineDay[currentIndex + 1].endPrice >= s.kLineDay[currentIndex].endPrice * 1.0985)
        {
            return false;
        }
        if (s.kLineDay[currentIndex+1].lowestPrice < s.kLineDay[currentIndex].endPrice - 0.02)
        {
            return false;
        }
        return true;
    }

    public void FillStockArr()
    {
        DataTable dt = DBHelper.GetDataTable(" select distinct gid from limit_up ");
        gidArr = new Stock[dt.Rows.Count];
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            gidArr[i] = new Stock(dt.Rows[i][0].ToString().Trim());
            gidArr[i].LoadKLineDay(Util.rc);
        }
    }

    public Stock GetStock(string gid)
    {
        Stock s = new Stock();
        foreach (Stock st in gidArr)
        {
            if (st.gid.Trim().Equals(gid))
            {
                s = st;
                break;
            }
        }
        return s;
    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
    
    </div>
    </form>
</body>
</html>
