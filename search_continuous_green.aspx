<%@ Page Language="C#" %>


<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime date = DateTime.Parse(Util.GetSafeRequestValue(Request, "date", DateTime.Now.ToShortDateString()));
        string[] gidArr = Util.GetAllGids();
        foreach(string gid in gidArr)
        {
            Stock s = new Stock(gid);
            s.LoadKLineDay(Util.rc);
            int startIndex = s.GetItemIndex(date);
            if (startIndex <= 3)
            { 
                continue;
            }
            
            for(int i = startIndex; i < s.kLineDay.Length; i++ )
            {
                
                if(s.kLineDay[i].startPrice <= s.kLineDay[i].endPrice)
                {
                    int greenNum = 0;
                    for(int j = i - 1; j >= 0 && s.kLineDay[j].endPrice < s.kLineDay[j].startPrice; j-- )
                    { 
                        greenNum++;
                    }
                    if (greenNum >= 4)
                    { 
                        DBHelper.InsertData("alert_continuous_green", new string[,]{{"alert_date", "datetime", s.kLineDay[i].startDateTime.ToShortDateString()},
                                {"gid", "varchar", s.gid.Trim()}, {"green_num", "int", greenNum.ToString()}
                        });
                    }
                }
            }
        }
    }
</script>