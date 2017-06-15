<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public DataTable dt = new DataTable();
    public DateTime startDate;
    public DateTime endDate;

    protected void Page_Load(object sender, EventArgs e)
    {
        startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", "2016-7-1"));
        endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", "2016-9-1"));
        dt.Columns.Add("代码");
        dt.Columns.Add("日期");
        dt.Columns.Add("收盘价");
        dt.Columns.Add("3线价格");
        dt.Columns.Add("跳空价");
        dt.Columns.Add("3日最高");
        dt.Columns.Add("3日涨幅");
        dt.Columns.Add("5日最高");
        dt.Columns.Add("5日涨幅");
        for (int i = 1; i < 700; i++)
        {
            try
            {
                KLine[] kArr = KLine.GetKLine("day", "3" + i.ToString().PadLeft(5, '0'),
                    startDate.AddMonths(-1), endDate.AddMonths(1));
                FillTable(kArr);
            }
            catch
            {

            }
        }

        dg.DataSource = dt;
        dg.DataBind();
    }

    public void FillTable(KLine[] kArr)
    {
        for (int i = 0; i < kArr.Length; i++)
        {
            if (kArr[i].startDateTime >= startDate && kArr[i].endDateTime < endDate)
            {
                if (IsMatch(kArr, i))
                {
                    DataRow dr = dt.NewRow();
                    dr["代码"] = kArr[i].gid.Trim();
                    dr["日期"] = kArr[i].startDateTime.ToShortDateString();
                    dr["收盘价"] = kArr[i].endPrice;
                    dr["3线价格"] = Compute_3_3_Price(kArr, kArr[i].startDateTime);
                    dr["跳空价"] = kArr[i + 1].startPrice;
                    dr["3日最高"] = GetMaxPrice(kArr, i + 1, i + 3);
                    dr["3日涨幅"] = GetMaxPrice(kArr, i + 1, i + 3) - kArr[i+1].startPrice;
                    dr["5日最高"] = GetMaxPrice(kArr, i + 1, i + 5);
                    dr["5日涨幅"] = GetMaxPrice(kArr, i + 1, i + 5) - kArr[i + 1].startPrice;
                    dt.Rows.Add(dr);
                }
            }
        }
    }

    public bool IsMatch(KLine[] kArr, int i)
    {
        bool ret = false;
        if (Compute_3_3_Price(kArr, kArr[i].startDateTime) > kArr[i].endPrice
            && Compute_3_3_Price(kArr, kArr[i + 1].startDateTime) < kArr[i + 1].startPrice
            && kArr[i+1].startPrice > kArr[i].endPrice )
        {
            ret = true;
        }
        return ret;
    }

    public double Compute_3_3_Price(KLine[] kArr, DateTime date)
    {
        double ret = 0;
        for (int i = 5; i < kArr.Length; i++)
        {
            if (kArr[i].startDateTime == date)
            {
                ret = (kArr[i - 5].endPrice + kArr[i - 4].endPrice + kArr[i - 3].endPrice) / 3;
                break;
            }
        }
        return ret;
    }

    public double GetNextPrice(KLine[] kArr, DateTime currentDate, int nextDays)
    {
        double ret = 0;
        for (int i = 5; i < kArr.Length; i++)
        {
            if (kArr[i].startDateTime == currentDate)
            {
                ret = kArr[i + nextDays].endPrice;
                break;
            }
        }
        return ret;
    }

    public double GetMaxPrice(KLine[] kArr, int startIndex, int endIndex)
    {
        double ret = 0;
        for (int i = startIndex; i <= endIndex; i++)
        {
            ret = Math.Max(ret, kArr[i].highestPrice);
        }
        return ret;
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <asp:DataGrid runat="server" ID="dg" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" Width="100%" >
            <AlternatingItemStyle BackColor="#DCDCDC"  />
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
