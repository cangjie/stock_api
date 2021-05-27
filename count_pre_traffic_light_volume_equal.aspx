<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {


        }
    }


    public DataTable GetData()
    {
        int volumeDiff = int.Parse(Util.GetSafeRequestValue(Request, "voldiff", "30"));
        bool needWeek = Util.GetSafeRequestValue(Request, "week", "0").Equals("1") ? true : false;
        int days = int.Parse(Util.GetSafeRequestValue(Request, "days", "10"));
        string buyPoint = Util.GetSafeRequestValue(Request, "buypoint", "settle");
        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", "2021-1-1").Trim());
        DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", "2021-6-1"));

        int totalCount = 0;
        int trafficLight = 0;
        int trafficLightPeaceCount = 0;
        int trafficLightSucCount = 0;
        int noneTrafficLightPeaceCount = 0;
        int noneTrafficLightSucCount = 0;

        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("红绿灯");
        dt.Columns.Add("买入");
        for (int i = 1; i <= days; i++)
        {
            dt.Columns.Add(i.ToString() + "日");
        }
        DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up where alert_date >= '" + startDate.ToShortDateString()
            + "' and alert_date <= '" + endDate.ToShortDateString() + "' ");
        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock s = GetStock(drOri["gid"].ToString());
            int limitUpDayIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            int limitUpWeekIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()).Date, "week");

            if (limitUpDayIndex >= s.kLineDay.Length - 1 || limitUpDayIndex < 0)
            {
                continue;
            }

            if (!s.IsLimitUp(limitUpDayIndex))
            {
                continue;
            }

            double deltaVolumeRate = 100 * (s.kLineDay[limitUpDayIndex + 1].volume - s.kLineDay[limitUpDayIndex].volume) / s.kLineDay[limitUpDayIndex].volume;
            if (Math.Abs(deltaVolumeRate) > volumeDiff)
            {
                continue;
            }



            if (s.kLineDay[limitUpDayIndex + 1].startPrice <= s.kLineDay[limitUpDayIndex + 1].endPrice)
            {
                continue;
            }

            if (limitUpDayIndex + 2 >= s.kLineDay.Length - 1)
            {
                continue;
            }
            bool isTrafficLight = false;
            if (s.kLineDay[limitUpDayIndex + 2].startPrice <= s.kLineDay[limitUpDayIndex + 2].endPrice)
            {
                isTrafficLight = true;
            }


        }


        return dt;
    }

    public  Stock GetStock(string gid)
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
            KLine.ComputeMACD(s.kLineDay);

            s.LoadKLineWeek(Util.rc);
            KLine.ComputeMACD(s.kLineWeek);
            KLine.ComputeRSV(s.kLineWeek);
            KLine.ComputeKDJ(s.kLineWeek);

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
            形成红绿灯概率：<br />
            红绿灯涨1%：红绿灯等涨5%：<br />
            非红绿灯涨1%：非红绿灯涨5%：
        </div>
        <div>
            <asp:DataGrid ID="dg" runat="server" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
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
