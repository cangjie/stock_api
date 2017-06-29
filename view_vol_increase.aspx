<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        //StockWatcher.WatchEachStock();
        if (!IsPostBack)
        {
            calendar.SelectedDate = DateTime.Parse(DateTime.Now.ToShortDateString());
            dg.DataSource = GetData();
            dg.DataBind();
        }
    }

    public DataTable GetData()
    {
        DateTime currentDate = calendar.SelectedDate;
        DataTable dt = new DataTable();
        dt.Columns.Add("时间");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("价格");
        dt.Columns.Add("1日最高");
        dt.Columns.Add("2日最高");
        dt.Columns.Add("3日最高");
        dt.Columns.Add("4日最高");
        dt.Columns.Add("5日最高");
        dt.Columns.Add("总计");

        DataTable dtOri = DBHelper.GetDataTable(" select * from volume_increase_log where (price_end - price_start)/price_start > 0.0075 and   volume_increase_time > '" + currentDate.ToShortDateString()
            + "' and volume_increase_time < '" + currentDate.AddDays(1).ToShortDateString() + "' order by volume_increase_time desc ,  (price_end - price_start)/ price_start desc ");

        int[] redCount = new int[5];
        int maxCount = 0;
        foreach (DataRow drOri in dtOri.Rows)
        {
            DataRow dr = dt.NewRow();
            dr["时间"] = DateTime.Parse(drOri["volume_increase_time"].ToString()).ToShortTimeString();
            dr["代码"] = drOri["gid"].ToString();
            Stock s = new Stock(drOri["gid"].ToString());
            dr["名称"] = s.Name;
            double byPrice = Math.Round(double.Parse(drOri["price_end"].ToString().Trim()), 2);
            dr["价格"] = byPrice.ToString();
            if (currentDate < DateTime.Parse(DateTime.Now.ToShortDateString()))
                s.kArr = KLine.GetKLine("day", s.gid, currentDate, DateTime.Parse(DateTime.Now.ToShortDateString()));
            int currentDateIndex = s.GetKLineIndexForADay(currentDate);
            //if (currentDateIndex < 0)
            //    continue;
            double maxHiprice = 0;
            for (int i = 0; i < 5; i++)
            {
                if (currentDate < DateTime.Parse(DateTime.Now.ToShortDateString()) && currentDateIndex + i + 1 < s.kArr.Length)
                {
                    double hiPrice = s.kArr[currentDateIndex + i + 1].highestPrice;
                    maxHiprice = Math.Max(maxHiprice, hiPrice);
                    dr[(i + 1).ToString() + "日最高"] =
                        (((hiPrice - byPrice)/byPrice > 0.01) ? "<font color='red' >" + Math.Round(100*hiPrice/byPrice, 2).ToString()+"%" + "</font>"
                        : "<font color='green' >" +  Math.Round(100*hiPrice/byPrice, 2).ToString()+"%" + "</font>") ;
                    if (dr[(i + 1).ToString() + "日最高"].ToString().IndexOf("red") >= 0)
                        redCount[i]++;
                }
                else
                {
                    dr[(i + 1).ToString() + "日最高"] = "-";
                }
            }
            dr["总计"] = (((maxHiprice - byPrice)/byPrice > 0.01) ? "<font color='red' >" + Math.Round(100*maxHiprice/byPrice, 2).ToString()+"%" + "</font>"
                        : "<font color='green' >" +  Math.Round(100*maxHiprice/byPrice, 2).ToString()+"%" + "</font>") ;
            if (dr["总计"].ToString().IndexOf("red") >= 0)
                maxCount++;
            dt.Rows.Add(dr);
        }

        DataRow drCount = dt.NewRow();
        for (int i = 0; i < 5; i++)
        {
            drCount[(i + 1).ToString() + "日最高"] = Math.Round((double)redCount[i] * 100 / (double)dt.Rows.Count, 2).ToString() + "%";
        }
        drCount["总计"] = Math.Round((double)maxCount * 100 / (double)dt.Rows.Count, 2).ToString() + "%";
        dt.Rows.Add(drCount);
        return dt;
    }




    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {
        dg.DataSource = GetData();
        dg.DataBind();
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
        <table style="width:100%" >
            <tr>
                <td><asp:Calendar ID="calendar" runat="server" BackColor="White" BorderColor="Black" BorderStyle="Solid" CellSpacing="1" Font-Names="Verdana" Font-Size="9pt" ForeColor="Black" Height="250px" NextPrevFormat="ShortMonth" Width="100%" OnSelectionChanged="calendar_SelectionChanged" >
                    <DayHeaderStyle Font-Bold="True" Font-Size="8pt" ForeColor="#333333" Height="8pt" />
                    <DayStyle BackColor="#CCCCCC" />
                    <NextPrevStyle Font-Bold="True" Font-Size="8pt" ForeColor="White" />
                    <OtherMonthDayStyle ForeColor="#999999" />
                    <SelectedDayStyle BackColor="#333399" ForeColor="White" />
                    <TitleStyle BackColor="#333399" BorderStyle="Solid" Font-Bold="True" Font-Size="12pt" ForeColor="White" Height="12pt" />
                    <TodayDayStyle BackColor="#999999" ForeColor="White" />
                    </asp:Calendar></td>
            </tr>
            <tr>
                <td><asp:DataGrid ID="dg" runat="server" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" Width="100%" >
                    <AlternatingItemStyle BackColor="#DCDCDC" />
                    <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
                    <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
                    <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
                    <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
                    <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
                    </asp:DataGrid></td>
            </tr>
        </table>

    </form>
</body>
</html>
