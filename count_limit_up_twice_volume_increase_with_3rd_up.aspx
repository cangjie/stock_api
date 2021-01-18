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
    public int limitUpSuc = 0;



    protected void Page_Load(object sender, EventArgs e)
    {



        DataTable dt = new DataTable();
        dt.Columns.Add("日期", Type.GetType("System.DateTime"));
        dt.Columns.Add("代码");
        dt.Columns.Add("名称");
        dt.Columns.Add("信号");
        dt.Columns.Add("缩量");
        dt.Columns.Add("买入");
        dt.Columns.Add("今涨", Type.GetType("System.Double"));

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
        dtNew.Columns.Add("今涨");
        dtNew.Columns.Add("买入");
        dtNew.Columns.Add("1日");
        dtNew.Columns.Add("2日");
        dtNew.Columns.Add("3日");
        dtNew.Columns.Add("4日");
        dtNew.Columns.Add("5日");
        dtNew.Columns.Add("总计");



        DataTable dtOri = DBHelper.GetDataTable(" select  * from limit_up first_up "
            + " where not exists (select 'a' from limit_up before_up where before_up.gid = first_up.gid and before_up.alert_date = dbo.func_GetLastTransactDate(first_up.alert_date, 1))  "
            + " and exists (select 'a' from limit_up second_up where second_up.gid = first_up.gid and first_up.alert_date = dbo.func_GetLastTransactDate(second_up.alert_date, 1) "
            + " and second_up.volume >= first_up.volume * 2.5) "
            + " order by first_up.alert_date desc ");
        foreach (DataRow drOri in dtOri.Rows)
        {

            try
            {
                Stock s = GetStock(drOri["gid"].ToString().Trim());

                int currentIndex = s.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString().Trim()));

                if (currentIndex <= 1 || currentIndex + 10 > s.kLineDay.Length)
                {
                    continue;
                }

                int buyIndex = currentIndex+2;
                if (dt.Select(" 日期 = '" + s.kLineDay[buyIndex].startDateTime.Date.ToShortDateString() + "' and 代码 = '" + s.gid.Trim() + "' ").Length == 0)
                {
                    DataRow dr = dt.NewRow();
                    dr["日期"] = s.kLineDay[buyIndex].startDateTime.Date;
                    dr["代码"] = s.gid.Trim();
                    dr["名称"] = s.Name.Trim();
                    dr["信号"] = "";
                    dr["缩量"] = Math.Round(100 * s.kLineDay[currentIndex].volume / s.kLineDay[currentIndex-1].volume, 2).ToString() + "%";
                    dr["今涨"] = 0;
                    double buyPrice = s.kLineDay[buyIndex].startPrice;
                    dr["买入"] = Math.Round(buyPrice, 2).ToString();
                    if (s.IsLimitUp(currentIndex + 2))
                    {
                        limitUpSuc++;
                    }
                    double maxPrice = 0;
                    for (int i = 1; i <= 5; i++)
                    {
                        maxPrice = Math.Max(maxPrice, s.kLineDay[buyIndex + i].endPrice);
                        dr[i.ToString() + "日"] = (s.kLineDay[buyIndex + i].endPrice - buyPrice) / buyPrice;
                    }
                    dr["总计"] = (maxPrice - buyPrice) / buyPrice;



                    if ((double)dr["总计"] >= 0.01)
                    {
                        suc++;
                        if ((double)dr["总计"] >= 0.05)
                        {
                            sucMax++;

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
    <div>涨幅过10%概率：<%= Math.Round(100*(double)sucMax/(double)count, 2).ToString() %>%</div>
    <div>三连板概率：<%= Math.Round(100*(double)limitUpSuc/(double)count, 2).ToString() %>%</div>
    
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
