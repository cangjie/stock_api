﻿ <%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">

    

    protected void Page_Load(object sender, EventArgs e)
    {
        Stock s = new Stock("sh600503");
        s.LoadKLineDay(Util.rc);
        int index = s.kLineDay.Length - 1;
        double[] boll = KLine.ComputeBoll(s.kLineDay, index, 20);
        Response.Write(boll[0].ToString()+ "," + boll[1].ToString()+ "," +  boll[2].ToString()+"," 
            + KLine.ComputeBB(s.kLineDay, index, 20).ToString() + "," + KLine.ComputeBBWidth(s.kLineDay, index, 20).ToString());

        //Response.Write(s.kLineDay[index].startDateTime.ToShortDateString() + " " + KLine.ComputeRisk(s.kLineDay, index).ToString());


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


</script>
