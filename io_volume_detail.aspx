<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public string gid = "sh600031";

    public Stock s;

    public static Core.RedisClient rc = new Core.RedisClient("52.81.252.140");

    protected void Page_Load(object sender, EventArgs e)
    {
        gid = Util.GetSafeRequestValue(Request, "gid", "sh600031");
        if (gid.StartsWith("60"))
        {
            gid = "sh" + gid.Trim();
        }
        if (gid.StartsWith("20") || gid.StartsWith("30") || gid.StartsWith("00"))
        {
            gid = "sz" + gid.Trim();
        }
        s = new Stock(gid);
        if (!IsPostBack)
        {
            DateTime currentDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", DateTime.Now.ToShortDateString()));
            if (currentDate.Year < 2010)
            {
                currentDate = DateTime.Now;
            }
            calendar.SelectedDate = currentDate;
            dg.DataSource = GetData(currentDate);
            dg.DataBind();
        }

    }

    public DataTable GetData(DateTime currentDate)
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("时间");
        dt.Columns.Add("盘比");
        dt.Columns.Add("价格");
        if (Util.IsTransacDay(currentDate))
        {
            Core.Timeline[] timelineArray;// = Core.Timeline.LoadTimelineArrayFromRedis(gid, currentDate, rc);
            if (currentDate == DateTime.Now.Date)
            {
                timelineArray = Core.Timeline.LoadTimelineArrayFromRedis(gid, currentDate, rc);
            }
            else
            {
                timelineArray = Core.Timeline.LoadTimelineArrayFromSqlServer(gid, currentDate);
            }
            DataTable dtOri = DBHelper.GetDataTable(" select * from io_volume where gid = '" + gid.Trim() + "' and trans_date_time > '" + currentDate.Date.ToShortDateString()
                + "' and trans_date_time < '" + currentDate.Date.ToShortDateString() + " 23:00' order by trans_date_time ");
            int i = 0;
            foreach (DataRow drOri in dtOri.Rows)
            {
                DataRow dr = dt.NewRow();
                dr["时间"] = DateTime.Parse(drOri["trans_date_time"].ToString()).ToShortTimeString();
                dr["盘比"] = Math.Round(100*(double.Parse(drOri["out_volume"].ToString()) - double.Parse(drOri["in_volume"].ToString())) / double.Parse(drOri["in_volume"].ToString()), 2);
                double currentPrice = 0;
                for (; i < timelineArray.Length; i++)
                {
                    if (timelineArray[i].tickTime > DateTime.Parse(drOri["trans_date_time"].ToString()))
                    {
                        i--;
                        currentPrice = timelineArray[i].todayEndPrice;
                        break;
                    }
                }
                dr["价格"] = currentPrice;
                dt.Rows.Add(dr);
            }
        }

        return dt;
    }

    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {
        dg.DataSource = GetData(calendar.SelectedDate);
        dg.DataBind();
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
    <%=s.gid%> <%=s.Name.Trim() %>
    </div>
    <div>

        <asp:Calendar runat="server" id="calendar" Width="100%" OnSelectionChanged="calendar_SelectionChanged" BackColor="White" BorderColor="Black" BorderStyle="Solid" CellSpacing="1" Font-Names="Verdana" Font-Size="9pt" ForeColor="Black" Height="250px" NextPrevFormat="ShortMonth" >
                    <DayHeaderStyle Font-Bold="True" Font-Size="8pt" ForeColor="#333333" Height="8pt" />
                    <DayStyle BackColor="#CCCCCC" />
                    <NextPrevStyle Font-Bold="True" Font-Size="8pt" ForeColor="White" />
                    <OtherMonthDayStyle ForeColor="#999999" />
                    <SelectedDayStyle BackColor="#333399" ForeColor="White" />
                    <TitleStyle BackColor="#333399" BorderStyle="Solid" Font-Bold="True" Font-Size="12pt" ForeColor="White" Height="12pt" />
                    <TodayDayStyle BackColor="#999999" ForeColor="White" />
                    </asp:Calendar>

    </div>
    <div>
        <asp:DataGrid ID="dg" runat="server" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" Width="100%" >
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
