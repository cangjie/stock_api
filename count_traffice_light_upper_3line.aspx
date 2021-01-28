<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public int suc = 0;
    public int newHighSuc = 0;
    public int count = 0;
    public int newHighCount = 0;
    public int goingDownCount = 0;
    public int totalGreenCount = 0;


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
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("涨停");
        dt.Columns.Add("买入");
        dt.Columns.Add("1日");
        dt.Columns.Add("2日");
        dt.Columns.Add("3日");
        dt.Columns.Add("4日");
        dt.Columns.Add("5日");
        /*
        dt.Columns.Add("6日");
        dt.Columns.Add("7日");
        dt.Columns.Add("8日");
        dt.Columns.Add("9日");
        dt.Columns.Add("10日");
        dt.Columns.Add("11日");
        dt.Columns.Add("12日");
        dt.Columns.Add("13日");
        dt.Columns.Add("14日");
        dt.Columns.Add("15日");
        */
        dt.Columns.Add("总计");
        DataTable dtOri = DBHelper.GetDataTable(" select a.alert_date as alert_date , a.gid as gid from limit_up a "
            + " where  not exists ( select 'a' from limit_up c where a.gid = c.gid and dbo.func_GetLastTransactDate(c.alert_date, 1) = a.alert_date ) "
            + " and  not exists ( select 'a' from limit_up d where a.gid = d.gid and dbo.func_GetLastTransactDate(d.alert_date, 1) = a.alert_date ) "
            + " and alert_date < dbo.func_GetLastTransactDate(getdate(), 20) "
            //+ " and a.gid = 'sz000767' "
            + " order by a.alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {

            bool newHigh = false;
            bool firstGreen = false;
            Stock s = GetStock(drOri["gid"].ToString().Trim());

            int alertIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (alertIndex < 0)
            {
                continue;
            }
            if (!s.IsLimitUp(alertIndex))
            {
                continue;
            }
            if (s.IsLimitUp(alertIndex + 1))
            {
                continue;
            }
            if (s.IsLimitUp(alertIndex + 2))
            {
                continue;
            }
            if ((s.kLineDay[alertIndex + 1].endPrice - s.kLineDay[alertIndex].endPrice) / s.kLineDay[alertIndex].endPrice <= -0.095)
            {
                continue;
            }
            if ((s.kLineDay[alertIndex + 2].endPrice - s.kLineDay[alertIndex+1].endPrice) / s.kLineDay[alertIndex+1].endPrice <= -0.095)
            {
                continue;
            }
            if (s.kLineDay[alertIndex + 1].startPrice <= s.kLineDay[alertIndex + 1].endPrice)
            {
                continue;
            }
            if (s.kLineDay[alertIndex + 2].startPrice >= s.kLineDay[alertIndex + 2].endPrice)
            {
                continue;
            }
            if (s.kLineDay[alertIndex + 1].endPrice <= s.GetAverageSettlePrice(alertIndex + 1, 3, 3))
            {
                continue;
            }
            if (s.kLineDay[alertIndex + 2].endPrice <= s.GetAverageSettlePrice(alertIndex + 2, 3, 3))
            {
                continue;
            }



            bool haveLimitUp = false;


            int buyIndex = 0;

            for (int i = 1; i <= 13 && alertIndex + 2 + i < s.kLineDay.Length - 5; i++)
            {
                if (s.IsLimitUp(alertIndex + 2 + i))
                {
                    haveLimitUp = true;
                    buyIndex = alertIndex + 2 + i + 1;
                    break;
                }
            }


            if (!haveLimitUp)
            {
                continue;
            }

            if (buyIndex == 0)
            {
                continue;
            }

            double maxVolume = Math.Max(s.kLineDay[buyIndex].volume, s.kLineDay[buyIndex - 1].volume);








            if (buyIndex + 5 >= s.kLineDay.Length)
            {
                continue;
            }

            double buyPrice = s.kLineDay[buyIndex].endPrice;



            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[buyIndex].endDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["买入"] = buyPrice.ToString();

            dr["涨停"] = "否";

            double finalRate = double.MinValue;
            for (int j = 1; j <= 5; j++)
            {
                if (!newHigh)
                {
                    if (s.IsLimitUp(buyIndex + j))
                    {
                        newHigh = true;
                        newHighCount++;
                        dr["涨停"] = "是";
                    }
                }

                double rate = (s.kLineDay[buyIndex + j].highestPrice - buyPrice) / buyPrice;
                finalRate = Math.Max(finalRate, rate);
                if (rate >= 0.01)
                {
                    dr[j.ToString() + "日"] = "<font color=red >" + Math.Round(rate * 100, 2).ToString() + "%</font>";
                }
                else
                {
                    if (j == 1)
                    {
                        firstGreen = true;
                    }
                    dr[j.ToString() + "日"] = "<font color=green >" + Math.Round(rate * 100, 2).ToString() + "%</font>";
                }
            }
            if (finalRate >= 0.01)
            {
                suc++;
                if (finalRate >= 0.05)
                {
                    newHighSuc++;
                }
                dr["总计"] = "<font color=red >" + Math.Round(finalRate * 100, 2).ToString() + "%</font>";
            }
            else
            {
                if (firstGreen)
                {
                    goingDownCount++;
                }
                totalGreenCount++;
                dr["总计"] = "<font color=green >" + Math.Round(finalRate * 100, 2).ToString() + "%</font>";
            }
            count++;

            dt.Rows.Add(dr);
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
            gidArr.Add(s);
        }
        return s;
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
            总计：<%=count.ToString() %> / <%=Math.Round((double)100*suc/(double)count, 2).ToString() %>%<br />
            涨5%：<%=newHighCount.ToString() %> / <%=Math.Round((double)100*newHighCount/(double)count, 2).ToString() %>%<br />
            首日止损：<%=Math.Round((double)100*goingDownCount/(double)totalGreenCount, 2).ToString() %>%
        </div>
        <div>
            <asp:DataGrid runat="server" id="dg" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
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
