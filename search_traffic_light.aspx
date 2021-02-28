<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime date = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", DateTime.Now.ToShortDateString()));
        DataTable dtOri = DBHelper.GetDataTable(" select gid, alert_date from limit_up a where  alert_date >= '" + Util.GetLastTransactDate(date, 2) + "' "
            + " and alert_date <=  '" + Util.GetLastTransactDate(DateTime.Now, 2) + "' "
            + " and not exists ( select 'a' from limit_up c where a.gid = c.gid and dbo.func_GetLastTransactDate(c.alert_date, 1) = a.alert_date ) "
            //+ " and not exists ( select 'a' from limit_up d where a.gid = d.gid and dbo.func_GetLastTransactDate(d.alert_date, 2) = a.alert_date ) "
            );

        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock s = GetStock(drOri["gid"].ToString());
            DateTime alertDate = DateTime.Parse(drOri["alert_date"].ToString());
            int limitUpIndex = s.GetItemIndex(alertDate);
            if (limitUpIndex < 0 || limitUpIndex + 2 >= s.kLineDay.Length)
            {
                continue;
            }
            if (!s.IsLimitUp(limitUpIndex))
            {
                continue;
            }
            if (!s.IsLimitUp(limitUpIndex + 1) //&& !s.IsLimitUp(limitUpIndex + 2)
                && (s.kLineDay[limitUpIndex + 1].endPrice - s.kLineDay[limitUpIndex].endPrice) / s.kLineDay[limitUpIndex].endPrice > -0.095
                && (s.kLineDay[limitUpIndex + 2].endPrice - s.kLineDay[limitUpIndex].endPrice) / s.kLineDay[limitUpIndex + 1].endPrice > -0.095
                && s.kLineDay[limitUpIndex + 1].startPrice > s.kLineDay[limitUpIndex + 1].endPrice
                && s.kLineDay[limitUpIndex + 2].startPrice < s.kLineDay[limitUpIndex + 2].endPrice)
            {
                try
                {
                    DBHelper.InsertData("alert_traffic_light", new string[,] { {"gid", "varchar", s.gid.Trim() },
                        {"alert_date", "datetime", s.kLineDay[limitUpIndex + 2].endDateTime.ToShortDateString() } });
                }
                catch
                {

                }
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

