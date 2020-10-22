<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>

<script runat="server">
    public  ArrayList gidArr = new ArrayList();

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!Util.IsTransacDay(DateTime.Now))
        {
            Response.End();
        }
        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", DateTime.Now.Date.ToShortDateString()));
        DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", DateTime.Now.Date.ToShortDateString()));

        string sql = " select * from limit_up where alert_date >= '" + Util.GetLastTransactDate(startDate, 1).ToShortDateString()
            + "' and alert_date <= '" + Util.GetLastTransactDate(endDate, 1).ToShortDateString() + "' ";
        DataTable dt = DBHelper.GetDataTable(sql);
        foreach (DataRow dr in dt.Rows)
        {
            string gid = dr["gid"].ToString().Trim();
            Stock s = GetStock(gid);
            DateTime currentDate = DateTime.Parse(dr["alert_date"].ToString());
            int currentIndex = s.GetItemIndex(currentDate);
            if (currentIndex < 0 || currentIndex >= s.kLineDay.Length-1)
            {
                continue;
            }
            if (s.IsLimitUp(currentIndex + 1))
            {
                continue;
            }
            if (s.kLineDay[currentIndex].volume < s.kLineDay[currentIndex + 1].volume)
            {
                continue;
            }
            try
            {
                DBHelper.InsertData("limit_up_volume_reduce", new string[,] {
                    {"alert_date", "datetime", s.kLineDay[currentIndex+1].startDateTime.ToShortDateString() },
                    {"gid", "varchar", s.gid.Trim() }});
            }
            catch
            {

            }
        }

    }

    public Stock GetStock(string gid)
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
        if (!found)
        {
            s = new Stock(gid);
            s.LoadKLineDay(Util.rc);
            gidArr.Add(s);
        }
        return s;
    }
</script>