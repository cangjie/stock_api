<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    //public static Stock[] gidArr;

    //public static Core.RedisClient rc = new Core.RedisClient("52.81.252.140");

    public static int count = 0;

    public static int success5 = 0;

    public static int success2 = 0;

    public static int success1 = 0;

    public static int fail = 0;


    protected void Page_Load(object sender, EventArgs e)
    {



        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.DateTime"));
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("买入");
        dt.Columns.Add("7日");
        dt.Columns.Add("8日");

        dt.Columns.Add("总计");

        DataTable dtNew = new DataTable();
        dtNew.Columns.Add("日期");
        dtNew.Columns.Add("代码");
        dtNew.Columns.Add("名称");
        dtNew.Columns.Add("买入");
        dtNew.Columns.Add("7日");
        dtNew.Columns.Add("8日");
        dtNew.Columns.Add("总计");

        success1 = 0;
        success2 = 0;
        success5 = 0;
        //DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up where next_day_cross_star_un_limit_up = 1 and alert_date <= '2019-10-24' order by alert_date desc");
        //string[] gidArr = new string[] { "sz002838"};//Util.GetAllGids();
        string[] gidArr = Util.GetAllGids();
        //foreach (Stock s  in gidArr)
        for(int m = 0; m < gidArr.Length; m++)
        {
            Stock s = new Stock(gidArr[m].Trim());
            s.LoadKLineDay(Util.rc);







            for (int i = 1; i < s.kLineDay.Length - 10; i++)
            {
                if (s.IsLimitUp(i - 1))
                {
                    continue;
                }
                if (!s.IsLimitUp(i))
                {
                    continue;
                }
                if (!s.IsLimitUp(i + 1))
                {
                    continue;
                }
                if (s.kLineDay[i + 2].lowestPrice > s.kLineDay[i + 1].highestPrice)
                {
                    continue;
                }
                if (!s.IsLimitUp(i + 3))
                {
                    continue;
                }
                if (s.kLineDay[i + 4].lowestPrice > s.kLineDay[i + 3].highestPrice)
                {
                    continue;
                }
                if (s.kLineDay[i + 5].startPrice <= s.kLineDay[i + 4].endPrice)
                {
                    continue;
                }
                double buyPrice = s.kLineDay[i + 5].startPrice;
                DataRow dr = dt.NewRow();
                dr["日期"] = s.kLineDay[i+7].startDateTime.Date;
                dr["代码"] = s.gid.Trim();
                dr["名称"] = s.Name.Trim();
                dr["买入"] = buyPrice;
                dr["7日"] = (s.kLineDay[i + 6].highestPrice - buyPrice) / buyPrice;
                dr["8日"] = (s.kLineDay[i + 7].highestPrice - buyPrice) / buyPrice;
                dr["总计"] = Math.Max(double.Parse(dr["7日"].ToString()),
                    double.Parse(dr["8日"].ToString()));
                if (double.Parse(dr["总计"].ToString()) > 0.1)
                {
                    success1++;
                }
                
                dt.Rows.Add(dr);

            }

        }

        count = dt.Rows.Count;


        //DataTable dtNew = dt.Clone();
        string lastDateString = "";
        string lastGid = "";
        foreach (DataRow dr in dt.Select("", "日期 desc"))
        {
            //if (dtNew.Rows[dtNew.Rows.Count - 1]["日期"].ToString()
            if (lastDateString.Trim().Equals(((DateTime)dr["日期"]).ToShortDateString()) && lastGid.Trim().Equals(dr["代码"].ToString()))
            {
                continue;
            }
            DataRow drNew = dtNew.NewRow();
            foreach (DataColumn c in dt.Columns)
            {
                drNew[c.Caption] = dr[c].ToString();
            }
            drNew["日期"] = ((DateTime)dr["日期"]).ToShortDateString();


            for (int i = 7; i <= 8; i++)
            {
                double rate = double.Parse(drNew[i.ToString()+"日"].ToString());
                drNew[i.ToString()+"日"] = "<font color=\"" + (rate >= 0.01 ? "red" : "green") + "\" >" + Math.Round((rate * 100), 2)+"%</font>";
            }
            double rateTotal = double.Parse(drNew["总计"].ToString());

            drNew["总计"] = "<font color=\"" + (rateTotal >= 0.01 ? "red" : "green") + "\" >" + Math.Round((rateTotal * 100), 2)+"%</font>";
            dtNew.Rows.Add(drNew);
            if (rateTotal < 0.01)
            {
                fail++;
            }
            lastDateString = ((DateTime)dr["日期"]).ToShortDateString();
            lastGid = dr["代码"].ToString();
        }


        dg.DataSource = dtNew;
        dg.DataBind();

    }



    public static double GetFirstLowestPrice(KLine[] kArr, int index, out int lowestIndex)
    {
        double ret = double.MaxValue;
        int find = 0;
        lowestIndex = 0;
        for (int i = index - 1; i > 0 && find < 2; i--)
        {
            double line3Pirce = KLine.GetAverageSettlePrice(kArr, i, 3, 3);
            ret = Math.Min(ret, kArr[i].lowestPrice);
            if (ret == kArr[i].lowestPrice)
            {
                lowestIndex = i;
            }
            if (kArr[i].endPrice < line3Pirce)
            {
                find = 1;
            }
            if (kArr[i].lowestPrice >= line3Pirce && find == 1)
            {
                find = 2;
            }
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
        
        成功：<%=success1.ToString() %> / <%=count.ToString() %> = <%=Math.Round(100 * (double)success1/count, 2).ToString() %>%<br />
        <asp:DataGrid runat="server" Width="100%" ID="dg" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" >
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
