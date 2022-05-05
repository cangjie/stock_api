<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>

<script runat="server">

    public  ArrayList gidArr = new ArrayList();

    protected void Page_Load(object sender, EventArgs e)
    {
        DataTable dt = DBHelper.GetDataTable(" select * from big_rise ");

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            Stock s = GetStock(dt.Rows[i]["gid"].ToString());
            s.LoadKLineDay(Util.rc);
            DateTime currentDate = DateTime.Parse(dt.Rows[i]["start_date"].ToString());
            int currentIndex = s.GetItemIndex(currentDate);
            if (currentIndex < 0 || currentIndex >= s.kLineDay.Length)
            {
                continue;
            }
            int lowIndex = -1;
            DateTime settleHighDate = DateTime.Parse(dt.Rows[i]["high_date"].ToString());
            int settleHighIndex = s.GetItemIndex(settleHighDate);
            int highIndex = -1;
            double highPrice = 0;
            for (int j = currentIndex; j <= settleHighIndex; j++)
            {
                if (s.kLineDay[j].highestPrice > highPrice)
                {
                    highIndex = j;
                    highPrice = s.kLineDay[j].highestPrice;
                }
            }

            if (highPrice == 0)
            {
                continue;
            }

            double lowPrice = GetFirstLowestPrice(s.kLineDay, currentIndex, out lowIndex);
            if (highIndex <= lowIndex || highIndex >= s.kLineDay.Length || lowIndex < 0)
            {
                continue;
            }

            double f5 = highPrice - (highPrice - lowPrice) * 0.618;

            for (int j = highIndex; j <= highIndex + 60 && j < s.kLineDay.Length; j++)
            {
                if (s.IsLimitUp(j) && s.kLineDay[j].highestPrice >= f5  &&  s.kLineDay[j].lowestPrice <= f5 * 1.01)
                {
                    DBHelper.InsertData("big_rise_f5_limitup", new string[,] { {"start_date", "datetime", s.kLineDay[currentIndex].startDateTime.ToShortDateString() },
                        {"gid", "varchar", s.gid.Trim() }, {"low_date", "datetime", s.kLineDay[lowIndex].startDateTime.ToShortDateString() },
                        { "low_price", "float", lowPrice.ToString()}, { "high_date", "datetime", s.kLineDay[highIndex].startDateTime.ToShortDateString()},
                        {"high_price", "float", highPrice.ToString() }, {"f5", "float", f5.ToString() },
                        {"f5_limit_up_date", "datetime", s.kLineDay[j].startDateTime.ToShortDateString() } }); ;
                }
            }

        }
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
            s.LoadKLineWeek(Util.rc);
            KLine.ComputeMACD(s.kLineWeek);
            KLine.ComputeKDJ(s.kLineWeek);
            gidArr.Add(s);
        }
        return s;
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