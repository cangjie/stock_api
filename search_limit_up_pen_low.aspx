<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>

<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("52.82.51.144");

    public static Stock[] gidArr;

    public DataTable dt;

    protected void Page_Load(object sender, EventArgs e)
    {
        FillGidArr();
        //gidArr = new Stock[] { new Stock("sh600143") };
        //gidArr[0].LoadKLineDay(rc);
        dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("买入");
        dt.Columns.Add("1日");
        dt.Columns.Add("2日");
        dt.Columns.Add("3日");

        dt.Columns.Add("总计");

        DateTime startDate = Util.GetLastTransactDate(DateTime.Now.Date, 6);

        foreach (Stock s in gidArr)
        {
            int currentIndex = s.GetItemIndex(startDate);
            if (currentIndex <= 5)
            {
                continue;
            }
            for (int i = currentIndex; i >= 5; i--)
            {
                if (s.IsLimitUp(i - 1) && !s.IsLimitUp(i - 2) && s.IsLimitUp(i - 3) && s.IsLimitUp(i - 4))
                {
                    bool fromBottom = true;
                    for (int j = i - 5; j >= 0 && s.GetAverageSettlePrice(j, 3, 3) <= s.kLineDay[j].endPrice; j--)
                    {
                        if (s.IsLimitUp(j))
                        {
                            fromBottom = false;
                            break;
                        }
                    }
                    if (fromBottom)
                    {
                        double maxPrice = Math.Max(Math.Max(s.kLineDay[i - 1].highestPrice, s.kLineDay[i - 2].highestPrice),
                            Math.Max(s.kLineDay[i - 3].highestPrice, s.kLineDay[i - 4].highestPrice));
                        if (s.kLineDay[i].startPrice > s.kLineDay[i - 1].endPrice)
                        {
                            DataRow dr = dt.NewRow();
                            dr["日期"] = s.kLineDay[i].startDateTime.ToShortDateString();
                            dr["名称"] = s.Name.Trim();
                            dr["代码"] = s.gid.Trim();
                            double buyPrice = s.kLineDay[currentIndex].startPrice;
                            dr["买入"] = Math.Round(buyPrice, 2).ToString();
                            maxPrice = s.kLineDay[currentIndex + 1].highestPrice;
                            double rate = (s.kLineDay[currentIndex + 1].highestPrice - buyPrice) / buyPrice;
                            dr["1日"] = "<font color=\"" + ((rate > 0.01) ? "red" : "green") + "\" >" + Math.Round(rate * 100, 2).ToString() + "%</a>";
                            maxPrice = Math.Max(maxPrice, s.kLineDay[currentIndex + 2].highestPrice);
                            rate = (s.kLineDay[currentIndex + 2].highestPrice - buyPrice) / buyPrice;
                            dr["2日"] = "<font color=\"" + ((rate > 0.01) ? "red" : "green") + "\" >" + Math.Round(rate * 100, 2).ToString() + "%</a>";
                            maxPrice = Math.Max(maxPrice, s.kLineDay[currentIndex + 3].highestPrice);
                            rate = (s.kLineDay[currentIndex + 3].highestPrice - buyPrice) / buyPrice;
                            dr["3日"] = "<font color=\"" + ((rate > 0.01) ? "red" : "green") + "\" >" + Math.Round(rate * 100, 2).ToString() + "%</a>";
                            rate = (maxPrice - buyPrice) / buyPrice;
                            dr["总计"] = "<font color=\"" + ((rate > 0.01) ? "red" : "green") + "\" >" + Math.Round(rate * 100, 2).ToString() + "%</a>";
                            dt.Rows.Add(dr);
                        }
                    }
                }

            }
        }



        DataTable dtNew = dt.Clone();
        foreach (DataRow dr in dt.Select("", "日期 desc"))
        {
            DataRow drNew = dtNew.NewRow();
            foreach (DataColumn c in dt.Columns)
            {
                drNew[c.Caption.Trim()] = dr[c];
            }
            dtNew.Rows.Add(drNew);
        }

        dg.DataSource = dtNew;
        dg.DataBind();

    }

    public static void FillGidArr()
    {
        DataTable dt = DBHelper.GetDataTable(" select distinct gid from limit_up ");
        gidArr = new Stock[dt.Rows.Count];
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            gidArr[i] = new Stock(dt.Rows[i][0].ToString());
            gidArr[i].LoadKLineDay(rc);
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
        <asp:DataGrid ID="dg" runat="server" Width="100%" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical">
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
