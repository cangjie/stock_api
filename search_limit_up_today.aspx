<%@ Page Language="C#" %>

<!DOCTYPE html>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!Util.IsTransacDay(DateTime.Now))
        {
            Response.End();
        }
        string[] gidArr = Util.GetAllGids();
        for (int i = 0; i < gidArr.Length; i++)
        {
            try
            {
                Stock s = new Stock(gidArr[i].Trim());
                s.LoadKLineDay(Util.rc);
                s.kArr = s.kLineDay;
                int currentIndex = s.kLineDay.Length - 1;
                if (s.kLineDay.Length >= 17)
                {
                    StockWatcher.SearchFolks(s.gid, "day", s.kLineDay, s.kLineDay.Length - 1);
                }
                for (int j = 0; j < 5; j++)
                {
                    currentIndex = s.kLineDay.Length - 1 - j;
                    if (Util.IsTransacDay(s.kLineDay[currentIndex].endDateTime) && s.IsLimitUp(currentIndex))
                    {
                        try
                        {
                            LimitUp.SaveLimitUp(s.gid.Trim(), DateTime.Parse(s.kLineDay[currentIndex].startDateTime.ToShortDateString()),
                                 s.kLineDay[currentIndex].endPrice, s.kLineDay[currentIndex].startPrice,
                                 s.kLineDay[currentIndex].highestPrice, s.kLineDay[currentIndex].volume);
                        }
                        catch
                        { 
                        
                        }

                    }
                }
            }
            catch
            {

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
