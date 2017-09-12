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
            dg.DataSource = AddTotal(GetData());
            dg.DataBind();
        }
    }

    public DataTable GetData()
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("涨停日");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("信号");
        dt.Columns.Add("开盘价");
        dt.Columns.Add("涨停价");
        dt.Columns.Add("涨停量");

        for (int i = 1; i <= 8; i++)
        {
            dt.Columns.Add(i.ToString() + "日");
            dt.Columns.Add(i.ToString() + "日价");
            dt.Columns.Add(i.ToString() + "日量");
            dt.Columns.Add(i.ToString() + "日涨幅");
        }

        if (Util.IsTransacDay(currentDate))
        {
            DataTable dtOri = LimitUp.GetLimitUpListBeforeADay(currentDate);
            for (int i = 0; i < dtOri.Rows.Count; i++)
            {
                Stock stock = new Stock(dtOri.Rows[i]["gid"].ToString());
                stock.LoadKLineDay();
                int upLimitIndex = stock.GetItemIndex(DateTime.Parse(dtOri.Rows[i]["alert_date"].ToString()));
                int currentIndex = stock.GetItemIndex(currentDate);
                DataRow dr = dt.NewRow();
                dr["涨停日"] = DateTime.Parse(dtOri.Rows[i]["alert_date"].ToString()).ToShortDateString();
                dr["代码"] = stock.gid.Trim();
                dr["名称"] = stock.Name.Trim();
                dr["开盘价"] = Math.Round(stock.kLineDay[upLimitIndex].startPrice, 2).ToString();
                dr["涨停价"] = Math.Round(stock.kLineDay[upLimitIndex].highestPrice, 2).ToString();
                double limitUpVolume = stock.kLineDay[upLimitIndex].volume;
                dr["涨停量"] = limitUpVolume.ToString();
                dr["信号"] = "";
                bool haveStar = false;
                bool haveShit = false;
                bool veryLow = false;

                for (int j = 1; j <= 8; j++)
                {
                    if (upLimitIndex + j < stock.kLineDay.Length)
                    {
                        if (stock.kLineDay[j + upLimitIndex].endPrice <= stock.kLineDay[upLimitIndex].startPrice)
                        {
                            veryLow = true;
                            break;
                        }

                        dr[j.ToString() + "日"] = "";
                        if (stock.kLineDay[j + upLimitIndex].IsCrossStar && stock.kLineDay[j + upLimitIndex].volume / limitUpVolume < 0.5 && j < 7)
                        {
                            dr[j.ToString() + "日"] = dr[j.ToString() + "日"] + "✝️";
                            if (stock.kLineDay[j + upLimitIndex].startPrice > stock.kLineDay[upLimitIndex].highestPrice
                                && stock.kLineDay[j + upLimitIndex].endPrice > stock.kLineDay[upLimitIndex].highestPrice)
                            {
                                haveStar = true;
                            }
                            else
                            {
                                if ((stock.kLineDay[upLimitIndex].highestPrice - stock.kLineDay[j + upLimitIndex].startPrice) / stock.kLineDay[upLimitIndex].highestPrice > 0.03)
                                {
                                    haveShit = true;
                                }
                            }
                        }
                        if ((stock.kLineDay[j + upLimitIndex].highestPrice - stock.kLineDay[j + upLimitIndex - 1].endPrice) / stock.kLineDay[j + upLimitIndex - 1].endPrice > 0.03)
                        {
                            dr[j.ToString() + "日"] = dr[j.ToString() + "日"] + "🔝";
                        }

                        dr[j.ToString() + "日价"] = Math.Round(stock.kLineDay[j + upLimitIndex].endPrice, 2).ToString();
                        dr[j.ToString() + "日量"] = Math.Round(100 * stock.kLineDay[j + upLimitIndex].volume / limitUpVolume, 2).ToString()+"%";
                        double raisePercent = Math.Round(100 * (stock.kLineDay[j + upLimitIndex].highestPrice - stock.kLineDay[j + upLimitIndex - 1].endPrice) / stock.kLineDay[j + upLimitIndex - 1].endPrice, 2);

                        dr[j.ToString() + "日涨幅"] =  "<font color=\"" + ((raisePercent>=1)? "red":"green")  + "\" >" +  raisePercent.ToString() + "%</font>";
                        //dr[j.ToString() + "日涨幅"] = raisePercent.ToString();

                    }
                }
                if (haveStar)
                {
                    dr["信号"] = dr["信号"].ToString() + "🌟";
                }
                if (haveShit)
                {
                    dr["信号"] = dr["信号"].ToString() + "💩";
                }
                if (!veryLow)
                {
                    dt.Rows.Add(dr);
                }

            }
        }




        return dt;
    }

    public DataTable AddTotal(DataTable dt)
    {
        int crossCount = 0;
        int starCrossCount = 0;
        int crossRaiseCount = 0;
        int starCrossRaiseCount = 0;

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            int firstCrossIndex = 0;
            double firstCrossPrice = 0;
            for (int j = 1; j < 8; j++)
            {
                try
                {
                    if (dt.Rows[i][j.ToString() + "日"].ToString().IndexOf("✝️") >= 0)
                    {
                        firstCrossPrice = double.Parse(dt.Rows[i][(j + 1).ToString() + "日价"].ToString());
                        firstCrossIndex = j;
                        break;
                    }
                }
                catch
                {

                }
            }

            if (firstCrossIndex > 0)
            {
                try
                {
                    double.Parse(dt.Rows[i][(firstCrossIndex + 1).ToString() + "日价"].ToString());
                }
                catch
                {
                    continue;
                }
                crossCount++;
                if (dt.Rows[i]["信号"].ToString().IndexOf("🌟") >= 0)
                {
                    starCrossCount++;
                }
                for (int j = firstCrossIndex + 1; j <= 8; j++)
                {
                    try
                    {
                        if (dt.Rows[i][j.ToString() + "日涨幅"].ToString().IndexOf("red") >= 0)
                        {
                            crossRaiseCount++;
                            if (dt.Rows[i]["信号"].ToString().IndexOf("🌟") >= 0)
                            {
                                starCrossRaiseCount++;
                            }
                            break;
                        }
                    }
                    catch
                    {

                    }
                }
            }


        }
        DataRow drCross = dt.NewRow();
        drCross[0] = "✝️";
        drCross[1] = crossRaiseCount.ToString() + "/" + crossCount.ToString();
        drCross[2] = Math.Round((double)crossRaiseCount * 100 / (double)crossCount, 2).ToString() + "%";

        dt.Rows.Add(drCross);
        DataRow drStarCross = dt.NewRow();
        drStarCross[0] = "🌟✝️";
        drStarCross[1] = starCrossRaiseCount.ToString() + "/" + starCrossCount.ToString();
        drStarCross[2] = Math.Round((double)starCrossRaiseCount * 100 / (double)starCrossCount, 2).ToString() + "%";

        dt.Rows.Add(drStarCross);
        return dt;
    }


    protected void calendar_SelectionChanged(object sender, EventArgs e)
    {
        currentDate = DateTime.Parse(calendar.SelectedDate.ToShortDateString());
        dg.DataSource = AddTotal(GetData());
        dg.DataBind();
    }

    protected void dg_SortCommand(object source, DataGridSortCommandEventArgs e)
    {

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
                <td><asp:DataGrid runat="server" id="dg" Width="125%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" OnSortCommand="dg_SortCommand" AllowSorting="True" AutoGenerateColumns="False" ShowFooter="True" >
                    <AlternatingItemStyle BackColor="#DCDCDC" />
                    <Columns>
                        <asp:BoundColumn DataField="涨停日" HeaderText="涨停日"></asp:BoundColumn>
                        <asp:BoundColumn DataField="代码" HeaderText="代码"></asp:BoundColumn>
                        <asp:BoundColumn DataField="名称" HeaderText="名称"></asp:BoundColumn>
                        <asp:BoundColumn DataField="信号" HeaderText="信号"></asp:BoundColumn>
                        <asp:BoundColumn DataField="开盘价" HeaderText="开盘价" ></asp:BoundColumn>
                        <asp:BoundColumn DataField="涨停价" HeaderText="涨停价"></asp:BoundColumn>
                        <asp:BoundColumn DataField="涨停量" HeaderText="涨停量"></asp:BoundColumn>

                        <asp:BoundColumn DataField="1日" HeaderText="1日" ></asp:BoundColumn>
                        <asp:BoundColumn DataField="1日价" HeaderText="1日价"></asp:BoundColumn>
                        <asp:BoundColumn DataField="1日量" HeaderText="1日量"></asp:BoundColumn>
                        <asp:BoundColumn DataField="1日涨幅" HeaderText="1日涨幅"></asp:BoundColumn>

                        <asp:BoundColumn DataField="2日" HeaderText="2日" ></asp:BoundColumn>
                        <asp:BoundColumn DataField="2日价" HeaderText="2日价"></asp:BoundColumn>
                        <asp:BoundColumn DataField="2日量" HeaderText="2日量"></asp:BoundColumn>
                        <asp:BoundColumn DataField="2日涨幅" HeaderText="2日涨幅"></asp:BoundColumn>

                        <asp:BoundColumn DataField="3日" HeaderText="3日" ></asp:BoundColumn>
                        <asp:BoundColumn DataField="3日价" HeaderText="3日价"></asp:BoundColumn>
                        <asp:BoundColumn DataField="3日量" HeaderText="3日量"></asp:BoundColumn>
                        <asp:BoundColumn DataField="3日涨幅" HeaderText="3日涨幅"></asp:BoundColumn>

                        <asp:BoundColumn DataField="4日" HeaderText="4日" ></asp:BoundColumn>
                        <asp:BoundColumn DataField="4日价" HeaderText="4日价"></asp:BoundColumn>
                        <asp:BoundColumn DataField="4日量" HeaderText="4日量"></asp:BoundColumn>
                        <asp:BoundColumn DataField="4日涨幅" HeaderText="4日涨幅"></asp:BoundColumn>

                        <asp:BoundColumn DataField="5日" HeaderText="5日" ></asp:BoundColumn>
                        <asp:BoundColumn DataField="5日价" HeaderText="5日价"></asp:BoundColumn>
                        <asp:BoundColumn DataField="5日量" HeaderText="5日量"></asp:BoundColumn>
                        <asp:BoundColumn DataField="5日涨幅" HeaderText="5日涨幅"></asp:BoundColumn>

                        <asp:BoundColumn DataField="6日" HeaderText="6日" ></asp:BoundColumn>
                        <asp:BoundColumn DataField="6日价" HeaderText="6日价"></asp:BoundColumn>
                        <asp:BoundColumn DataField="6日量" HeaderText="6日量"></asp:BoundColumn>
                        <asp:BoundColumn DataField="6日涨幅" HeaderText="6日涨幅"></asp:BoundColumn>

                        <asp:BoundColumn DataField="7日" HeaderText="7日" ></asp:BoundColumn>
                        <asp:BoundColumn DataField="7日价" HeaderText="7日价"></asp:BoundColumn>
                        <asp:BoundColumn DataField="7日量" HeaderText="7日量"></asp:BoundColumn>
                        <asp:BoundColumn DataField="7日涨幅" HeaderText="7日涨幅"></asp:BoundColumn>

                        <asp:BoundColumn DataField="8日" HeaderText="8日" ></asp:BoundColumn>
                        <asp:BoundColumn DataField="8日价" HeaderText="8日价"></asp:BoundColumn>
                        <asp:BoundColumn DataField="8日量" HeaderText="8日量"></asp:BoundColumn>
                        <asp:BoundColumn DataField="8日涨幅" HeaderText="8日涨幅"></asp:BoundColumn>
                        
                    </Columns>
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
