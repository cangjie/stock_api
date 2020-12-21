﻿<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    public static Core.RedisClient rc = new Core.RedisClient("52.81.252.140");

    public  int suc = 0;
    public  int sucMax = 0;
    public  int count = 0;
    public int horseHeadSuc = 0;
    public int horseHeadCount = 0;



    protected void Page_Load(object sender, EventArgs e)
    {



        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.DateTime"));
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("信号");
        dt.Columns.Add("缩量");
        dt.Columns.Add("买入");
        //dt.Columns.Add("高开幅度", Type.GetType("System.Double"));

        dt.Columns.Add("1日", Type.GetType("System.Double"));
        dt.Columns.Add("2日", Type.GetType("System.Double"));
        dt.Columns.Add("3日", Type.GetType("System.Double"));
        dt.Columns.Add("4日", Type.GetType("System.Double"));
        dt.Columns.Add("5日", Type.GetType("System.Double"));
        dt.Columns.Add("总计", Type.GetType("System.Double"));


        DataTable dtNew = new DataTable();
        dtNew.Columns.Add("日期");
        dtNew.Columns.Add("代码");
        dtNew.Columns.Add("名称");
        dtNew.Columns.Add("信号");
        dtNew.Columns.Add("缩量");
        //dtNew.Columns.Add("高开幅度");
        dtNew.Columns.Add("买入");
        dtNew.Columns.Add("1日");
        dtNew.Columns.Add("2日");
        dtNew.Columns.Add("3日");
        dtNew.Columns.Add("4日");
        dtNew.Columns.Add("5日");
        dtNew.Columns.Add("总计");



        DataTable dtOri = DBHelper.GetDataTable(" select  alert_date, gid from limit_up a where alert_date  >= '2019-1-1' and not exists("
            + " select 'a' from limit_up b where a.gid = b.gid and (a.alert_date = dbo.func_GetLastTransactDate(b.alert_date, 2) or a.alert_date = dbo.func_GetLastTransactDate(b.alert_date, 1)) )  order by alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {
            bool isHorseHead = false;
            try
            {
                Stock s = GetStock(drOri["gid"].ToString().Trim());
                int currentIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
                if (currentIndex < 0)
                {
                    continue;
                }

                if (currentIndex + 7 >= s.kLineDay.Length)
                {
                    continue;
                }

                if (s.kLineDay[currentIndex].volume  < s.kLineDay[currentIndex + 1].volume)
                {
                    continue;
                }
                if (s.kLineDay[currentIndex + 2].highestPrice < s.kLineDay[currentIndex + 1].highestPrice
                    || s.kLineDay[currentIndex + 2].highestPrice < s.kLineDay[currentIndex].highestPrice)
                {
                    continue;
                }

                if (dt.Select(" 日期 = '" + s.kLineDay[currentIndex+2].startDateTime.Date.ToShortDateString() + "' and 代码 = '" + s.gid.Trim() + "' ").Length == 0)
                {
                    DataRow dr = dt.NewRow();
                    dr["日期"] = s.kLineDay[currentIndex+2].startDateTime.Date;
                    dr["代码"] = s.gid.Trim();
                    dr["名称"] = s.Name.Trim();
                    dr["缩量"] = Math.Round(100 * s.kLineDay[currentIndex + 1].volume / s.kLineDay[currentIndex].volume, 2).ToString() + "%";
                    //dr["高开幅度"] = (s.kLineDay[currentIndex + 2].startPrice - s.kLineDay[currentIndex + 1].endPrice) / s.kLineDay[currentIndex + 1].endPrice;
                    double buyPrice = s.kLineDay[currentIndex + 2].endPrice;
                    dr["买入"] = Math.Round(buyPrice, 2).ToString();
                    double maxPrice = 0;
                    for (int i = 1; i <= 5; i++)
                    {
                        maxPrice = Math.Max(maxPrice, s.kLineDay[currentIndex + 2 + i].highestPrice);
                        dr[i.ToString() + "日"] = (s.kLineDay[currentIndex + 2 + i].highestPrice - buyPrice) / buyPrice;
                    }
                    dr["总计"] = (maxPrice - buyPrice) / buyPrice;
                    if (s.kLineDay[currentIndex - 1].endPrice > s.kLineDay[currentIndex - 2].endPrice
                        && s.kLineDay[currentIndex - 1].startPrice > s.kLineDay[currentIndex - 2].endPrice)
                    {
                        isHorseHead = true;
                        horseHeadCount++;
                        dr["信号"] = "🐴";
                    }
                    if ((double)dr["总计"] >= 0.01)
                    {
                        suc++;
                        if ((double)dr["总计"] >= 0.05)
                        {
                            sucMax++;
                            if (isHorseHead)
                            {
                                horseHeadSuc++;
                            }
                        }
                    }
                    dt.Rows.Add(dr);
                }
            }
            catch
            {

            }
        }

        count = dt.Rows.Count;

        //DataTable dtNew = dt.Clone();
        foreach (DataRow dr in dt.Select("", "日期 desc"))
        {
            DataRow drNew = dtNew.NewRow();
            foreach (DataColumn c in dt.Columns)
            {
                if (c.DataType.FullName.ToString().Equals("System.Double"))
                {
                    double value = double.Parse(dr[c].ToString());
                    drNew[c.Caption] = "<font color='" + ((value < 0.01) ? "green" : "red") + "' >"
                        + Math.Round(100 * value, 2).ToString() + "%</font>";
                }
                else
                {
                    drNew[c.Caption] = dr[c].ToString();
                }
            }
            drNew["日期"] = ((DateTime)dr["日期"]).ToShortDateString();
            dtNew.Rows.Add(drNew);
        }


        dg.DataSource = dtNew;
        dg.DataBind();

    }



    public Stock GetStock(string gid)
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
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>涨幅过1%概率：<%= Math.Round(100*(double)suc/(double)count, 2).ToString() %>%</div>
    <div>涨幅过5%概率：<%= Math.Round(100*(double)sucMax/(double)count, 2).ToString() %>%</div>
    <div>马头涨幅过5%概率：<%= Math.Round(100*(double)horseHeadSuc/(double)horseHeadCount, 2).ToString() %>%</div>
    <div>
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