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
            Stock s = new Stock(gidArr[i].Trim());
            s.kLineDay = Stock.LoadLocalKLineFromDB(s.gid.Trim(), "day");
            s.kArr = s.kLineDay;
            for (int j = 0; j < 5; j++)
            {
                try
                {
                    if (s.IsLimitUp(s.kLineDay.Length - 1 - j))
                    {
                        LimitUp.SaveLimitUp(s.gid.Trim(), DateTime.Parse(s.kLineDay[s.kLineDay.Length - 1 - j].startDateTime.ToShortDateString()),
                             s.kLineDay[s.kLineDay.Length - 1 - j - 1].endPrice, s.kLineDay[s.kLineDay.Length - 1 - j].startPrice,
                             s.kLineDay[s.kLineDay.Length - 1 - j].highestPrice, s.kLineDay[s.kLineDay.Length - 1 - j].volume);
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
