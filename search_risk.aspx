﻿<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", DateTime.Now.ToShortDateString()));
        DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", DateTime.Now.ToShortDateString()));
        string[] gidArr = Util.GetAllGids();
        foreach (string gid in gidArr)
        {

            Stock s = new Stock(gid);
            s.LoadKLineDay(Util.rc);
            int startIndex = s.GetItemIndex(startDate);
            if (startIndex < 0)
            {
                startIndex = 0;
            }
            for (int i = startIndex; i < s.kLineDay.Length && s.kLineDay[i].endDateTime.Date <= endDate; i++)
            {

                if (i < 16)
                {
                    continue;
                }
                double risk = KLine.ComputeRisk(s.kLineDay, i);
                try
                {
                    int r= DBHelper.InsertData("risk", new string[,] {{"gid", "varchar", gid.Trim() },
                    {"alert_date", "datetime", s.kLineDay[i].endDateTime.ToShortDateString() },
                    {"risk", "float", Math.Round(risk, 2).ToString() } });
                    if (r == 0)
                    { 
                        DBHelper.UpdateData("risk", new string[,] { { "risk", "float", Math.Round(risk, 2).ToString() }, { "create_date", "datetime", DateTime.Now.ToString() } },
                            new string[,] { { "gid", "varchar", gid.Trim() }, { "alert_date", "datetime", s.kLineDay[i].endDateTime.ToShortDateString() } }, Util.conStr);
                    }

                }
                catch
                {
                    
                }
            }
        }

    }
</script>