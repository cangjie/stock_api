<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<script runat="server">

    

    public static ArrayList gidArr = new ArrayList();

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime startDate = GetStartDate();
        for(DateTime i = startDate; i <= DateTime.Now.Date; i = i.AddDays(1))
        {
            if (Util.IsTransacDay(i))
            {
                SearchReverse(i);
            }
        }
    }


    public void SearchReverse(DateTime currentDate)
    {
        DataTable dtOri = DBHelper.GetDataTable(" select * from limit_up where alert_date >= '" + Util.GetLastTransactDate(currentDate, 20).ToShortDateString()
            + "' and alert_date <= '" + currentDate.ToShortDateString() + "' order by alert_date ");
        foreach (DataRow drOri in dtOri.Rows)
        {
            string gid = drOri["gid"].ToString().Trim();
            Stock stock = GetStock(gid);
            if (stock == null && currentDate != DateTime.Now.Date)
            {
                stock = new Stock(gid);
                stock.LoadKLineDay(Util.rc);
                gidArr.Add(stock);
            }
            if (currentDate == DateTime.Now.Date)
            {
                stock = new Stock(gid);
                stock.LoadKLineDay(Util.rc);
            }

            int currentIndex = stock.GetItemIndex(currentDate);
            if (currentIndex == -1)
            {
                continue;
            }

            int limitUpIndex = stock.GetItemIndex(DateTime.Parse(drOri["alert_date"].ToString()));
            if (limitUpIndex == -1)
            {
                continue;
            }

            int highIndex = 0;
            double highestPrice = 0;
            for (int i = limitUpIndex; i < currentIndex; i++)
            {
                if (highestPrice < stock.kLineDay[i].highestPrice)
                {
                    highestPrice = stock.kLineDay[i].highestPrice;
                    highIndex = i;
                }
            }

            int lowestIndex = 0;
            double lowestPrice = GetFirstLowestPrice(stock.kLineDay, limitUpIndex, out lowestIndex);

            if (lowestPrice == double.MaxValue)
            {
                continue;
            }

            double f3 = highestPrice - (highestPrice - lowestPrice) * 0.382;
            double f5 = highestPrice - (highestPrice - lowestPrice) * 0.618;
            string type = "";
            if (stock.kLineDay[currentIndex].lowestPrice <= f5)
            {
                type = "f5";
            }
            else if (stock.kLineDay[currentIndex].lowestPrice <= f3)
            {
                type = "f3";
            }
            if (!type.Trim().Equals(""))
            {
                SaveLowestPoint(currentDate, gid, highestPrice, f3, f5, lowestPrice, stock.kLineDay[currentIndex].lowestPrice, type);
            }

        }
    }

    public static void SaveLowestPoint(DateTime logDate, string gid, double highestPrice, double f3,
        double f5, double lowestPrice, double currentLowestPrice, string type)
    {
        string sql = " select * from alert_reverse where  gid = '" + gid.Trim()
            + "' and alert_type = '" + type.Trim() + "' and high = " + Math.Round(highestPrice, 4).ToString() + " and low = " + Math.Round(lowestPrice, 4).ToString()
            + " and alert_date >= '" + Util.GetLastTransactDate(logDate, 10).ToShortDateString()
            + "' and alert_date <= '" + logDate.AddDays(10).ToShortDateString() + "' ";
        try
        {
            DataTable dt = DBHelper.GetDataTable(sql);
            if (dt.Rows.Count == 0)
            {
                try
                {
                    DBHelper.InsertData("alert_reverse", new string[,] {
                {"gid", "varchar", gid.Trim() },
                {"alert_date", "datetime", logDate.ToShortDateString() },
                {"alert_type", "varchar", type.Trim() },
                {"high", "float", Math.Round(highestPrice, 4).ToString() },
                {"f3", "float", Math.Round(f3, 4).ToString() },
                {"f5", "float", Math.Round(f5, 4).ToString() },
                {"low", "float", Math.Round(lowestPrice, 4).ToString() },
                {"current_lowest_price", "float", currentLowestPrice.ToString() },
                {"range", "float", Math.Round(((highestPrice - lowestPrice)/lowestPrice), 4).ToString() }
                });
                }
                catch
                {

                }
            }
            dt.Dispose();
        }
        catch
        {
            System.Diagnostics.Debug.WriteLine(sql);
        }
    }

    public static double GetFirstLowestPrice(KLine[] kArr, int index, out int lowestIndex)
    {
        double ret = double.MaxValue;
        int find = 0;
        lowestIndex = 0;
        for (int i = index; i > 0 && find < 2; i--)
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


    public static Stock GetStock(string gid)
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
        if (found)
        {
            return s;
        }
        else
        {
            return null;
        }
    }

    public DateTime GetStartDate()
    {
        DateTime startDate = DateTime.Parse("2017-9-1");
        if (!Util.GetSafeRequestValue(Request, "date", "").Equals(""))
        {
            try
            {
                startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", ""));
                if (startDate == DateTime.Parse("1900-1-1"))
                {
                    startDate = DateTime.Now.Date;
                }
            }
            catch
            {

            }
        }
        //startDate = DateTime.Parse("2019-6-11");
        return startDate;
    }


</script>