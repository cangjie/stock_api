<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">



    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            dg.DataSource = GetData(DateTime.Now);
            dg.DataBind();
        }
    }

    public DataTable GetData(DateTime currentDate)
    {
        int totalLimNum = 5;
        DataTable dtLimitUp = DBHelper.GetDataTable(" select * from limit_up where alert_date = '" + currentDate.ToShortDateString() + "' ");

        DataTable dt = new DataTable();
        dt.Columns.Add("板数");
        dt.Columns.Add("数量");
        dt.Columns.Add("连板数");
        dt.Columns.Add("连板率");

        for (int i = 2; i <= totalLimNum; i++)
        {
            DataRow dr = dt.NewRow();
            dr["板数"] = i.ToString();
            dr["数量"] = 0;
            dr["连板数"] = 0;
            dr["连板率"] = "0";
            dt.Rows.Add(dr);
        }

        DataRow drVolEqual = dt.NewRow();
        drVolEqual["板数"] = "2板平量";
        drVolEqual["数量"] = "0";
        drVolEqual["连板数"] = "0";
        drVolEqual["连板率"] = "0";
        dt.Rows.Add(drVolEqual);

        foreach (DataRow drLimitUp in dtLimitUp.Rows)
        {
            Stock s = new Stock(drLimitUp["gid"].ToString().Trim());
            s.LoadKLineDay(Util.rc);
            int currentIndex = s.GetItemIndex(currentDate);
            if (currentIndex >= s.kLineDay.Length - 1 || currentIndex - totalLimNum <= 0)
            {
                continue;
            }
            int limitUp = 0;
            for (int i = currentIndex; i >= currentIndex - totalLimNum ; i--)
            {
                if (s.IsLimitUp(i))
                {
                    limitUp++;
                }
                else
                {
                    break;
                }
            }
            if (limitUp <= 1 || limitUp > totalLimNum)
            {
                continue;
            }
            if (limitUp > 1 && (  Math.Abs(s.kLineDay[currentIndex].volume - s.kLineDay[currentIndex - 1].volume) / s.kLineDay[currentIndex - 1].volume < 0.1  ))
            {
                int numV = int.Parse(dt.Rows[dt.Rows.Count - 1]["数量"].ToString());
                int sucV = int.Parse(dt.Rows[dt.Rows.Count - 1]["连板数"].ToString());
                numV++;
                dt.Rows[dt.Rows.Count - 1]["数量"] = numV.ToString();
                if (s.IsLimitUp(currentIndex + 1))
                {
                    sucV++;
                }
                dt.Rows[dt.Rows.Count - 1]["连板数"] = sucV.ToString();
            }
            int num = 0;
            int suc = 0;
            switch (limitUp)
            {
                case 2:
                    num = int.Parse(dt.Rows[0]["数量"].ToString().Trim());
                    num++;
                    suc = int.Parse(dt.Rows[0]["连板数"].ToString().Trim());
                    if (currentIndex < s.kLineDay.Length - 1)
                    {
                        if (s.IsLimitUp(currentIndex + 1))
                        {
                            suc++;
                        }
                    }
                    dt.Rows[0]["数量"] = num.ToString();
                    dt.Rows[0]["连板数"] = suc.ToString();
                    break;
                case 3:
                    num = int.Parse(dt.Rows[1]["数量"].ToString().Trim());
                    num++;
                    suc = int.Parse(dt.Rows[1]["连板数"].ToString().Trim());
                    if (currentIndex < s.kLineDay.Length - 1)
                    {
                        if (s.IsLimitUp(currentIndex + 1))
                        {
                            suc++;
                        }
                    }
                    dt.Rows[1]["数量"] = num.ToString();
                    dt.Rows[1]["连板数"] = suc.ToString();
                    break;
                case 4:
                    num = int.Parse(dt.Rows[2]["数量"].ToString().Trim());
                    num++;
                    suc = int.Parse(dt.Rows[2]["连板数"].ToString().Trim());
                    if (currentIndex < s.kLineDay.Length - 1)
                    {
                        if (s.IsLimitUp(currentIndex + 1))
                        {
                            suc++;
                        }
                    }
                    dt.Rows[2]["数量"] = num.ToString();
                    dt.Rows[2]["连板数"] = suc.ToString();
                    break;
                case 5:
                    num = int.Parse(dt.Rows[3]["数量"].ToString().Trim());
                    num++;
                    suc = int.Parse(dt.Rows[3]["连板数"].ToString().Trim());
                    if (currentIndex < s.kLineDay.Length - 1)
                    {
                        if (s.IsLimitUp(currentIndex + 1))
                        {
                            suc++;
                        }
                    }
                    dt.Rows[3]["数量"] = num.ToString();
                    dt.Rows[3]["连板数"] = suc.ToString();
                    break;
                default:
                    break;
            }
        }
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            int num = int.Parse(dt.Rows[i]["数量"].ToString());
            int suc = int.Parse(dt.Rows[i]["连板数"].ToString());
            if (num > 0)
            {
                dt.Rows[i]["连板率"] = Math.Round(100 * (double)suc / (double)num, 2).ToString() + "%";
            }
        }
        return dt;
    }



    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {

        DataTable dt = GetData(calendar.SelectedDate.Date);
        dg.DataSource = dt;
        dg.DataBind();
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>N连扳概率</title>
</head>
<body>
    <form id="form1" runat="server">
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
                <asp:DataGrid runat="server" id="dg" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
                <AlternatingItemStyle BackColor="#DCDCDC" />
                <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
                <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
                <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
                <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
                <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
                </asp:DataGrid>
            </tr>
        </table>
    </form>
</body>
</html>
