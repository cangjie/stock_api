<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        FillPastData();
    }

    public static void FillPastData()
    {
        for (DateTime i = DateTime.Parse("2017-7-1"); i < DateTime.Now.AddDays(1); i = i.AddDays(1))
        {
            RefreshPriceVolumeIncreaseStocksForADay(i);
        }
    }

    public static void RefreshPriceVolumeIncreaseStocksForADay(DateTime currentDate)
    {
        double volumeIncreaseFilter = 0.3;
        double kLineEntityLengthFilter = 0.03;
        double priceIncreaseFilter = 0.08;

        if (Util.IsTransacDay(currentDate)
            && ((currentDate.ToShortDateString().Equals(DateTime.Now.ToShortDateString()) && DateTime.Now.Hour >= 14 && DateTime.Now.Minute >= 40)
            || !currentDate.ToShortDateString().Equals(DateTime.Now.ToShortDateString())))
        {
            string[] gidArr = Util.GetAllGids();
            for (int i = 0; i < gidArr.Length; i++)
            {
                try
                {
                    Stock s = new Stock(gidArr[i]);
                    s.LoadKLineDay();
                    int currentIndex = s.GetItemIndex(DateTime.Parse(currentDate.ToShortDateString()));
                    if (currentIndex > 0)
                    {
                        double currentVolume = Stock.GetVolumeAndAmount(gidArr[i], DateTime.Parse(currentDate.ToShortDateString() + " 14:40"))[0];
                        double previousVolume = Stock.GetVolumeAndAmount(gidArr[i],
                            DateTime.Parse(s.kLineDay[currentIndex - 1].startDateTime.ToShortDateString() + " 14:40"))[0];
                        if ((currentVolume - previousVolume) / previousVolume >= volumeIncreaseFilter
                            && (s.kLineDay[currentIndex].endPrice - s.kLineDay[currentIndex].startPrice) / s.kLineDay[currentIndex].startPrice >= kLineEntityLengthFilter
                            && (s.kLineDay[currentIndex].endPrice - s.kLineDay[currentIndex - 1].endPrice) / s.kLineDay[currentIndex - 1].endPrice >= priceIncreaseFilter)
                        {
                            DBHelper.InsertData("price_increase_volume_increase", new string[,] {
                            { "alarm_date", "datetime", s.kLineDay[currentIndex].startDateTime.ToShortDateString()},
                            { "gid", "varchar", gidArr[i].Trim()},
                            { "open_price", "float", s.kLineDay[currentIndex].startPrice.ToString()},
                            { "settle_price", "float", s.kLineDay[currentIndex].endPrice.ToString()},
                            { "price_increase", "float", ((s.kLineDay[currentIndex].endPrice - s.kLineDay[currentIndex-1].endPrice)/s.kLineDay[currentIndex-1].endPrice).ToString()},
                            { "volume_increase", "float", ((currentVolume-previousVolume)/previousVolume).ToString()}
                        });
                        }

                    }
                }
                catch
                {

                }
            }
        }
    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
    
    </div>
    </form>
</body>
</html>
