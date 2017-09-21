<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<!DOCTYPE html>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            DataTable dt = GetData();
            AddTotal(dt);
            RenderHtml(dt);
            dg.DataSource = dt;
            dg.DataBind();
        }
    }

    public void RenderHtml(DataTable dt)
    {
        int totalCount = 1;
        for (int i = 0; i < dt.Rows.Count - totalCount; i++)
        {
            dt.Rows[i]["代码"] = "<a href=\"show_k_line_day.aspx?gid=" + dt.Rows[i]["代码"].ToString() + "\" target=\"_blank\" >"
                + dt.Rows[i]["代码"].ToString().Trim() + "</a>";
            dt.Rows[i]["缩量"] = dt.Rows[i]["缩量"].ToString() + "%";
            for (int j = 1; j <= 5; j++)
            {
                try
                {
                    if (!dt.Rows[i][j.ToString()+"日"].ToString().Trim().Equals("-"))
                    {
                        double value = double.Parse(dt.Rows[i][j.ToString()+"日"].ToString());
                        string color = "green";
                        if (value >= 1)
                            color = "red";
                        dt.Rows[i][j.ToString() + "日"] = "<font color=\"" + color.Trim() + "\" >"
                            + Math.Round(value, 2).ToString() + "%</font>";
                    }
                }
                catch
                {

                }
            }
            if (!dt.Rows[i]["总计"].ToString().Trim().Equals("-"))
            {
                try
                {
                    double value = double.Parse(dt.Rows[i]["总计"].ToString());
                    string color = "green";
                    if (value >= 1)
                        color = "red";
                    dt.Rows[i]["总计"] = "<font color=\"" + color.Trim() + "\" >"
                        + Math.Round(value, 2).ToString() + "%</font>";
                }
                catch
                {

                }
            }
        }
    }

    public static void AddTotal(DataTable dt)
    {
        DataRow drTotal = dt.NewRow();
        int[] totalCountArr = new int[6] { 0, 0, 0, 0, 0, 0 };
        foreach (DataRow dr in dt.Rows)
        {
            for (int j = 1; j <= 5; j++)
            {
                if (!dr[j.ToString() + "日"].ToString().Trim().Equals("-"))
                {
                    totalCountArr[j - 1]++;
                    try
                    {
                        double value = double.Parse(dr[j.ToString() + "日"].ToString().Trim());
                        if (value >= 1)
                        {
                            int count = 0;
                            try
                            {
                                count = int.Parse(drTotal[j.ToString() + "日"].ToString().Trim());
                            }
                            catch
                            {

                            }
                            count++;
                            drTotal[j.ToString() + "日"] = count;
                        }
                    }
                    catch
                    {

                    }

                }

            }
            if (!dr["总计"].ToString().Equals("-"))
            {
                try
                {
                    double value = double.Parse(dr["总计"].ToString().Trim());
                    totalCountArr[5]++;
                    if (value>=1)
                    {
                        int count = 0;
                        try
                        {
                            if (!drTotal["总计"].ToString().Trim().Equals(""))
                                count = int.Parse(drTotal["总计"].ToString().Trim());
                        }
                        catch
                        {

                        }
                        count++;
                        drTotal["总计"] = count;
                    }
                }
                catch
                {

                }
            }
        }
        for (int j = 1; j <= 5; j++)
        {
            if (!drTotal[j.ToString() + "日"].ToString().Equals(""))
                drTotal[j.ToString() + "日"] = Math.Round(100*double.Parse(drTotal[j.ToString() + "日"].ToString()) / (double)totalCountArr[j-1], 2).ToString() + "%";
        }
        drTotal["总计"] = Math.Round(100 * double.Parse(drTotal["总计"].ToString()) / (double)totalCountArr[5]).ToString() + "%";
        dt.Rows.Add(drTotal);
    }

    public static DataTable GetData()
    {
        DateTime startDate = DateTime.Parse("2017-9-19");
        DataTable dtOri = DBHelper.GetDataTable(" select * from stock_alert_message where alert_date >= '" + startDate.ToShortDateString()
            + "' and alert_type = 'limit_up_box' order by alert_date desc, create_date desc ");

        DataTable dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("时间");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("信号");
        dt.Columns.Add("缩量");
        dt.Columns.Add("调整天数");
        dt.Columns.Add("买入价");
        for (int i = 1; i <= 5; i++)
        {
            dt.Columns.Add(i.ToString() + "日");
        }
        dt.Columns.Add("总计");

        for (int i = 0; i < dtOri.Rows.Count; i++)
        {
            DataRow dr = dt.NewRow();
            DateTime currentDate = DateTime.Parse(dtOri.Rows[i]["alert_date"].ToString());
            dr["日期"] = currentDate.ToShortDateString();
            dr["时间"] = DateTime.Parse(dtOri.Rows[i]["create_date"].ToString()).ToShortTimeString();
            dr["代码"] = dtOri.Rows[i]["gid"].ToString().Trim();
            Stock s = new Stock(dtOri.Rows[i]["gid"].ToString().Trim());
            dr["名称"] = s.Name.Trim();
            dr["信号"] = "";
            string message = dtOri.Rows[i]["message"].ToString().Trim();
            dr["缩量"] = GetVolumePercent(message);
            dr["调整天数"] = GetShockDays(message);
            double buyPrice = GetBuyPrice(message);
            dr["买入价"] = buyPrice;
            s.LoadKLineDay();
            int currentIndex = s.GetItemIndex(currentDate);
            double maxPrice = 0;
            for (int j = 1; j <= 5; j++)
            {
                if (currentIndex + j < s.kLineDay.Length)
                {
                    double highPrice = s.kLineDay[currentIndex + j].highestPrice;
                    maxPrice = Math.Max(maxPrice, highPrice);
                    dr[j.ToString() + "日"] = 100 * (highPrice - buyPrice) / buyPrice;
                }
                else
                {
                    dr[j.ToString() + "日"] = "-";
                }
            }
            if (maxPrice > 0)
                dr["总计"] = 100 * (maxPrice - buyPrice) / buyPrice;
            else
                dr["总计"] = "-";
            dt.Rows.Add(dr);
        }

        return dt;
    }

    public static double GetVolumePercent(string message)
    {
        try
        {
            string str = Regex.Match(message, "缩量\\d+\\.*\\d*%").Value.Trim();
            return double.Parse(str.Replace("缩量", "").Replace("%",""));
        }
        catch
        {

        }
        return 0;
    }

    public static int GetShockDays(string message)
    {
        try
        {
            string str = Regex.Match(message, "已调整\\d日").Value.Trim();
            return int.Parse(str.Replace("已调整", "").Replace("日", ""));
        }
        catch
        {

        }
        return 0;
    }

    public static double GetBuyPrice(string message)
    {
        try
        {
            string str = Regex.Match(message, "买入价：\\d+\\.*\\d*").Value.Trim();
            return double.Parse(str.Replace("买入价：", "").Replace("%",""));
        }
        catch
        {

        }
        return 0;
    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
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
