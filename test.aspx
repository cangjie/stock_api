<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">

    public static Queue queue = new Queue();

    protected void Page_Load(object sender, EventArgs e)
    {
        //double[] volumeAndAmount = Stock.GetVolumeAndAmount("sh600031", DateTime.Now);
        //Response.Write(volumeAndAmount[0].ToString() + "|" + volumeAndAmount[1].ToString());

        string[] gidArr = Util.GetAllGids();

        foreach (string gid in gidArr)
        {
            Stock s = new Stock(gid);
            s.kArr = KLine.GetLocalKLine(gid, "day");
            for (DateTime i = DateTime.Parse("2017-6-16"); i <= DateTime.Parse("2017-7-11"); i = i.AddDays(1))
            {
                if (Util.IsTransacDay(i))
                {
                    int idx = s.GetItemIndex(DateTime.Parse(i.ToShortDateString() + " 9:30"));
                    if (idx > 1)
                    {
                        if ((s.kArr[idx - 1].endPrice - s.kArr[idx - 2].endPrice) / s.kArr[idx - 1].endPrice > 0.07)
                        {
                            double volume = Stock.GetVolumeAndAmount(s.gid, DateTime.Parse(i.ToShortDateString() + " 14:30"))[0];
                            double volumeLast = Stock.GetVolumeAndAmount(s.gid, DateTime.Parse(s.kArr[idx - 1].startDateTime.ToShortDateString() + " 14:30"))[0];

                            if (volumeLast - volume > 0 && volume / volumeLast < 0.66)
                            {
                                DBHelper.InsertData("limit_up_volume_reduce", new string[,] {
                                    { "gid", "varchar", gid},
                                    { "alert_date", "datetime", i.ToShortDateString()}
                                });
                            }

                        }

                    }
                }
            }
        }




        /*
        Util.RefreshTodayKLine();
        foreach (string gid in Util.GetAllGids())
        {
            try
            {
                int todayIndex = 0;
                KLine[] kArr = KLine.GetLocalKLine(gid, "day");
                kArr = KLine.ComputeRSV(kArr);
                kArr = KLine.ComputeKDJ(kArr);
                todayIndex = KLine.GetStartIndexForDay(kArr, DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30"));
                KLine.SearchKDJAlert(kArr, todayIndex);
                kArr = KLine.GetLocalKLine(gid, "1hr");
                kArr = KLine.ComputeRSV(kArr);
                kArr = KLine.ComputeKDJ(kArr);
                todayIndex = KLine.GetStartIndexForDay(kArr, DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30"));
                KLine.SearchKDJAlert(kArr, todayIndex);
                kArr = KLine.GetLocalKLine(gid, "30min");
                kArr = KLine.ComputeRSV(kArr);
                kArr = KLine.ComputeKDJ(kArr);
                todayIndex = KLine.GetStartIndexForDay(kArr, DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30"));
                KLine.SearchKDJAlert(kArr, todayIndex);
                kArr = KLine.GetLocalKLine(gid, "15min");
                kArr = KLine.ComputeRSV(kArr);
                kArr = KLine.ComputeKDJ(kArr);
                todayIndex = KLine.GetStartIndexForDay(kArr, DateTime.Parse(DateTime.Now.ToShortDateString() + " 9:30"));
                KLine.SearchKDJAlert(kArr, todayIndex);
            }
            catch
            {

            }

        }*/

    }


</script>
