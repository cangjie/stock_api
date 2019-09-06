<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    public static Stock[] stockArr;

    protected void Page_Load(object sender, EventArgs e)
    {
        DataTable dtGid = DBHelper.GetDataTable(" select distinct gid from bread_pool where alert_type <> '' ");
        stockArr = new Stock[dtGid.Rows.Count];
        if (Application["total_stock_run_reverse_all"] == null)
        {
            for (int i = 0; i < stockArr.Length; i++)
            {
                Stock s = new Stock(dtGid.Rows[i][0].ToString().Trim(), rc);
                s.LoadKLineDay(rc);
                KLine.ComputeMACD(s.kLineDay);
                KLine.ComputeRSV(s.kLineDay);
                KLine.ComputeKDJ(s.kLineDay);
                stockArr[i] = s;
            }
            Application.Lock();
            Application["total_stock_run_reverse_all"] = stockArr;
            Application.UnLock();
        }
        else
        {
            stockArr = (Stock[])Application["total_stock_run_reverse_all"];
        }
        if (!IsPostBack)
        {
            int success = 0;
            DataTable dtOri = GetData();
            DataTable dt = new DataTable();
            dt.Columns.Add("日期");
            dt.Columns.Add("代码");
            dt.Columns.Add("名称");
            dt.Columns.Add("折返类型");
            dt.Columns.Add("换手");
            dt.Columns.Add("幅度");
            dt.Columns.Add("买入");
            for (int i = 1; i <= 10; i++)
            {
                dt.Columns.Add(i.ToString() + "日");
            }
            dt.Columns.Add("总计");
            foreach (DataRow drOri in dtOri.Select("", "幅度 desc"))
            {
                DataRow dr = dt.NewRow();
                dr["日期"] = DateTime.Parse(drOri["日期"].ToString().Trim()).ToShortDateString();
                dr["代码"] = drOri["代码"];
                dr["名称"] = drOri["名称"];
                dr["折返类型"] = drOri["折返类型"];
                dr["换手"] = Math.Round(100*(double)drOri["换手"], 2).ToString() + "%";
                dr["幅度"] = Math.Round(100 * (double)drOri["幅度"], 2).ToString() + "%";
                dr["买入"] = drOri["买入"];
                for (int i = 1; i <= 10; i++)
                {
                    double rate = (double)drOri[i.ToString() + "日"];
                    dr[i.ToString() + "日"] = "<font color='" + (rate >= 0.05 ? "red" : "green") + "' >" + Math.Round(rate * 100, 2).ToString() + "%</font>";
                }
                double totalRate = (double)drOri["总计"];
                dr["总计"] = "<font color='" + (totalRate >= 0.05 ? "red" : "green") + "' >" + Math.Round(totalRate * 100, 2).ToString() + "%</font>";
                if (totalRate >= 0.05)
                    success++;
                dt.Rows.Add(dr);
            }
            dg.DataSource = dt;
            dg.DataBind();
            LblCount.Text = (Math.Round(100 * (double)success / (double)dt.Rows.Count, 2)).ToString() + "%";
        }
    }

    public DataTable GetData()
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("折返类型");
        dt.Columns.Add("换手", Type.GetType("System.Double"));
        dt.Columns.Add("幅度", Type.GetType("System.Double"));
        dt.Columns.Add("买入", Type.GetType("System.Double"));
        for (int i = 1; i <= 10; i++)
        {
            dt.Columns.Add(i.ToString() + "日", Type.GetType("System.Double"));
        }
        dt.Columns.Add("总计", Type.GetType("System.Double"));

        DataTable dtOri = DBHelper.GetDataTable(" select * from bread_pool where alert_type <> '' and alert_date <= '"
            + Util.GetLastTransactDate(DateTime.Now, 10).ToShortDateString() + "' order by alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock s = GetGid(drOri["gid"].ToString().Trim());
            int highestIndex = s.GetItemIndex(DateTime.Parse(drOri["highest_date"].ToString().Trim()));
            int currentIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString().Trim()));
            if (highestIndex < 0 || highestIndex > s.kLineDay.Length)
            {
                continue;
            }
            double exchange = s.kLineDay[highestIndex].volume / s.TotalStockCount(DateTime.Parse(drOri["highest_date"].ToString().Trim()));
            if (highestIndex > 0 && highestIndex < s.kLineDay.Length && exchange < 0.15)
            {
                double buyPrice = s.kLineDay[currentIndex].endPrice;
                if (currentIndex + 10 >= s.kLineDay.Length)
                {
                    continue;
                }
                DataRow dr = dt.NewRow();
                double maxPrice = 0;
                for (int i = 1; i <= 10; i++)
                {
                    dr[i.ToString() + "日"] = (s.kLineDay[currentIndex + i].highestPrice - buyPrice) / buyPrice;
                    maxPrice = Math.Max(maxPrice, s.kLineDay[currentIndex + i].highestPrice);
                }
                dr["总计"] = (maxPrice - buyPrice) / buyPrice;
                dr["日期"] = drOri["alert_date"].ToString();
                dr["代码"] = drOri["gid"].ToString();
                dr["名称"] = s.Name.Trim();
                double higest = double.Parse(drOri["highest"].ToString());
                double lowest = double.Parse(drOri["lowest"].ToString());
                dr["幅度"] = (higest - lowest) / lowest;
                if ((double)dr["幅度"] < 0.4)
                {
                    continue;
                }
                dr["折返类型"] = drOri["alert_type"].ToString().Replace("_next_day", "隔日");
                dr["换手"] = exchange;
                dt.Rows.Add(dr);
            }
        }
        return dt;
    }

    public Stock GetGid(string gid)
    {
        foreach (Stock sTemp in stockArr)
        {
            if (sTemp.gid.Trim().Equals(gid))
            {
                return sTemp;
            }
        }
        return new Stock();
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
        <br />
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
