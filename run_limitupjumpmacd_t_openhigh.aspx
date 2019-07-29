﻿<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>

<!DOCTYPE html>

<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    public static ArrayList gidArr = new ArrayList();

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            DataTable dtOri = GetData();
            int successCount = 0;
            DataTable dt = new DataTable();
            dt.Columns.Add("日期");
            dt.Columns.Add("代码");
            dt.Columns.Add("名称");
            dt.Columns.Add("1日");
            dt.Columns.Add("2日");
            dt.Columns.Add("3日");
            dt.Columns.Add("4日");
            dt.Columns.Add("5日");
            dt.Columns.Add("6日");
            dt.Columns.Add("7日");
            dt.Columns.Add("8日");
            dt.Columns.Add("9日");
            dt.Columns.Add("10日");
            dt.Columns.Add("总计");

            foreach (DataRow drOri in dtOri.Rows)
            {
                if (((double)drOri["总计"]) >= 0.2)
                {
                    successCount++;
                }
                DataRow dr = dt.NewRow();
                dr["日期"] = drOri["日期"].ToString();
                dr["代码"] = drOri["代码"].ToString();
                dr["名称"] = drOri["名称"].ToString();
                double v = 0;
                for (int i = 1; i <= 10; i++)
                {
                    v = (double)drOri[i.ToString() + "日"];
                    dr[i.ToString() + "日"] = "<font color='" + ((v > 0.01)? "red" : "green") + "' >" + Math.Round(v * 100, 2).ToString() + "%</font>";
                }
                v = (double)drOri["总计"];
                dr["总计"] = "<font color='" + ((v > 0.01)? "red" : "green") + "' >" + Math.Round(v * 100, 2).ToString() + "%</font>";
                dt.Rows.Add(dr);
            }
            LblCount.Text = Math.Round(100 * (double)successCount / (double)(dt.Rows.Count), 2).ToString();
            dg.DataSource = dt;
            dg.DataBind();
        }
    }

    public DataTable GetData()
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("1日", Type.GetType("System.Double"));
        dt.Columns.Add("2日", Type.GetType("System.Double"));
        dt.Columns.Add("3日", Type.GetType("System.Double"));
        dt.Columns.Add("4日", Type.GetType("System.Double"));
        dt.Columns.Add("5日", Type.GetType("System.Double"));
        dt.Columns.Add("6日", Type.GetType("System.Double"));
        dt.Columns.Add("7日", Type.GetType("System.Double"));
        dt.Columns.Add("8日", Type.GetType("System.Double"));
        dt.Columns.Add("9日", Type.GetType("System.Double"));
        dt.Columns.Add("10日", Type.GetType("System.Double"));
        dt.Columns.Add("总计", Type.GetType("System.Double"));

        DataTable dtLimitUp = DBHelper.GetDataTable(" select * from limit_up where alert_date <= '"
            + Util.GetLastTransactDate(DateTime.Now.Date, 13) + "' order by alert_date desc ");
        foreach (DataRow drLimitUp in dtLimitUp.Rows)
        {
            Stock s = GetStock(drLimitUp["gid"].ToString().Trim());
            DateTime limitUpDate = DateTime.Parse(drLimitUp["alert_date"].ToString());
            int limitUpIndex = s.GetItemIndex(limitUpDate);
            if (!SearchLimitUp(s.kLineDay, limitUpIndex) || !SearchLimitUp(s.kLineDay, limitUpIndex+1) 
                || s.kLineDay[limitUpIndex+2].startPrice <= s.kLineDay[limitUpIndex + 1].endPrice)
            {
                continue;
            }
            double currentSettlePrice = s.kLineDay[limitUpIndex].endPrice;
            double buyPrice = s.kLineDay[limitUpIndex].startPrice;
            s.kLineDay[limitUpIndex].endPrice = buyPrice;
            KLine.ComputeMACD(s.kLineDay);
            if (s.kLineDay[limitUpIndex - 1].macd >= 0 || s.kLineDay[limitUpIndex].macd <= 0 || buyPrice <= s.kLineDay[limitUpIndex-1].highestPrice)
            {
                continue;
            }
            s.kLineDay[limitUpIndex].endPrice = currentSettlePrice;

            buyPrice = s.kLineDay[limitUpIndex + 2].startPrice;

            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[limitUpIndex + 2].startDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();


            dr["名称"] = s.Name.Trim();


            double highestPrice = 0;
            for (int i = 0; i < 10; i++)
            {
                highestPrice = Math.Max(s.kLineDay[limitUpIndex + 1 + 1 + i].highestPrice, highestPrice);
                dr[(i + 1).ToString() + "日"] = (s.kLineDay[limitUpIndex + 1 + 1 + 1 + i].highestPrice - buyPrice) / buyPrice;
            }

            dr["总计"] = (highestPrice - buyPrice) / buyPrice;
            dt.Rows.Add(dr);

        }

        return dt;
    }

    public static bool SearchLimitUp(KLine[] kArr, int currentIndex)
    {
        if (currentIndex <= 0)
        {
            return false;
        }
        if ((kArr[currentIndex].endPrice - kArr[currentIndex-1].endPrice) / kArr[currentIndex-1].endPrice > 0.095
            && kArr[currentIndex].endPrice == kArr[currentIndex].highestPrice)
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    public static Stock GetStock(string gid)
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
            s.LoadKLineDay(rc);
            gidArr.Add(s);
        }
        return s;
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <asp:Label runat="server" ID="LblCount" ></asp:Label>
    </div>
    <div>
        <asp:DataGrid ID="dg" runat="server" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
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
