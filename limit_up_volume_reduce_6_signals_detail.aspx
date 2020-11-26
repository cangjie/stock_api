<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("52.81.252.140");

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            DateTime start = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", DateTime.Now.Date.ToShortDateString()));
            DateTime end = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", DateTime.Now.Date.ToShortDateString()));
            calendar.SelectedDate = start;
            GetData();
        }
    }

    public void GetData()
    {
        string type = Util.GetSafeRequestValue(Request, "type", "");
        LimitUpVolumeReduce l = new LimitUpVolumeReduce();
        DataTable dtOri = l.GetAllSignalList(calendar.SelectedDate, calendar.SelectedDate);
        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("信号");
        dt.Columns.Add("缩量");
        dt.Columns.Add("买入");
        for (int i = 1; i <= 5; i++)
        {
            dt.Columns.Add(i.ToString() + "日");
        }
        dt.Columns.Add("总计");
        foreach (DataRow drOri in dtOri.Rows)
        {
            bool valid = false;
            switch (type.Trim())
            {
                case "F3":
                    if (drOri["信号"].ToString().Trim().IndexOf("F3") >= 0)
                    {
                        valid = true;
                    }
                    break;
                case "F5":
                    if (drOri["信号"].ToString().Trim().IndexOf("F5") >= 0)
                    {
                        valid = true;
                    }
                    break;
                case "3线":
                    if (drOri["信号"].ToString().Trim().IndexOf("3⃣️") >= 0)
                    {
                        valid = true;
                    }
                    break;
                case "新高":
                    if (drOri["信号"].ToString().Trim().IndexOf("📈") >= 0)
                    {
                        valid = true;
                    }
                    break;
                case "连板":
                    if (drOri["信号"].ToString().Trim().IndexOf("🚩") >= 0)
                    {
                        valid = true;
                    }
                    break;
                case "马头":
                    if (drOri["信号"].ToString().Trim().IndexOf("🐴") >= 0)
                    {
                        valid = true;
                    }
                    break;
                default:
                    valid = true;
                    break;
            }
            if (valid)
            {
                DataRow dr = dt.NewRow();
                dr["日期"] = DateTime.Parse(drOri["日期"].ToString()).ToShortDateString();
                dr["代码"] = drOri["代码"].ToString();
                dr["名称"] = drOri["名称"].ToString();
                dr["缩量"] = drOri["缩量"].ToString();
                if (type.Trim().Equals("新高"))
                {
                    Stock s = new Stock(drOri["代码"].ToString());
                    s.LoadKLineDay(rc);
                    int currentIndex = s.GetItemIndex((DateTime)drOri["日期"]);
                    if (currentIndex < 1)
                    {
                        continue;
                    }
                    if (s.kLineDay[currentIndex].endPrice > s.kLineDay[currentIndex - 1].highestPrice)
                    {
                        dr["信号"] = drOri["信号"].ToString();
                    }
                    else
                    {
                        dr["信号"] = "";
                    }
                }
                else
                { 
                    dr["信号"] = drOri["信号"].ToString();
                }

                dr["买入"] = Math.Round(double.Parse(drOri["买入"].ToString()), 2).ToString();

                for (int i = 1; i <= 5; i++)
                {

                    double rate = (double)drOri[i.ToString() + "日"];

                    if (rate == double.MinValue)
                    {
                        dr[i.ToString() + "日"] = "<font color=\"gray\" >--</font>";
                    }
                    else
                    {
                        if (rate >= 0.01)
                        {
                            dr[i.ToString() + "日"] = "<font color=\"orange\" >" + Math.Round(100 * rate, 2).ToString() + "%</font>";
                            if (rate >= 0.05)
                            {
                                dr[i.ToString() + "日"] = "<font color=\"red\" >" + Math.Round(100 * rate, 2).ToString() + "%</font>";
                            }
                        }
                        else
                        {
                            dr[i.ToString() + "日"] = "<font color=\"green\" >" + Math.Round(100 * rate, 2).ToString() + "%</font>";
                        }
                    }
                }
                double totalRate = (double)drOri["总计"];
                if (totalRate == double.MinValue)
                {
                    dr["总计"] = "<font color=\"gray\" >--</font>";
                }
                else
                {
                    if (totalRate >= 0.01)
                    {
                        dr["总计"] = "<font color=\"orange\" >" + Math.Round(100 * totalRate, 2).ToString() + "%</font>";
                        if (totalRate >= 0.05)
                        {
                            dr["总计"] = "<font color=\"red\" >" + Math.Round(100 * totalRate, 2).ToString() + "%</font>";
                        }
                    }
                    else
                    {
                        dr["总计"] = "<font color=\"green\" >" + Math.Round(100 * totalRate, 2).ToString() + "%</font>";
                    }

                }
                dt.Rows.Add(dr);
            }
        }


        dg.DataSource = dt;
        dg.DataBind();
    }

    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {
        GetData();
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
        <div>
            <table style="width:100%" >
                <tr>
                    <td>
                        <asp:Calendar runat="server" id="calendar" Width="100%" OnSelectionChanged="calendar_SelectionChanged" BackColor="White" BorderColor="Black" BorderStyle="Solid" CellSpacing="1" Font-Names="Verdana" Font-Size="9pt" ForeColor="Black" Height="250px" NextPrevFormat="ShortMonth" >
                            <DayHeaderStyle Font-Bold="True" Font-Size="8pt" ForeColor="#333333" Height="8pt" />
                            <DayStyle BackColor="#CCCCCC" />
                            <NextPrevStyle Font-Bold="True" Font-Size="8pt" ForeColor="White" />
                            <OtherMonthDayStyle ForeColor="#999999" />
                            <SelectedDayStyle BackColor="#333399" ForeColor="White" />
                            <TitleStyle BackColor="#333399" BorderStyle="Solid" Font-Bold="True" Font-Size="12pt" ForeColor="White" Height="12pt" />
                            <TodayDayStyle BackColor="#999999" ForeColor="White" />
                        </asp:Calendar>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:DataGrid runat="server" Width="100%" ID="dg" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
                            <AlternatingItemStyle BackColor="#DCDCDC" />
                            <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
                            <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
                            <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
                            <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
                            <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
                        </asp:DataGrid>
                    </td>
                </tr>
            </table>
        </div>
    </form>
</body>
</html>
