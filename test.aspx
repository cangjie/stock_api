<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        DataTable dt = DBHelper.GetDataTable(" select * from limit_up  ");
        foreach (DataRow dr in dt.Rows)
        {
            Stock stock = new Stock(dr["gid"].ToString().Trim());
            stock.LoadKLineDay();
            LimitUp.SearchCrossStar(stock, DateTime.Parse(dr["alert_date"].ToString()));
        }
        return;
        string[] gidArr = Util.GetAllGids();
        for (int i = 0; i < gidArr.Length; i++)
        {

            Stock s = new Stock(gidArr[i]);
            s.LoadKLineDay();

            for (int j = 1; j < s.kLineDay.Length - 1; j++)
            {

                if (s.IsLimitUp(j))
                {
                    LimitUp.SaveLimitUp(s.gid.Trim(), DateTime.Parse(s.kLineDay[j].startDateTime.ToShortDateString()), s.kLineDay[j - 1].endPrice,
                        s.kLineDay[j].startPrice, s.kLineDay[j].endPrice, s.kLineDay[j].volume);
                }
            }
        }
    }
</script>
