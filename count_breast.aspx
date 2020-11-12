<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">



    public static int count = 0;

    public static int success = 0;

    public static int notFail = 0;

    public static int fail = 0;




    protected void Page_Load(object sender, EventArgs e)
    {

        //FillStockArr();

        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.DateTime"));
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("板数", Type.GetType("System.Int32"));
        dt.Columns.Add("买入", Type.GetType("System.Double"));
        dt.Columns.Add("1日");
        dt.Columns.Add("2日");
        dt.Columns.Add("3日");
        dt.Columns.Add("4日");
        dt.Columns.Add("5日");
        dt.Columns.Add("总计");

        DataTable dtNew = new DataTable();
        dtNew.Columns.Add("日期");
        dtNew.Columns.Add("代码");
        dtNew.Columns.Add("名称");
        dtNew.Columns.Add("板数");
        dtNew.Columns.Add("买入");
        dtNew.Columns.Add("1日");
        dtNew.Columns.Add("2日");
        dtNew.Columns.Add("3日");
        dtNew.Columns.Add("4日");
        dtNew.Columns.Add("5日");
        dtNew.Columns.Add("总计");

        string[] gidArr = Util.GetAllGids();
        //DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up where next_day_cross_star_un_limit_up = 1 and alert_date <= '2019-10-24' order by alert_date desc");
        for (int m = 0; m < gidArr.Length; m++ )
        {
            Stock s = new Stock(gidArr[m].Trim());
            s.LoadKLineDay(Util.rc);
            for (int i = s.kLineDay.Length-1-5-1; i >= 4; i--)
            {
                double line3Current = s.GetAverageSettlePrice(i, 3, 3);
                double settle = s.kLineDay[i].endPrice;
                double low = s.kLineDay[i].lowestPrice;
                double nextOpen = s.kLineDay[i + 1].startPrice;
                double line3Next = s.GetAverageSettlePrice(i + 1, 3, 3);
                if (!(s.GetAverageSettlePrice(i - 1, 3, 3) < line3Current && line3Current < line3Next
                    && line3Next < s.GetAverageSettlePrice(i + 2, 3, 3) && s.GetAverageSettlePrice(i + 2, 3, 3) < s.GetAverageSettlePrice(i + 3, 3, 3)))
                {
                    continue;
                }
                if (s.kLineDay[i].startPrice <= 0 || s.kLineDay[i].endPrice <= 0 || s.kLineDay[i].highestPrice <= 0 || s.kLineDay[i].endPrice <= 0)
                {
                    continue;
                }
                if (low >= line3Current * 1.05)
                {
                    continue;
                }
                if (settle <= line3Current)
                {
                    continue;
                }
                if (nextOpen <= settle || nextOpen <= line3Next)
                {
                    continue;
                }
                int cross3LineTimes = 0;
                int startIndex = 0;
                for (int j = i-1; j >= 0 && cross3LineTimes < 2; j--)
                {
                    double line3Temp = s.GetAverageSettlePrice(j, 3, 3);
                    if (cross3LineTimes == 0 && s.kLineDay[j].endPrice < line3Temp)
                    {
                        cross3LineTimes++;
                    }
                    if (cross3LineTimes == 1 && s.kLineDay[j].endPrice > line3Temp)
                    {
                        cross3LineTimes++;
                    }
                    if (cross3LineTimes == 2)
                    {
                        startIndex = j;
                        break;
                    }
                }
                if (startIndex == 0)
                {
                    continue;
                }


                double lowestPrice = double.MaxValue;
                double highestPrice = 0;
                int lowestIndex = 0;

                for (int j = startIndex; j <= i; j++)
                {
                    if (s.kLineDay[j].lowestPrice > 0)
                    {
                        if (lowestPrice >= s.kLineDay[j].lowestPrice)
                        {
                            lowestPrice = s.kLineDay[j].lowestPrice;
                            lowestIndex = j;
                        }
                    }
                    highestPrice = Math.Max(highestPrice, s.kLineDay[j].highestPrice);
                }
                if (lowestPrice <= 0 || highestPrice <= 0)
                {
                    continue;
                }

                int limitUpNum = 0;
                for (int j = lowestIndex; j <= i; j++)
                {
                    if (s.IsLimitUp(j))
                    {
                        limitUpNum++;
                    }
                }
                if (limitUpNum < 2)
                {
                    continue;
                }

                highestPrice = Math.Max(highestPrice, s.kLineDay[i + 1].highestPrice);
                double f5 = highestPrice - (highestPrice - lowestPrice) * 0.618;
                DataRow dr = dt.NewRow();
                dr["日期"] = s.kLineDay[i+1].startDateTime.Date;
                dr["代码"] = s.gid.Trim();
                dr["名称"] = s.Name.Trim();
                dr["板数"] = limitUpNum;
                dr["买入"] = nextOpen;
                double buyPrice = nextOpen;
                double maxRate = 0;
                bool lessF5 = false;
                for (int j = 1; j <= 5; j++)
                {
                    double rate = (s.kLineDay[i+ 1 + j].highestPrice - buyPrice) / buyPrice;
                    maxRate = Math.Max(maxRate, rate);
                    //dr[i.ToString() + "日"] = "<font color=\"" + (rate >= 0.01 ? "red" : "green") + "\" >" + Math.Round((rate * 100), 2)+"%</font>";
                    dr[j.ToString() + "日"] = rate;
                    if (s.kLineDay[i + 1 + j].endPrice < f5)
                    {
                        lessF5 = true;
                    }
                }
                //dr["总计"] = "<font color=\"" + (maxRate >= 0.01 ? "red" : "green") + "\" >" + Math.Round((maxRate * 100), 2)+"%</font>";
                dr["总计"] = maxRate;

                count++;
                if (maxRate >= 0.05)
                {
                    success++;
                }
                if (maxRate >= 0.01)
                {
                    notFail++;
                }
                if (lessF5)
                {
                    fail++;
                }
                dt.Rows.Add(dr);
            }

        }



        //DataTable dtNew = dt.Clone();
        foreach (DataRow dr in dt.Select("", "日期 desc"))
        {
            DataRow drNew = dtNew.NewRow();
            foreach (DataColumn c in dt.Columns)
            {
                drNew[c.Caption] = dr[c].ToString();
            }
            drNew["日期"] = ((DateTime)dr["日期"]).ToShortDateString();


            for (int i = 1; i <= 5; i++)
            {
                double rate = double.Parse(drNew[i.ToString()+"日"].ToString());
                drNew[i.ToString()+"日"] = "<font color=\"" + (rate >= 0.01 ? "red" : "green") + "\" >" + Math.Round((rate * 100), 2)+"%</font>";
            }
            double rateTotal = double.Parse(drNew["总计"].ToString());
            drNew["总计"] = "<font color=\"" + (rateTotal >= 0.01 ? "red" : "green") + "\" >" + Math.Round((rateTotal * 100), 2)+"%</font>";
            dtNew.Rows.Add(drNew);
        }


        dg.DataSource = dtNew;
        dg.DataBind();

    }


</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <%=success.ToString() %> / <%=count.ToString() %> = <%=Math.Round(100 * (double)success/count, 2).ToString() %>%
        <%=notFail.ToString() %> / <%=count.ToString() %> = <%=Math.Round(100 * (double)notFail/count, 2).ToString() %>%
        <%=fail.ToString() %> / <%=count.ToString() %> = <%=Math.Round(100 * (double)fail/count, 2).ToString() %>%
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
