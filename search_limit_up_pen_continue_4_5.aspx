<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>

<script runat="server">

    public static Core.RedisClient rc = new Core.RedisClient("127.0.0.1");

    public static Stock[] gidArr;

    public DataTable dt;

    public static int count = 0;

    protected void Page_Load(object sender, EventArgs e)
    {
        FillGidArr();

        dt = new DataTable();
        dt.Columns.Add("日期");
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("买入");
        dt.Columns.Add("1日");


        DateTime startDate = DateTime.Now.Date.AddDays(-7);

        foreach (Stock s in gidArr)
        {
            int startIndex = s.GetItemIndex(startDate);
            for (int i = startIndex; i >= 7; i--)
            {
                if (!s.IsLimitUp(i) && s.IsLimitUp(i - 1) && s.IsLimitUp(i - 2) && s.IsLimitUp(i - 4) )
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
                        try
                        {
                            DataRow dr = dt.NewRow();
                            dr["日期"] = s.kLineDay[i].startDateTime.ToShortDateString();
                            dr["名称"] = s.Name.Trim();
                            dr["代码"] = s.gid.Trim();
                            double buyPrice = s.kLineDay[i].endPrice;
                            dr["买入"] = Math.Round(buyPrice, 2).ToString();
                            double maxPrice = s.kLineDay[i + 1].highestPrice;
                            double rate = (s.kLineDay[i + 1].endPrice - buyPrice) / buyPrice;
                            dr["1日"] = "<font color=\"" + ((rate > 0.01) ? "red" : "green") + "\" >" + Math.Round(rate * 100, 2).ToString() + "%</a>";
                            dt.Rows.Add(dr);
                            if (rate > 0.0975 && s.kLineDay[i + 1].endPrice == s.kLineDay[i + 1].highestPrice)
                            {
                                count++;
                            }
                        }
                        catch
                        {

                        }
                    }


                }
            }
        }





        dg.DataSource = dt;
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
        <%=Math.Round(100*(double)count/(double)dt.Rows.Count, 2).ToString() %>%<br />
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
