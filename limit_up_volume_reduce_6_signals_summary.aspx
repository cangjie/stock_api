<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public int line3Count2 = 0;
    public int line3Suc2 = 0;
    public int line3Suc2Great = 0;
    public int line3Count5 = 0;
    public int line3Suc5 = 0;
    public int line3Suc5Great = 0;

    public int f3Count2 = 0;
    public int f3Suc2 = 0;
    public int f3Suc2Great = 0;
    public int f3Count5 = 0;
    public int f3Suc5 = 0;
    public int f3Suc5Great = 0;

    public int f5Count2 = 0;
    public int f5Suc2 = 0;
    public int f5Suc2Great = 0;
    public int f5Count5 = 0;
    public int f5Suc5 = 0;
    public int f5Suc5Great = 0;

    public int horseCount2 = 0;
    public int horseSuc2 = 0;
    public int horseSuc2Great = 0;
    public int horseCount5 = 0;
    public int horseSuc5 = 0;
    public int horseSuc5Great = 0;

    public int highCount2 = 0;
    public int highSuc2 = 0;
    public int highSuc2Great = 0;
    public int highCount5 = 0;
    public int highSuc5 = 0;
    public int highSuc5Great = 0;

    public int limitUp2Count2 = 0;
    public int limitUp2Suc2 = 0;
    public int limitUp2Suc2Great = 0;
    public int limitUp2Count5 = 0;
    public int limitUp2Suc5 = 0;
    public int limitUp2Suc5Great = 0;

    public DateTime currentDate = DateTime.Now.Date;

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        { 
            GetData();
        }
    }

    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {
        currentDate = calendar.SelectedDate.Date;
        GetData();
    }

    public void GetData()
    {
        LimitUpVolumeReduce l = new LimitUpVolumeReduce();
        DataTable dt = l.GetAllSignalList(currentDate, currentDate);
        foreach (DataRow dr in dt.Rows)
        {
            if ((double)dr["1日"] > double.MinValue)
            {
                if (dr["信号"].ToString().IndexOf("3⃣️") >= 0)
                {
                    line3Count2++;
                    if ((double)dr["1日"] >= 0.01)
                    {
                        line3Suc2++;
                        if ((double)dr["1日"] >= 0.05)
                        {
                            line3Suc2Great++;
                        }
                    }
                }

                if (dr["信号"].ToString().IndexOf("F3") >= 0)
                {
                    f3Count2++;
                    if ((double)dr["1日"] >= 0.01)
                    {
                        f3Suc2++;
                        if ((double)dr["1日"] >= 0.05)
                        {
                            f3Suc2Great++;
                        }
                    }
                }

                if (dr["信号"].ToString().IndexOf("F5") >= 0)
                {
                    f5Count2++;
                    if ((double)dr["1日"] >= 0.01)
                    {
                        f5Suc2++;
                        if ((double)dr["1日"] >= 0.05)
                        {
                            f5Suc2Great++;
                        }
                    }
                }

                if (dr["信号"].ToString().IndexOf("🐴") >= 0)
                {
                    horseCount2++;
                    if ((double)dr["1日"] >= 0.01)
                    {
                        horseSuc2++;
                        if ((double)dr["1日"] >= 0.05)
                        {
                            horseSuc2Great++;
                        }
                    }
                }

                if (dr["信号"].ToString().IndexOf("📈") >= 0)
                {
                    highCount2++;
                    if ((double)dr["1日"] >= 0.01)
                    {
                        highSuc2++;
                        if ((double)dr["1日"] >= 0.05)
                        {
                            highSuc2Great++;
                        }
                    }
                }

                if (dr["信号"].ToString().IndexOf("🚩") >= 0)
                {
                    limitUp2Count2++;
                    if ((double)dr["1日"] >= 0.01)
                    {
                        limitUp2Suc2++;
                        if ((double)dr["1日"] >= 0.05)
                        {
                            limitUp2Suc2Great++;
                        }
                    }
                }



            }
            if ((double)dr["总计"] > double.MinValue)
            {
                if (dr["信号"].ToString().IndexOf("3⃣️") >= 0)
                {
                    line3Count5++;
                    if ((double)dr["总计"] >= 0.01)
                    {
                        line3Suc5++;
                        if ((double)dr["总计"] >= 0.05)
                        {
                            line3Suc5Great++;
                        }
                    }
                }

                if (dr["信号"].ToString().IndexOf("F3") >= 0)
                {
                    f3Count5++;
                    if ((double)dr["总计"] >= 0.01)
                    {
                        f3Suc5++;
                        if ((double)dr["总计"] >= 0.05)
                        {
                            f3Suc5Great++;
                        }
                    }
                }

                if (dr["信号"].ToString().IndexOf("F5") >= 0)
                {
                    f5Count5++;
                    if ((double)dr["总计"] >= 0.01)
                    {
                        f5Suc5++;
                        if ((double)dr["总计"] >= 0.05)
                        {
                            f5Suc5Great++;
                        }
                    }
                }

                if (dr["信号"].ToString().IndexOf("🐴") >= 0)
                {
                    horseCount5++;
                    if ((double)dr["总计"] >= 0.01)
                    {
                        horseSuc5++;
                        if ((double)dr["总计"] >= 0.05)
                        {
                            horseSuc5Great++;
                        }
                    }
                }

                if (dr["信号"].ToString().IndexOf("📈") >= 0)
                {
                    highCount5++;
                    if ((double)dr["总计"] >= 0.01)
                    {
                        highSuc5++;
                        if ((double)dr["总计"] >= 0.05)
                        {
                            highSuc5Great++;
                        }
                    }
                }

                if (dr["信号"].ToString().IndexOf("🚩") >= 0)
                {
                    limitUp2Count5++;
                    if ((double)dr["总计"] >= 0.01)
                    {
                        limitUp2Suc5++;
                        if ((double)dr["总计"] >= 0.05)
                        {
                            limitUp2Suc5Great++;
                        }
                    }
                }
            }
        }
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
                        <table style="width:100%;" border="1" >
                            <tr>
                                <td> </td>
                                <td colspan="2">1日</td>
                                <td colspan="2">5日</td>
                            </tr>
                            <tr>
                                <td> </td>
                                <td>1%</td>
                                <td>5%</td>
                                <td>1%</td>
                                <td>5%</td>
                            </tr>
                            <tr>
                                <td><a href="limit_up_volume_reduce_6_signals_detail.aspx?type=<%=Server.UrlEncode("3线") %>&start=<%=Server.UrlEncode(currentDate.ToShortDateString()) %>&end=<%=Server.UrlEncode(currentDate.ToShortDateString()) %>" target="_blank" >3线</a></td>
                                <td><%= (line3Count2==0?"--":(Math.Round(100 * (double)line3Suc2 / line3Count2, 2).ToString()+"%")) %></td>
                                <td><%= (line3Count2==0?"--":(Math.Round(100 * (double)line3Suc2Great / line3Count2, 2).ToString()+"%")) %></td>
                                <td><%= (line3Count5==0?"--":(Math.Round(100 * (double)line3Suc5 / line3Count5, 2).ToString()+"%")) %></td>
                                <td><%= (line3Count5==0?"--":(Math.Round(100 * (double)line3Suc5Great / line3Count5, 2).ToString()+"%")) %></td>
                            </tr>
                            <tr>
                                <td><a href="limit_up_volume_reduce_6_signals_detail.aspx?type=<%=Server.UrlEncode("F3") %>&start=<%=Server.UrlEncode(currentDate.ToShortDateString()) %>&end=<%=Server.UrlEncode(currentDate.ToShortDateString()) %>" target="_blank" >F3</a></td>
                                <td><%= (f3Count2==0?"--":(Math.Round(100 * (double)f3Suc2 / f3Count2, 2).ToString()+"%")) %></td>
                                <td><%= (f3Count2==0?"--":(Math.Round(100 * (double)f3Suc2Great / f3Count2, 2).ToString()+"%")) %></td>
                                <td><%= (f3Count5==0?"--":(Math.Round(100 * (double)f3Suc5 / f3Count5, 2).ToString()+"%")) %></td>
                                <td><%= (f3Count5==0?"--":(Math.Round(100 * (double)f3Suc5Great / f3Count5, 2).ToString()+"%")) %></td>
                            </tr>
                            <tr>
                                <td><a href="limit_up_volume_reduce_6_signals_detail.aspx?type=<%=Server.UrlEncode("F5") %>&start=<%=Server.UrlEncode(currentDate.ToShortDateString()) %>&end=<%=Server.UrlEncode(currentDate.ToShortDateString()) %>" target="_blank" >F5</a></td>
                                <td><%= (f5Count2==0?"--":(Math.Round(100 * (double)f5Suc2 / f5Count2, 2).ToString()+"%")) %></td>
                                <td><%= (f5Count2==0?"--":(Math.Round(100 * (double)f5Suc2Great / f5Count2, 2).ToString()+"%")) %></td>
                                <td><%= (f5Count5==0?"--":(Math.Round(100 * (double)f5Suc5 / f5Count5, 2).ToString()+"%")) %></td>
                                <td><%= (f5Count5==0?"--":(Math.Round(100 * (double)f5Suc5Great / f5Count5, 2).ToString()+"%")) %></td>
                            </tr>
                            <tr>
                                <td><a href="limit_up_volume_reduce_6_signals_detail.aspx?type=<%=Server.UrlEncode("新高") %>&start=<%=Server.UrlEncode(currentDate.ToShortDateString()) %>&end=<%=Server.UrlEncode(currentDate.ToShortDateString()) %>" target="_blank" >新高</a></td>
                                <td><%= (highCount2==0?"--":(Math.Round(100 * (double)highSuc2 / highCount2, 2).ToString()+"%")) %></td>
                                <td><%= (highCount2==0?"--":(Math.Round(100 * (double)highSuc2Great / highCount2, 2).ToString()+"%")) %></td>
                                <td><%= (highCount5==0?"--":(Math.Round(100 * (double)highSuc5 / highCount5, 2).ToString()+"%")) %></td>
                                <td><%= (highCount5==0?"--":(Math.Round(100 * (double)highSuc5Great / highCount5, 2).ToString()+"%")) %></td>
                            </tr>
                            <tr>
                                <td><a href="limit_up_volume_reduce_6_signals_detail.aspx?type=<%=Server.UrlEncode("马头") %>&start=<%=Server.UrlEncode(currentDate.ToShortDateString()) %>&end=<%=Server.UrlEncode(currentDate.ToShortDateString()) %>" target="_blank" >马头</a></td>
                                <td><%= (horseCount2==0?"--":(Math.Round(100 * (double)horseSuc2 / horseCount2, 2).ToString()+"%")) %></td>
                                <td><%= (horseCount2==0?"--":(Math.Round(100 * (double)horseSuc2Great / horseCount2, 2).ToString()+"%")) %></td>
                                <td><%= (horseCount5==0?"--":(Math.Round(100 * (double)horseSuc5 / horseCount5, 2).ToString()+"%")) %></td>
                                <td><%= (horseCount5==0?"--":(Math.Round(100 * (double)horseSuc5Great / horseCount5, 2).ToString()+"%")) %></td>
                            </tr>
                            <tr>
                                <td><a href="limit_up_volume_reduce_6_signals_detail.aspx?type=<%=Server.UrlEncode("连板") %>&start=<%=Server.UrlEncode(currentDate.ToShortDateString()) %>&end=<%=Server.UrlEncode(currentDate.ToShortDateString()) %>" target="_blank" >连板</a></td>
                                <td><%= (limitUp2Count2==0?"--":(Math.Round(100 * (double)limitUp2Suc2 / limitUp2Count2, 2).ToString()+"%")) %></td>
                                <td><%= (limitUp2Count2==0?"--":(Math.Round(100 * (double)limitUp2Suc2Great / limitUp2Count2, 2).ToString()+"%")) %></td>
                                <td><%= (limitUp2Count5==0?"--":(Math.Round(100 * (double)limitUp2Suc5 / limitUp2Count5, 2).ToString()+"%")) %></td>
                                <td><%= (limitUp2Count5==0?"--":(Math.Round(100 * (double)limitUp2Suc5Great / limitUp2Count5, 2).ToString()+"%")) %></td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </table>
        </div>
    </form>
</body>
</html>
