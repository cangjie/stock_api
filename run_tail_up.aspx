<%@ Page Language="C#" %>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", DateTime.Now.ToShortDateString()));
        DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", DateTime.Now.ToShortDateString()));
        startDate = DateTime.Parse("2020-4-21");
        endDate = startDate;
        string[] gidArr = Util.GetAllGids();
        for (int i = 0; i < gidArr.Length; i++)
        {
            string gid = gidArr[i].Trim();
            for (DateTime j = startDate; j <= endDate; j = j.AddDays(1))
            {
                if (Util.IsTransacDay(j))
                {
                    TimeLine[] tArr = TimeLine.GetTimeLineItem(gid.Trim(),
                        DateTime.Parse(j.ToShortDateString() + " 14:00"), DateTime.Parse(j.ToShortDateString() + " 15:01"));
                    if (tArr.Length > 0)
                    {
                        TimeLine t = tArr[0];
                        if (t.tickTime >= DateTime.Parse(j.ToShortDateString() + " 14:40"))
                        {
                            continue;
                        }
                        bool haveTailUp = false;
                        double lowest = double.MaxValue;
                        foreach (TimeLine tItem in tArr)
                        {
                            if (lowest > tItem.low)
                            {
                                lowest = tItem.low;
                                if (tItem.tickTime > DateTime.Parse(j.ToShortDateString() + " 14:40")
                                    && tItem.tickTime < DateTime.Parse(j.ToShortDateString() + " 14:50") )
                                {
                                    haveTailUp = true;
                                }
                                if (haveTailUp && tItem.tickTime >= DateTime.Parse(j.ToShortDateString() + " 14:50"))
                                {
                                    haveTailUp = false;
                                    break;
                                }
                            }
                        }
                        if (haveTailUp)
                        {
                            try
                            {
                                DBHelper.InsertData("alert_tail_up", new string[,] { {"alert_date", "datetime", t.tickTime.Date.ToShortDateString() },
                                {"gid", "varchar", gid.Trim() } });
                            }
                            catch
                            { 
                            
                            }
                        }

                    }
                    else
                    {
                        continue;
                    }
                }
            }
        }
    }
</script>