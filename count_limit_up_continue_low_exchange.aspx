﻿<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public int suc = 0;
    public int newHighSuc = 0;
    public int count = 0;
    public int newHighCount = 0;
    public int days = 15;

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
        dt.Columns.Add("换手");
        dt.Columns.Add("买入");
        for (int i = 1; i <= days; i++)
        {
            dt.Columns.Add( i.ToString() + "日");
        }


        dt.Columns.Add("总计");
        DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up a where  "
            + " exists ( select 'a' from limit_up b where a.gid = b.gid and b.alert_date = dbo.func_GetLastTransactDate(a.alert_date, 1) )  "
            + " and not exists ( select 'a' from limit_up c where a.gid = c.gid and a.alert_date = dbo.func_GetLastTransactDate(c.alert_date, 1) ) "
            + " and alert_date > '2022-8-31'  order by alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {

            bool newHigh = true;
            Stock s = GetStock(drOri["gid"].ToString().Trim());
            int alertIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));

            if (alertIndex < 2 || alertIndex >= s.kLineDay.Length - 1)
            {
                continue;
            }

            if (!s.IsLimitUp(alertIndex - 1) || !s.IsLimitUp(alertIndex) || s.IsLimitUp(alertIndex + 1))
            {
                continue;
            }

            if ((s.kLineDay[alertIndex + 1].endPrice - s.kLineDay[alertIndex].endPrice) / s.kLineDay[alertIndex].endPrice <= -0.0995)
            {
                continue;
            }

            if (s.kLineDay[alertIndex + 1].turnOver >= 20)
            {
                continue;
            }








            double highestPrice = s.kLineDay[alertIndex].highestPrice;



            int buyIndex = alertIndex + 1;

            if (buyIndex + days >= s.kLineDay.Length)
            {
                continue;
            }

            bool below3Line = false;
            double preHighestPrice = 0;
            int below3LineIndex = 0;

            for (int i = 1; i <= 200 && alertIndex - i >= 0; i++)
            {
                if (s.kLineDay[alertIndex - i].endPrice < s.GetAverageSettlePrice(alertIndex - i, 3, 3))
                {
                    below3Line = true;
                    below3LineIndex = alertIndex - i;
                }
                if (below3Line && s.kLineDay[alertIndex - i].highestPrice > preHighestPrice)
                {
                    preHighestPrice = s.kLineDay[alertIndex - i].highestPrice;
                }
            }

            int breakIndex = -1;

            for (int i = below3LineIndex; i <= alertIndex; i++)
            {
                if (s.IsLimitUp(i) && s.kLineDay[i].endPrice > preHighestPrice)
                {
                    breakIndex = i;
                    break;
                }
            }




            double buyPrice = s.kLineDay[buyIndex].startPrice;
            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[buyIndex].endDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["买入"] = buyPrice.ToString();
            dr["换手"] = Math.Round(s.kLineDay[buyIndex].turnOver, 2).ToString() + "%";
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
                if (finalRate >= 0.05)
                {
                    newHighSuc++;
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

    protected void btn_Click(object sender, EventArgs e)
    {
        DataTable dtDownload = GetData();
        string content = "";
        foreach (DataRow dr in dtDownload.Rows)
        {
            string gid = dr["代码"].ToString().Trim();
            try
            {
                gid = gid.Substring(gid.IndexOf(">"), gid.Length - gid.IndexOf(">"));
            }
            catch
            {

            }
            gid = gid.Replace("</a>", "").Replace(">", "").ToUpper();
            content += gid + "\r\n";
        }
        Response.Clear();
        Response.ContentType = "text/plain";
        Response.Headers.Add("Content-Disposition", "attachment; filename=count_limit_up_continue.txt");
        Response.Write(content.Trim());
        Response.End();
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>连板后低换手</title>
</head>
<body>
    <form id="form1" runat="server">
        <div><asp:Button ID="btn" runat="server"  Text=" 下 载 " OnClick="btn_Click" /></div>
        <div>
            总计：<%=count.ToString() %> / <%=Math.Round((double)100*suc/(double)count, 2).ToString() %>%<br />
            5%：<%=newHighSuc.ToString() %> / <%=Math.Round((double)100*newHighSuc/(double)count, 2).ToString() %>%
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
