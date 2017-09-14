<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Text" %>
<!DOCTYPE html>

<script runat="server">

    public DateTime currentDate = DateTime.Parse(DateTime.Now.ToShortDateString());

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            dg.DataSource = GetData();
            dg.DataBind();
        }
    }

    public DataTable GetData()
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("信号");
        dt.Columns.Add("调整天数");
        dt.Columns.Add("缩量");
        dt.Columns.Add("涨停开");
        dt.Columns.Add("涨停收");
        dt.Columns.Add("现价");
        dt.Columns.Add("1日");
        dt.Columns.Add("2日");
        dt.Columns.Add("3日");
        dt.Columns.Add("4日");
        dt.Columns.Add("5日");
        dt.Columns.Add("总计");
        DataTable dtOri = DBHelper.GetDataTable(" select * from cross_star_list where alert_date = '" + currentDate.ToShortDateString() + "' order by limit_up_date desc " );
        for (int i = 0; i < dtOri.Rows.Count; i++)
        {
            if (dt.Select(" 代码 = '" + dtOri.Rows[i]["gid"].ToString().Trim() + "' ").Length == 0)
            {
                DataRow dr = dt.NewRow();
                Stock stock = new Stock(dtOri.Rows[i]["gid"].ToString().Trim());
                stock.LoadKLineDay();

                dr["代码"] = stock.gid.Trim();
                dr["名称"] = stock.Name.Trim();
                dr["信号"] = "";
                int currentIndex = stock.GetItemIndex(currentDate);
                int limitUpIndex = stock.GetItemIndex(DateTime.Parse(dtOri.Rows[i]["limit_up_date"].ToString()));
                if (currentIndex <= 0
                    || (stock.kLineDay[currentIndex].endPrice - stock.kLineDay[currentIndex - 1].endPrice) / stock.kLineDay[currentIndex - 1].endPrice > 0.095)
                    continue;
                dr["调整天数"] = (currentIndex - limitUpIndex).ToString();
                double currentVolume = stock.kLineDay[currentIndex].volume;
                double limitUpVolume = LimitUp.GetEffectMaxLimitUpVolumeBeforeACertainDate(stock, currentDate);
                dr["缩量"] = currentVolume / limitUpVolume;
                dr["涨停开"] = stock.kLineDay[limitUpIndex].startPrice.ToString();
                dr["涨停收"] = stock.kLineDay[limitUpIndex].endPrice.ToString();
                dr["现价"] = stock.kLineDay[currentIndex].endPrice.ToString();
                if (stock.kLineDay[currentIndex].endPrice >= stock.kLineDay[limitUpIndex].endPrice && stock.kLineDay[currentIndex].startPrice >= stock.kLineDay[limitUpIndex].endPrice)
                {
                    dr["信号"] = "🌟";
                }
                if ((stock.kLineDay[limitUpIndex].endPrice - stock.kLineDay[currentIndex].endPrice) / stock.kLineDay[limitUpIndex].endPrice > 0.03)
                {
                    dr["信号"] = "💩";
                }

                double maxRaiseRate = 0;
                for (int j = 1; j <= 5; j++)
                {
                    if (currentIndex + j < stock.kLineDay.Length)
                    {
                        double raiseRate = (stock.kLineDay[currentIndex + j].highestPrice - stock.kLineDay[currentIndex].endPrice) / stock.kLineDay[currentIndex].endPrice;
                        maxRaiseRate = Math.Max(maxRaiseRate, raiseRate);
                        dr[j.ToString() + "日"] = raiseRate.ToString();
                    }
                    else
                    {
                        dr[j.ToString() + "日"] = "-";
                    }
                }
                dr["总计"] = maxRaiseRate.ToString();
                dt.Rows.Add(dr);
            }
        }
        AddTotal(dt);
        RenderHtml(dt);
        return dt;
    }

    public void AddTotal(DataTable dt)
    {
        int totalCount = 0;
        int[] totalRaiseCount = new int[6] {0, 0, 0, 0, 0, 0 };
        int starCount = 0;
        int[] starRaiseCount = new int[6] {0, 0, 0, 0, 0, 0 };
        foreach (DataRow dr in dt.Rows)
        {
            if (dr["信号"].ToString().IndexOf("💩") < 0)
            {
                totalCount++;
                if (dr["信号"].ToString().IndexOf("🌟") >= 0)
                {
                    starCount++;
                }
            }
            for (int i = 1; i <= 5; i++)
            {
                if (!dr[i.ToString() + "日"].ToString().Trim().Equals("-"))
                {
                    double percent = double.Parse(dr[i.ToString() + "日"].ToString());
                    if (percent > 0.01)
                    {
                        if (dr["信号"].ToString().IndexOf("💩") < 0)
                        {
                            totalRaiseCount[i - 1]++;
                            if (dr["信号"].ToString().IndexOf("🌟") >= 0)
                            {
                                starRaiseCount[i - 1]++;
                            }
                        }
                    }
                }
            }
            double percentMax = double.Parse(dr["总计"].ToString().Trim());
            if (percentMax > 0.01)
            {
                if (dr["信号"].ToString().IndexOf("💩") < 0)
                {
                    totalRaiseCount[5]++;
                    if (dr["信号"].ToString().IndexOf("🌟") >= 0)
                    {
                        starRaiseCount[5]++;
                    }
                }
            }
        }
        DataRow drTotal = dt.NewRow();
        drTotal["信号"] = "";
        drTotal["调整天数"] = totalCount.ToString();

        DataRow drStar = dt.NewRow();
        drStar["信号"] = "🌟";
        drStar["调整天数"] = starCount.ToString();

        for (int i = 1; i <= 5; i++)
        {
            drTotal[i.ToString() + "日"] = (double)totalRaiseCount[i - 1] / (double)totalCount;
            drStar[i.ToString() + "日"] = (double)starRaiseCount[i - 1] / (double)starCount;
        }
        drTotal["总计"] = (double)totalRaiseCount[5] / (double)totalCount;
        drStar["总计"] = (double)starRaiseCount[5] / (double)starCount;
        dt.Rows.Add(drTotal);
        dt.Rows.Add(drStar);

    }

    public void RenderHtml(DataTable dt)
    {
        for (int i = 0; i < dt.Rows.Count - 2; i++)
        {
            dt.Rows[i]["代码"] = "<a href=\"show_k_line_day.aspx?gid=" + dt.Rows[i]["代码"].ToString() + "\" target=\"_blank\" >"
                + dt.Rows[i]["代码"].ToString().Trim() + "</a>";
            dt.Rows[i]["缩量"] = Math.Round(double.Parse(dt.Rows[i]["缩量"].ToString()) * 100, 2).ToString() + "%";
            dt.Rows[i]["涨停开"] = Math.Round(double.Parse(dt.Rows[i]["涨停开"].ToString()), 2).ToString();
            dt.Rows[i]["涨停收"] = Math.Round(double.Parse(dt.Rows[i]["涨停收"].ToString()), 2).ToString();
            for (int j = 1; j <= 5; j++)
            {
                if (!dt.Rows[i][j.ToString() + "日"].ToString().Trim().Equals("-"))
                {
                    double percent = double.Parse(dt.Rows[i][j.ToString() + "日"].ToString().Trim());
                    string color = "green";
                    if (percent > 0.01)
                    {
                        color = "red";
                    }
                    dt.Rows[i][j.ToString() + "日"] = "<font color=\"" + color + "\" >" + Math.Round(percent * 100, 2).ToString() + "%" + "</font>";
                }


            }
            if (!dt.Rows[i]["总计"].ToString().Trim().Equals("-"))
            {
                string totalColor = "green";
                double totalPercent = double.Parse(dt.Rows[i]["总计"].ToString().Trim());
                if (totalPercent > 0.01)
                {
                    totalColor = "red";
                }
                dt.Rows[i]["总计"] = "<font color=\"" + totalColor + "\" >" + Math.Round(totalPercent * 100, 2).ToString() + "%" + "</font>";
            }
        }
        for (int i = 1; i <= 5; i++)
        {
            if (!dt.Rows[dt.Rows.Count - 1][i.ToString() + "日"].ToString().Equals("-"))
                dt.Rows[dt.Rows.Count - 1][i.ToString() + "日"]
                    = Math.Round(double.Parse(dt.Rows[dt.Rows.Count - 1][i.ToString() + "日"].ToString()) * 100, 2).ToString() + "%";
            if (!dt.Rows[dt.Rows.Count - 2][i.ToString() + "日"].ToString().Equals("-"))
                dt.Rows[dt.Rows.Count - 2][i.ToString() + "日"]
                    = Math.Round(double.Parse(dt.Rows[dt.Rows.Count - 2][i.ToString() + "日"].ToString()) * 100, 2).ToString() + "%";
        }
        if (!dt.Rows[dt.Rows.Count - 1]["总计"].ToString().Trim().Equals("-"))
            dt.Rows[dt.Rows.Count - 1]["总计"]
                = Math.Round(double.Parse(dt.Rows[dt.Rows.Count - 1]["总计"].ToString()) * 100, 2).ToString() + "%";
        if (!dt.Rows[dt.Rows.Count - 2]["总计"].ToString().Trim().Equals("-"))
            dt.Rows[dt.Rows.Count - 2]["总计"]
                = Math.Round(double.Parse(dt.Rows[dt.Rows.Count - 2]["总计"].ToString()) * 100, 2).ToString() + "%";
    }


    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {
        currentDate = DateTime.Parse(calendar.SelectedDate.ToShortDateString());
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
    <div>
    <table width="100%" >
        <tr>
            <td><asp:Calendar runat="server" id="calendar" Width="100%" OnSelectionChanged="calendar_SelectionChanged" BackColor="White" BorderColor="Black" BorderStyle="Solid" CellSpacing="1" Font-Names="Verdana" Font-Size="9pt" ForeColor="Black" Height="250px" NextPrevFormat="ShortMonth" >
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
            <td><asp:DataGrid runat="server" ID="dg" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" Width="100%" >
                <AlternatingItemStyle BackColor="#DCDCDC" />
                <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
                <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
                <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
                <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
                <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
                </asp:DataGrid></td>
        </tr>
    </table>
    </div>
    </form>
</body>
</html>
