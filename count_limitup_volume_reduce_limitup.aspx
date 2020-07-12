<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    public static int highCount = 0;

    public static int highSuccess = 0;

    public static int lowCount = 0;

    public static int lowSuccess = 0;

    protected void Page_Load(object sender, EventArgs e)
    {

      

        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.DateTime"));
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("缩量");
        dt.Columns.Add("再次涨停天数");

        DataTable dtNew = new DataTable();
        dtNew.Columns.Add("日期");
        dtNew.Columns.Add("代码");
        dtNew.Columns.Add("名称");
        dtNew.Columns.Add("缩量");
        dtNew.Columns.Add("再次涨停天数");



        DataTable dtOri = DBHelper.GetDataTable(" select  alert_date, gid from limit_up a "
            + " where exists (select 'a' from limit_up b where a.gid = b.gid  "
            + " and dbo.func_GetLastTransactDate(a.alert_date, 16) <= b.alert_date  "
            + " and b.alert_date <= dbo.func_GetLastTransactDate(a.alert_date, 2) ) and a.alert_date >= '2020-1-1' ");
        foreach (DataRow drOri in dtOri.Rows)
        {
            try
            {
                Stock s = GetStock(drOri["gid"].ToString().Trim());
                int currentIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
                if (currentIndex < 0)
                {
                    continue;
                }
                int prevLimitUpVolumeReduceIndex = 0;
                for (int i = currentIndex - 2; i >= currentIndex - 16; i--)
                {
                    if (s.IsLimitUp(i) && s.kLineDay[i].volume > s.kLineDay[i + 1].volume && !s.IsLimitUp(i + 1))
                    {
                        prevLimitUpVolumeReduceIndex = i;
                        break;
                    }
                }
                if (prevLimitUpVolumeReduceIndex > 0 
                    && dt.Select(" 日期 = '" + s.kLineDay[prevLimitUpVolumeReduceIndex].startDateTime.Date.ToShortDateString() + "' and 代码 = '" + s.gid.Trim() + "' ").Length == 0)
                {
                    DataRow dr = dt.NewRow();
                    dr["日期"] = s.kLineDay[prevLimitUpVolumeReduceIndex].startDateTime.Date;
                    dr["代码"] = s.gid.Trim();
                    dr["名称"] = s.Name.Trim();
                    dr["缩量"] = Math.Round(100 * s.kLineDay[prevLimitUpVolumeReduceIndex + 1].volume / s.kLineDay[prevLimitUpVolumeReduceIndex].volume, 2).ToString() + "%";
                    int reLimitUpDays = 0;
                    for (int i = prevLimitUpVolumeReduceIndex + 2; i <= currentIndex; i++)
                    {
                        if (s.IsLimitUp(i))
                        {
                            break;
                        }
                        else
                        {
                            reLimitUpDays++;
                        }
                    }
                    dr["再次涨停天数"] = (1+reLimitUpDays).ToString();
                    dt.Rows.Add(dr);
                }
            }
            catch
            {

            }
        }



        //DataTable dtNew = dt.Clone();
        foreach (DataRow dr in dt.Select("", "日期 desc"))
        {
            DataRow drNew = dtNew.NewRow();
            foreach (DataColumn c in dt.Columns)
            {
                drNew[c.Caption] = dr[c].ToString();
            }
            drNew["日期"] = ((DateTime)dr["日期"]).ToShortDateString();


            dtNew.Rows.Add(drNew);
        }


        dg.DataSource = dtNew;
        dg.DataBind();

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

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <asp:DataGrid runat="server" Width="100%" ID="dg" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
            <AlternatingItemStyle BackColor="#DCDCDC" />
            <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
            <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
            <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
            <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
            <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
        </asp:DataGrid>
    </div>
    </form>
</body>
</html>
