<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<!DOCTYPE html>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        //GetVolumePercent("买入价：52.1 ????? 放量：76.39%");
        if (!IsPostBack)
        {
            DataTable dt = GetData();
            AddTotal(dt);
            RenderHTML(dt);
            dg.DataSource = dt;
            dg.DataBind();
        }
    }

    public void RenderHTML(DataTable dt)
    {
        for (int i = 0; i < dt.Rows.Count - 2; i++)
        {
            dt.Rows[i]["代码"] = "<a href=\"show_k_line_day.aspx?gid=" + dt.Rows[i]["代码"].ToString() + "\" target=\"_blank\" >"
                + dt.Rows[i]["代码"].ToString().Trim() + "</a>";
            dt.Rows[i]["放量"] = dt.Rows[i]["放量"].ToString() + "%";
            for(int j = 1; j <= 5; j++)
            {
                double value = 0;
                if (!dt.Rows[i][j.ToString() + "日"].ToString().Trim().Equals("-"))
                {
                    value = double.Parse(dt.Rows[i][j.ToString() + "日"].ToString().Trim());
                    string color = ((value >= 1) ? "red" : "green");
                    dt.Rows[i][j.ToString() + "日"] = "<font color=\"" + color.Trim() + "\" >" + Math.Round(value, 2).ToString() + "%</font>";
                }
            }
            //double valueTotal = 0;
            if (!dt.Rows[i]["总计"].ToString().Trim().Equals("-"))
            {
                double value = double.Parse(dt.Rows[i]["总计"].ToString().Trim());
                string color = ((value >= 1) ? "red" : "green");
                dt.Rows[i]["总计"] = "<font color=\"" + color.Trim() + "\" >" + Math.Round(value, 2).ToString() + "%</font>";
            }
        }
    }

    public static void AddTotal(DataTable dt)
    {
        int[] commonRaise = new int[6] { 0, 0, 0, 0, 0, 0 };
        int[] crownRaise = new int[6] { 0, 0, 0, 0, 0, 0 };
        int[] commonCount = new int[6] { 0, 0, 0, 0, 0, 0 };
        int[] crownCount = new int[6] { 0, 0, 0, 0, 0, 0 };
        DataRow drCommon = dt.NewRow();
        DataRow drCrown = dt.NewRow();
        foreach (DataRow dr in dt.Rows)
        {
            for (int j = 1; j <= 5; j++)
            {
                if (!dr[j.ToString() + "日"].ToString().Equals("-"))
                {
                    commonCount[j - 1]++;
                    if (dr["信号"].ToString().IndexOf("👑") >= 0)
                        crownCount[j - 1]++;
                    double value = double.Parse(dr[j.ToString() + "日"].ToString());
                    if (value >= 1)
                    {
                        commonRaise[j - 1]++;
                        if (dr["信号"].ToString().IndexOf("👑") >= 0)
                        {
                            crownRaise[j - 1]++;
                        }
                    }
                }
            }
            if (!dr["总计"].ToString().Equals("-"))
            {
                commonCount[5]++;
                if (dr["信号"].ToString().IndexOf("👑") >= 0)
                {
                    crownCount[5]++;
                }
                double value = double.Parse(dr["总计"].ToString());
                if (value >= 1)
                {
                    commonRaise[5]++;
                    if (dr["信号"].ToString().IndexOf("👑") >= 0)
                    {
                        crownRaise[5]++;
                    }
                }
            }
        }
        drCommon["信号"] = "";
        drCrown["信号"] = "👑";
        for (int i = 1; i <= 5; i++)
        {
            drCommon[i.ToString() + "日"] = Math.Round((double)commonRaise[i - 1] * 100 / (double)commonCount[i -1], 2).ToString() + "%";
            drCrown[i.ToString() + "日"] = Math.Round((double)crownRaise[i - 1] * 100 / (double)crownCount[i - 1]).ToString() + "%";
        }
        drCommon["总计"] = Math.Round((double)commonRaise[5] * 100 / (double)commonCount[5], 2).ToString() + "%";
        drCrown["总计"] = Math.Round((double)crownRaise[5] * 100 / (double)crownCount[5]).ToString() + "%";
        dt.Rows.Add(drCommon);
        dt.Rows.Add(drCrown);
    }


    public static DataTable GetData()
    {
        DateTime startDate = DateTime.Parse("2017-9-19");
        DataTable dtOri = DBHelper.GetDataTable(" select * from stock_alert_message where alert_date >= '" + startDate.ToShortDateString()
            + "' and alert_type = 'break_3_line_twice' order by alert_date desc, create_date desc ");

        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("时间");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("信号");
        dt.Columns.Add("价格");
        dt.Columns.Add("放量");
        for (int i = 1; i <= 5; i++)
        {
            dt.Columns.Add(i.ToString() + "日");
        }
        dt.Columns.Add("总计");

        if (dtOri.Rows.Count == 0)
            return dt;
        DateTime currentDate = DateTime.Parse(dtOri.Rows[0]["alert_date"].ToString().Trim());
        double maxVolume = GetVolumePercent(dtOri.Rows[0]["message"].ToString().Trim());
        string maxVolumeGid = dtOri.Rows[0]["gid"].ToString().Trim();
        for (int i = 0; i < dtOri.Rows.Count; i++)
        {
            if (currentDate != DateTime.Parse(dtOri.Rows[i]["alert_date"].ToString().Trim()))
            {
                DataRow[] drArr = dt.Select(" 日期 = '" + currentDate.ToShortDateString() + "' and 代码 = '" + maxVolumeGid + "' ");
                if (drArr.Length > 0)
                {
                    drArr[0]["信号"] = "👑";
                }
                currentDate = DateTime.Parse(dtOri.Rows[i]["alert_date"].ToString().Trim());
                maxVolume = GetVolumePercent(dtOri.Rows[i]["message"].ToString().Trim());
                maxVolumeGid = dtOri.Rows[i]["gid"].ToString().Trim();
            }
            else
            {
                if (maxVolume < GetVolumePercent(dtOri.Rows[i]["message"].ToString().Trim()))
                {
                    maxVolume = GetVolumePercent(dtOri.Rows[i]["message"].ToString().Trim());
                    maxVolumeGid = dtOri.Rows[i]["gid"].ToString().Trim();
                }
            }
            DataRow dr = dt.NewRow();
            dr["日期"] = DateTime.Parse(dtOri.Rows[i]["alert_date"].ToString().Trim()).ToShortDateString();
            dr["时间"] = DateTime.Parse(dtOri.Rows[i]["create_date"].ToString().Trim()).ToShortTimeString();
            dr["代码"] = dtOri.Rows[i]["gid"].ToString().Trim();
            Stock stock = new Stock(dtOri.Rows[i]["gid"].ToString().Trim());
            dr["名称"] = stock.Name.Trim();
            dr["信号"] = "";
            double buyPrice = GetBuyPrice(dtOri.Rows[i]["message"].ToString().Trim());
            if (buyPrice == 0)
                continue;
            dr["价格"] = buyPrice;
            double volume = GetVolumePercent(dtOri.Rows[i]["message"].ToString().Trim());
            if (volume <= 150)
                continue;
            dr["放量"] = volume;
            stock.LoadKLineDay();
            int currentIndex = stock.GetItemIndex(DateTime.Parse(dtOri.Rows[i]["alert_date"].ToString().Trim()));
            double maxPrice = 0;
            for (int j = 1; j <= 5; j++)
            {
                if (currentIndex + j < stock.kLineDay.Length)
                {
                    maxPrice = Math.Max(stock.kLineDay[j + currentIndex].highestPrice, maxPrice);
                    dr[j.ToString() + "日"] = (stock.kLineDay[j + currentIndex].highestPrice - buyPrice) * 100 / buyPrice;
                }
                else
                {
                    dr[j.ToString() + "日"] = "-";
                }
            }
            dr["总计"] = maxPrice == 0 ? "-" : (100 * (maxPrice - buyPrice) / buyPrice).ToString();
            dt.Rows.Add(dr);
        }
        DataRow[] drArrLast = dt.Select(" 日期 = '" + currentDate.ToShortDateString() + "' and 代码 = '" + maxVolumeGid + "' ");
        if (drArrLast.Length > 0)
        {
            drArrLast[0]["信号"] = "👑";
        }

        return dt;
    }

    public static double GetVolumePercent(string message)
    {
        try
        {
            string v = Regex.Match(message, "放量：\\d+\\.*\\d*%").Value.Replace("放量：", "").Replace("%","");
            return double.Parse(v);
        }
        catch
        {
            return 0;
        }
    }

    public static double GetBuyPrice(string message)
    {
        try
        {
            string v = Regex.Match(message, "买入价：\\d+\\.*\\d*").Value.Replace("买入价：", "");
            return double.Parse(v);
        }
        catch
        {
            return 0;
        }
    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
    <asp:DataGrid ID="dg" runat="server" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" Width="100%" >
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
