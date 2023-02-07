<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public int suc = 0;
    public int newHighSuc = 0;
    public int count = 0;
    public int newHighCount = 0;
    public int days = 10;

    public int openHigh = 0;
    public int openLow = 0;
    public int openHighSuc = 0;
    public int openLowSuc = 0;
    public int openHighBigSuc = 0;
    public int openLowbigSuc = 0;

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
        dt.Columns.Add("开盘");
        dt.Columns.Add("买入");
        for (int i = 1; i <= days; i++)
        {
            dt.Columns.Add( i.ToString() + "日");
        }


        dt.Columns.Add("总计");
        DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up_twice where alert_date > '2022-1-1'  order by alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {

            bool newHigh = true;
            Stock s = GetStock(drOri["gid"].ToString().Trim());
            int alertIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));

            if (alertIndex <= 0 || alertIndex > s.kLineDay.Length - 1)
            {
                continue;
            }

            if (s.kLineDay[alertIndex].highestPrice != s.kLineDay[alertIndex].lowestPrice
                || s.kLineDay[alertIndex - 1].highestPrice != s.kLineDay[alertIndex - 1].lowestPrice)
            {
                continue;
            }





            int buyIndex = alertIndex + 1;
            if (buyIndex + days >= s.kLineDay.Length)
            {
                continue;
            }


            if ((s.kLineDay[buyIndex].startPrice - s.kLineDay[alertIndex].endPrice) / s.kLineDay[alertIndex].endPrice >= 0.0995)
            {
                continue;
            }




            double buyPrice = s.kLineDay[buyIndex].startPrice;
            bool isOpenHigh = false;

            if (buyPrice >= s.kLineDay[alertIndex].endPrice)
            {
                openHigh++;
                isOpenHigh = true;
            }
            else
            {
                openLow++;
            }


            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[buyIndex].endDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["买入"] = buyPrice.ToString();
            dr["开盘"] = isOpenHigh?"高开":"低开";

            double finalRate = double.MinValue;
            for (int j = 1; j <= days; j++)
            {
                double rate = (s.kLineDay[buyIndex + j].highestPrice - buyPrice) / buyPrice;
                finalRate = Math.Max(finalRate, rate);
                if (rate >= 0.01)
                {
                    dr[j.ToString() + "日"] = "<font color=red >" + Math.Round(rate * 100, 2).ToString() + "%</font>";
                }
                else
                {
                    dr[j.ToString() + "日"] = "<font color=green >" + Math.Round(rate * 100, 2).ToString() + "%</font>";
                }
            }
            if (finalRate >= 0.01)
            {
                suc++;

                if (isOpenHigh)
                {
                    openHighSuc++;
                }
                else
                {
                    openLowSuc++;
                }

                if (finalRate >= 0.1)
                {
                    newHighSuc++;
                    if (isOpenHigh)
                    {
                        openHighBigSuc++;
                    }
                    else
                    {
                        openLowbigSuc++;
                    }
                }
                dr["总计"] = "<font color=red >" + Math.Round(finalRate * 100, 2).ToString() + "%</font>";
            }
            else
            {
                dr["总计"] = "<font color=green >" + Math.Round(finalRate * 100, 2).ToString() + "%</font>";
            }
            count++;
            if (newHigh)
            {
                newHighCount++;
            }
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
    <title>二连板连续高换手</title>
</head>
<body>
    <form id="form1" runat="server">
        <div>
            总计：<%=count.ToString() %> / <%=Math.Round((double)100*suc/(double)count, 2).ToString() %>%<br />
            10%：<%=newHighSuc.ToString() %> / <%=Math.Round((double)100*newHighSuc/(double)count, 2).ToString() %>%
        </div>
        <div>
            高开：<%=openHigh.ToString() %> / <%=Math.Round((double)100*openHighSuc/(double)openHigh, 2).ToString() %>%<br />
            10%：<%=openHighBigSuc.ToString() %> / <%=Math.Round((double)100*openHighBigSuc/(double)openHigh, 2).ToString() %>%
        </div>
        <div>
            低开：<%=openLow.ToString() %> / <%=Math.Round((double)100*openLowSuc/(double)openLow, 2).ToString() %>%<br />
            10%：<%=openLowbigSuc.ToString() %> / <%=Math.Round((double)100*openLowbigSuc/(double)openLow, 2).ToString() %>%
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
