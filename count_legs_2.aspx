<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public int suc = 0;
    public int newHighSuc = 0;
    public int count = 0;
    public int newHighCount = 0;

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
        dt.Columns.Add("买入");
        dt.Columns.Add("1日");
        dt.Columns.Add("2日");
        dt.Columns.Add("3日");
        dt.Columns.Add("4日");
        dt.Columns.Add("5日");
        dt.Columns.Add("总计");
        DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up order by alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {
            bool newHigh = true;

            
            Stock s = GetStock(drOri["gid"].ToString().Trim());



            int currentIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (currentIndex + 7 >= s.kLineDay.Length)
            {
                continue;
            }



            int countIndex = 0;

            if (Math.Abs(s.kLineDay[currentIndex + 1].lowestPrice - s.kLineDay[currentIndex].lowestPrice) / s.kLineDay[currentIndex].lowestPrice < 0.005
                || Math.Abs(s.kLineDay[currentIndex + 1].lowestPrice - s.kLineDay[currentIndex - 1].lowestPrice) / s.kLineDay[currentIndex - 1].lowestPrice < 0.005)
            {
                countIndex = currentIndex + 1;
            }
            else if (Math.Abs(s.kLineDay[currentIndex + 2].lowestPrice - s.kLineDay[currentIndex].lowestPrice) / s.kLineDay[currentIndex].lowestPrice < 0.005
                || Math.Abs(s.kLineDay[currentIndex + 2].lowestPrice - s.kLineDay[currentIndex + 1].lowestPrice) / s.kLineDay[currentIndex + 1].lowestPrice < 0.005)
            {
                countIndex = currentIndex + 2;
            }


            if (countIndex == 0 || !s.IsLimitUp(currentIndex - 1) || !s.IsLimitUp(countIndex)
                || dt.Select(" 日期 = '" + s.kLineDay[countIndex].startDateTime.Date.ToShortDateString() + "' and 代码 =  '" + s.gid.Trim() + "' " ).Length > 0)
            {
                continue;
            }


            int buyIndex = countIndex;

            double buyPrice = s.kLineDay[countIndex].endPrice;
            DataRow dr = dt.NewRow();
            dr["日期"] = s.kLineDay[countIndex].endDateTime.ToShortDateString();
            dr["代码"] = s.gid.Trim();
            dr["名称"] = s.Name.Trim();
            dr["买入"] = buyPrice.ToString();

            double finalRate = double.MinValue;
            for (int j = 1; j <= 5; j++)
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
                if (newHigh)
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

</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
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
