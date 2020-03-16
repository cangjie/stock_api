﻿<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public static int count = 0;

    public int limitUpTriCount = 0;

    public int limitUpTriSuc = 0;

    public int limitUpTriEarn = 0;

    public int horseHeadCount = 0;

    public int horseHeadSuc = 0;

    public int horseHeadEarn = 0;

    public int sortCaseCount = 0;

    public int sortCaseSuc = 0;

    public int sortCaseEarn = 0;

    public int downCount = 0;

    public int downSuc = 0;

    public int downEarn = 0;

    public static string buyPoint = "open";

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

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            buyPoint = Util.GetSafeRequestValue(Request, "buypoint", "open");
            DataTable dt = GetData();
            dg.DataSource = RenderHtml(dt.Select("", ""));
            dg.DataBind();
        }
    }

    public DataTable RenderHtml(DataRow[] drArr)
    {

        DataTable dt = new DataTable();
        if (drArr.Length == 0)
            return dt;
        for (int i = 0; i < drArr[0].Table.Columns.Count; i++)
        {
            dt.Columns.Add(drArr[0].Table.Columns[i].Caption.Trim(), Type.GetType("System.String"));
        }
        foreach (DataRow drOri in drArr)
        {
            DataRow dr = dt.NewRow();
            //double settle = Math.Round((double)drOri["昨收"], 2);
            for (int i = 0; i < drArr[0].Table.Columns.Count; i++)
            {

                if (drArr[0].Table.Columns[i].DataType.FullName.ToString().Equals("System.Double"))
                {
                    switch (drArr[0].Table.Columns[i].Caption.Trim())
                    {
                        case "综指":
                        case "昨收":
                        case "MACD率":
                        case "KDJ率":
                            dr[i] = Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2).ToString();
                            break;
                        case "买入":
                            double buyPrice = Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2);
                            dr[i] = Math.Round((double)drOri[drArr[0].Table.Columns[i].Caption.Trim()], 2).ToString();
                            break;
                        case "今开":
                        case "现价":
                        case "前低":
                        case "F1":
                        case "F3":
                        case "F5":
                        case "现高":

                        default:
                            if (System.Text.RegularExpressions.Regex.IsMatch(drArr[0].Table.Columns[i].Caption.Trim(), "\\d日")
                                || drArr[0].Table.Columns[i].Caption.Trim().Equals("总计"))
                            {
                                if (!drOri[i].ToString().Equals(""))
                                {
                                    double currentValue = (double)drOri[i];
                                    currentValue = Math.Round(currentValue * 100, 2);
                                    dr[i] = "<font color=\"" + (currentValue >= 1 ? "red" : "green") + "\" >" + currentValue.ToString().Trim() + "%</font>";
                                }
                                else
                                {
                                    dr[i] = "--";
                                }
                            }
                            else
                            {
                                double currentValue = (double)drOri[i];
                                dr[i] = Math.Round(currentValue * 100, 2).ToString() + "%";
                            }
                            break;
                    }
                }
                else
                {
                    dr[i] = drOri[i].ToString();
                }
            }
            dr["代码"] = "<a href=\"show_K_line_day.aspx?gid=" + dr["代码"].ToString() + "\" target=\"_blank\" >" + dr["代码"].ToString() + "</a>";
            dt.Rows.Add(dr);
        }
        //AddTotal(drArr, dt);
        return dt;
    }


    public DataTable GetData()
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.String"));
        dt.Columns.Add("信号", Type.GetType("System.String"));
        dt.Columns.Add("代码", Type.GetType("System.String"));
        dt.Columns.Add("名称", Type.GetType("System.String"));
        dt.Columns.Add("连板", Type.GetType("System.Int32"));
        dt.Columns.Add("调整", Type.GetType("System.Int32"));
        dt.Columns.Add("买入", Type.GetType("System.Double"));
        for (int i = 1; i <= 5; i++)
        {
            dt.Columns.Add(i.ToString() + "日", Type.GetType("System.Double"));
        }
        dt.Columns.Add("总计", Type.GetType("System.Double"));

        DataTable dtOri = DBHelper.GetDataTable("select  * from limit_up a where exists(select 'a' from limit_up b where a.gid = b.gid and b.alert_date = dbo.func_GetLastTransactDate(a.alert_date, 1)) "
            // + " and gid = 'sz300643' " 
            + " and alert_date <= '" + Util.GetLastTransactDate(DateTime.Now.Date, 10).ToShortDateString() + "' "
            + " order by a.alert_date desc"
            );
        foreach (DataRow drOri in dtOri.Rows)
        {
            Stock stock = GetStock(drOri["gid"].ToString());
            int currentIndex = stock.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));

            if (currentIndex < 1)
            {
                continue;
            }
            if (currentIndex + 14 > stock.kLineDay.Length - 1)
            {
                continue;
            }

            if (stock.kLineDay[currentIndex + 1].highestPrice <= stock.kLineDay[currentIndex].endPrice)
            {
                continue;
            }

            int continousLimitUpNum = 0;

            for (int i = currentIndex; i >= 0 && stock.IsLimitUp(i); i--)
            {
                continousLimitUpNum++;
            }
            if (continousLimitUpNum <= 1)
            {
                continue;
            }

            int lowestIndex = 0;
            double lowestPrice = double.MaxValue;

            lowestPrice = GetFirstLowestPrice(stock.kLineDay, currentIndex, out lowestIndex);

            double highestPrice = stock.kLineDay[currentIndex + 1].highestPrice;

            double f5 = highestPrice - (highestPrice - lowestPrice) * 0.618;

            int adjustNum = 0;

            bool newHigh = false;

            for (int i = currentIndex + 1; adjustNum <= 5 && i < stock.kLineDay.Length && stock.kLineDay[i].lowestPrice >= f5 * 1.005; i++)
            {
                if (stock.kLineDay[currentIndex + 1].highestPrice <= stock.kLineDay[i].highestPrice && i > currentIndex + 1)
                {
                    newHigh = true;
                    break;
                }
                adjustNum++;
            }

            if (newHigh)
            {
                continue;
            }

            if (adjustNum > 5)
            {
                continue;
            }


            double buyPrice = Math.Max(f5, stock.kLineDay[currentIndex + adjustNum].lowestPrice);


            DataRow dr = dt.NewRow();
            dr["日期"] = stock.kLineDay[currentIndex+1+adjustNum].startDateTime.ToShortDateString();
            dr["代码"] = stock.gid;
            dr["名称"] = stock.Name.Trim();
            dr["买入"] = buyPrice;
            dr["连板"] = continousLimitUpNum;
            dr["调整"] = adjustNum;
            double maxPrice = 0;
            for (int i = 1; i <= 5; i++)
            {
                maxPrice = Math.Max(maxPrice, stock.kLineDay[currentIndex + adjustNum + i].highestPrice);
                dr[i.ToString() + "日"] = (stock.kLineDay[currentIndex + adjustNum + i].highestPrice - buyPrice) / buyPrice;
            }
            double totalRate = (maxPrice - buyPrice) / buyPrice;
            dr["总计"] = totalRate;
            if (stock.IsLimitUp(currentIndex + 1))
            {
                limitUpTriCount++;
                if (totalRate >= 0.01)
                {
                    limitUpTriSuc++;
                }
                if (totalRate >= 0.05)
                {
                    limitUpTriEarn++;
                }
                dr["信号"] = dr["信号"].ToString() + "涨停";
            }
            if (!stock.IsLimitUp(currentIndex + 1) && stock.kLineDay[currentIndex + 1].lowestPrice > stock.kLineDay[currentIndex].endPrice)
            {
                horseHeadCount++;
                if (totalRate >= 0.01)
                {
                    horseHeadSuc++;
                }
                if (totalRate >= 0.05)
                {
                    horseHeadEarn++;
                }
                dr["信号"] = dr["信号"].ToString() + "马头";
            }
            if (!stock.IsLimitUp(currentIndex + 1) && Math.Min(stock.kLineDay[currentIndex + 1].startPrice, stock.kLineDay[currentIndex + 1].endPrice) > stock.kLineDay[currentIndex].endPrice
                && stock.kLineDay[currentIndex + 1].lowestPrice <= stock.kLineDay[currentIndex].endPrice)
            {
                sortCaseCount++;
                if (totalRate >= 0.01)
                {
                    sortCaseSuc++;
                }
                if (totalRate >= 0.05)
                {
                    sortCaseEarn++;
                }
                dr["信号"] = dr["信号"].ToString() + "剑鞘";
            }
            if (!stock.IsLimitUp(currentIndex + 1) && stock.kLineDay[currentIndex + 1].endPrice <= stock.kLineDay[currentIndex].endPrice)
            {
                downCount++;
                if (totalRate >= 0.01)
                {
                    downSuc++;
                }
                if (totalRate >= 0.05)
                {
                    downEarn++;
                }
                dr["信号"] = dr["信号"].ToString() + "下跌";
            }


            dt.Rows.Add(dr);
        }
        count = dt.Rows.Count;
        return dt;
    }

    public string ShowPercent(int num, int count)
    {
        return Math.Round(100 * (double)num / count, 2).ToString() + "%";
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
        <table style="width:100%" >
            <tr>
                <td>涨停：<%=ShowPercent(limitUpTriCount, count) %></td>
                <td>1%：<%=ShowPercent(limitUpTriSuc, limitUpTriCount) %></td>
                <td>5%：<%=ShowPercent(limitUpTriEarn, limitUpTriCount) %></td>
            </tr>
            <tr>
                <td>马头：<%=ShowPercent(horseHeadCount, count) %></td>
                <td>1%：<%=ShowPercent(horseHeadSuc, horseHeadCount) %> </td>
                <td>5%：<%=ShowPercent(horseHeadEarn, horseHeadCount) %></td>
            </tr>
            <tr>
                <td>剑鞘：<%=ShowPercent(sortCaseCount, count) %></td>
                <td>1%：<%=ShowPercent(sortCaseSuc, sortCaseCount) %> </td>
                <td>5%：<%=ShowPercent(sortCaseEarn, sortCaseCount) %></td>
            </tr>
            <tr>
                <td>下跌：<%=ShowPercent(downCount, count) %></td>
                <td>1%：<%=ShowPercent(downSuc, downCount) %></td>
                <td>5%：<%=ShowPercent(downEarn, downCount) %></td>
            </tr>
        </table>

    </div>

    <div>
       
        <div><asp:DataGrid ID="dg" runat="server" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" Width="100%">
            <AlternatingItemStyle BackColor="#DCDCDC" />
            <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
            <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
            <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
            <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
            <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
            </asp:DataGrid></div>
    </div>
    </form>
</body>
</html>