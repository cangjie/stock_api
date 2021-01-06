<%@ Page Language="C#" %>

<!DOCTYPE html>

<script runat="server">

    //public string jsonData = "";

    public string gid = "sh603396";
    public string name = "";
    public double avg3LinePrice = 0;
    public string[] gidArr = new string[] { };
    public string previousGid = "";
    public string nextGid = "";

    public double yesterdayVolume = 0;
    public double todayVolume = 0;

    protected void Page_Load(object sender, EventArgs e)
    {
        //jsonData = Util.GetWebContent("api/get_k_line.aspx?gid=" + Util.GetSafeRequestValue(Request, "gid", "sh600031"));
        gid = Util.GetSafeRequestValue(Request, "gid", "sh603396");
        name = Util.GetSafeRequestValue(Request, "name", "");
        gidArr = Util.GetSafeRequestValue(Request, "gids", "").Split(',');

        Stock s = new Stock(gid);
        s.LoadKLineDay(Util.rc);
        if (s.kLineDay[s.kLineDay.Length - 1].startDateTime.ToShortDateString().Equals(DateTime.Now.ToShortDateString()))
        {
            todayVolume = Stock.GetVolumeAndAmount(s.gid, DateTime.Now)[0];
            yesterdayVolume = Stock.GetVolumeAndAmount(s.gid, DateTime.Parse(s.kLineDay[s.kLineDay.Length - 2].startDateTime.ToShortDateString() + " " + DateTime.Now.ToShortTimeString()))[0];
        }
        else
        {
            todayVolume = Stock.GetVolumeAndAmount(s.gid, s.kLineDay[s.kLineDay.Length - 1].endDateTime)[0];
            yesterdayVolume = Stock.GetVolumeAndAmount(s.gid, s.kLineDay[s.kLineDay.Length - 2].endDateTime)[0];

        }

        avg3LinePrice = Math.Round(s.GetAverageSettlePrice(s.kLineDay.Length - 1, 3, 3), 2);
        if (name.Trim().Equals(""))
        {
            name = s.Name.Trim();

        }

        for (int i = 0; i < gidArr.Length; i++)
        {
            if (gidArr[i].Trim().Equals(gid))
            {
                if (i > 0)
                {
                    previousGid = gidArr[i - 1].Trim();
                }
                if (i < gidArr.Length - 1)
                {
                    nextGid = gidArr[i + 1].Trim();
                }
            }
        }
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="UTF-8" />
    <title>Title</title>
    <script type="text/javascript" src="js/svg.js" ></script>
    <script type="text/javascript" src="js/stock.js" ></script>
    <script type="text/javascript" src="js/jquery.min.js" ></script>
    <script type="text/javascript" >
        function go() {
            var gid = document.getElementById("gid").value.trim();
            if (gid.charAt(0) == '6') {
                gid = "sh" + gid;
            }
            else {
                gid = "sz" + gid;
            }
            window.location.href = "show_k_line_day.aspx?gid=" + gid;
        }
    </script>
</head>
<body onresize="init()" onload="init()"  >
    <button id="btn_draw" onclick="ready_draw()" > 画 线 </button><%=gid %> <%=name %> <span id="price" >现价:</span> <span id="rate" >涨幅:</span> <span id="settle" >昨收:</span> <span id="open" >今开:</span> <span id="max" >最高:</span> <span id="min" >最低:</span> <span>放量：<%=Math.Round(100 * (todayVolume - yesterdayVolume)/yesterdayVolume, 2).ToString() + "%" %></span> <span id="avg3" >3线：<%=avg3LinePrice.ToString() %></span>
    <%if (!previousGid.Trim().Equals(""))
                    {
            %>
     <span > <a href="show_k_line_day.aspx?gid=<%=previousGid.Trim() %>&gids=<%=Util.GetSafeRequestValue(Request, "gids", "") %>" >上一支</a> </span>
    <%
        }
        if (!nextGid.Trim().Equals(""))
        {
            %>
    <span > <a href="show_k_line_day.aspx?gid=<%=nextGid.Trim() %>&gids=<%=Util.GetSafeRequestValue(Request, "gids", "") %>" >下一支</a> </span>
                <%
        }
        %>
    <input type="text" id="gid" /><button  onclick="go()" >go!</button><br />
    <svg id="svg" version="1.1"   xmlns="http://www.w3.org/2000/svg"  onmousedown="mouse_down(evt)" onmouseup="mouse_up(evt)" onmousemove="mouse_move(evt)"  ></svg>
</body>
<script type="text/javascript" >
    //var stock_data_json = '{"type": "day", "gid": "sz002579", "start_time": "2017/3/1", "end_time": "2017/6/15" , "items": [{"item_start_time": "2017/3/1 0:00:00", "item_end_time": "2017/3/1 0:00:00", "item_start_price": "14.29", "item_end_price": "14.48" , "item_highest_price": "15.05" , "item_lowest_price": "14.01" , "item_deal": "451782" , "item_volumn": "66738.4" , "item_change": "12.89" },{"item_start_time": "2017/3/2 0:00:00", "item_end_time": "2017/3/2 0:00:00", "item_start_price": "14.06", "item_end_price": "13.7" , "item_highest_price": "14.26" , "item_lowest_price": "13.61" , "item_deal": "286454" , "item_volumn": "39993.73" , "item_change": "8.17" },{"item_start_time": "2017/3/3 0:00:00", "item_end_time": "2017/3/3 0:00:00", "item_start_price": "13.57", "item_end_price": "15.07" , "item_highest_price": "15.07" , "item_lowest_price": "13.57" , "item_deal": "427642" , "item_volumn": "63071" , "item_change": "12.2" },{"item_start_time": "2017/3/6 0:00:00", "item_end_time": "2017/3/6 0:00:00", "item_start_price": "15.4", "item_end_price": "15.58" , "item_highest_price": "15.88" , "item_lowest_price": "15.07" , "item_deal": "594913" , "item_volumn": "92011.3" , "item_change": "16.98" },{"item_start_time": "2017/3/7 0:00:00", "item_end_time": "2017/3/7 0:00:00", "item_start_price": "15.4", "item_end_price": "15.25" , "item_highest_price": "15.47" , "item_lowest_price": "15.1" , "item_deal": "316338" , "item_volumn": "48315.63" , "item_change": "9.03" },{"item_start_time": "2017/3/8 0:00:00", "item_end_time": "2017/3/8 0:00:00", "item_start_price": "15.21", "item_end_price": "14.87" , "item_highest_price": "15.36" , "item_lowest_price": "14.77" , "item_deal": "216471" , "item_volumn": "32485.2" , "item_change": "6.18" },{"item_start_time": "2017/3/9 0:00:00", "item_end_time": "2017/3/9 0:00:00", "item_start_price": "14.98", "item_end_price": "14.91" , "item_highest_price": "15.12" , "item_lowest_price": "14.8" , "item_deal": "164457" , "item_volumn": "24591.1" , "item_change": "4.69" },{"item_start_time": "2017/3/10 0:00:00", "item_end_time": "2017/3/10 0:00:00", "item_start_price": "14.8", "item_end_price": "15" , "item_highest_price": "15.04" , "item_lowest_price": "14.61" , "item_deal": "174902" , "item_volumn": "25980.28" , "item_change": "4.99" },{"item_start_time": "2017/3/13 0:00:00", "item_end_time": "2017/3/13 0:00:00", "item_start_price": "14.78", "item_end_price": "14.95" , "item_highest_price": "15.06" , "item_lowest_price": "14.62" , "item_deal": "122142" , "item_volumn": "18188.26" , "item_change": "3.49" },{"item_start_time": "2017/3/14 0:00:00", "item_end_time": "2017/3/14 0:00:00", "item_start_price": "14.9", "item_end_price": "14.55" , "item_highest_price": "15.07" , "item_lowest_price": "14.54" , "item_deal": "144089" , "item_volumn": "21254.53" , "item_change": "4.11" },{"item_start_time": "2017/3/15 0:00:00", "item_end_time": "2017/3/15 0:00:00", "item_start_price": "14.51", "item_end_price": "14.58" , "item_highest_price": "14.71" , "item_lowest_price": "14.47" , "item_deal": "73339" , "item_volumn": "10685.97" , "item_change": "2.09" },{"item_start_time": "2017/3/16 0:00:00", "item_end_time": "2017/3/16 0:00:00", "item_start_price": "14.58", "item_end_price": "14.76" , "item_highest_price": "14.84" , "item_lowest_price": "14.53" , "item_deal": "117498" , "item_volumn": "17233.72" , "item_change": "3.35" },{"item_start_time": "2017/3/17 0:00:00", "item_end_time": "2017/3/17 0:00:00", "item_start_price": "14.76", "item_end_price": "14.43" , "item_highest_price": "14.76" , "item_lowest_price": "14.32" , "item_deal": "91380" , "item_volumn": "13335.08" , "item_change": "2.61" },{"item_start_time": "2017/3/20 0:00:00", "item_end_time": "2017/3/20 0:00:00", "item_start_price": "14.4", "item_end_price": "14.31" , "item_highest_price": "14.5" , "item_lowest_price": "14.01" , "item_deal": "113101" , "item_volumn": "16083.5" , "item_change": "3.23" },{"item_start_time": "2017/3/21 0:00:00", "item_end_time": "2017/3/21 0:00:00", "item_start_price": "14.24", "item_end_price": "14.28" , "item_highest_price": "14.3" , "item_lowest_price": "14.14" , "item_deal": "56804" , "item_volumn": "8079.31" , "item_change": "1.62" },{"item_start_time": "2017/3/22 0:00:00", "item_end_time": "2017/3/22 0:00:00", "item_start_price": "14.23", "item_end_price": "14.29" , "item_highest_price": "14.29" , "item_lowest_price": "14.08" , "item_deal": "58000" , "item_volumn": "8222.66" , "item_change": "1.65" },{"item_start_time": "2017/3/23 0:00:00", "item_end_time": "2017/3/23 0:00:00", "item_start_price": "14.29", "item_end_price": "14.17" , "item_highest_price": "14.45" , "item_lowest_price": "14.09" , "item_deal": "71812" , "item_volumn": "10249.61" , "item_change": "2.05" },{"item_start_time": "2017/3/24 0:00:00", "item_end_time": "2017/3/24 0:00:00", "item_start_price": "14.13", "item_end_price": "13.98" , "item_highest_price": "14.24" , "item_lowest_price": "13.87" , "item_deal": "81462" , "item_volumn": "11391.27" , "item_change": "2.32" },{"item_start_time": "2017/3/27 0:00:00", "item_end_time": "2017/3/27 0:00:00", "item_start_price": "13.81", "item_end_price": "13.26" , "item_highest_price": "13.83" , "item_lowest_price": "13.17" , "item_deal": "164784" , "item_volumn": "22079.73" , "item_change": "4.7" },{"item_start_time": "2017/3/28 0:00:00", "item_end_time": "2017/3/28 0:00:00", "item_start_price": "13.25", "item_end_price": "13.27" , "item_highest_price": "13.37" , "item_lowest_price": "13.15" , "item_deal": "58441" , "item_volumn": "7755.65" , "item_change": "1.67" },{"item_start_time": "2017/3/29 0:00:00", "item_end_time": "2017/3/29 0:00:00", "item_start_price": "13.31", "item_end_price": "12.78" , "item_highest_price": "13.35" , "item_lowest_price": "12.78" , "item_deal": "93784" , "item_volumn": "12158.68" , "item_change": "2.68" },{"item_start_time": "2017/3/30 0:00:00", "item_end_time": "2017/3/30 0:00:00", "item_start_price": "12.79", "item_end_price": "12.39" , "item_highest_price": "12.9" , "item_lowest_price": "12.37" , "item_deal": "69928" , "item_volumn": "8793.24" , "item_change": "2" },{"item_start_time": "2017/3/31 0:00:00", "item_end_time": "2017/3/31 0:00:00", "item_start_price": "12.45", "item_end_price": "12.52" , "item_highest_price": "12.76" , "item_lowest_price": "12.41" , "item_deal": "45380" , "item_volumn": "5699.84" , "item_change": "1.29" },{"item_start_time": "2017/4/5 0:00:00", "item_end_time": "2017/4/5 0:00:00", "item_start_price": "12.54", "item_end_price": "12.73" , "item_highest_price": "12.76" , "item_lowest_price": "12.48" , "item_deal": "52206" , "item_volumn": "6597.84" , "item_change": "1.49" },{"item_start_time": "2017/4/6 0:00:00", "item_end_time": "2017/4/6 0:00:00", "item_start_price": "12.75", "item_end_price": "12.67" , "item_highest_price": "12.76" , "item_lowest_price": "12.62" , "item_deal": "36194" , "item_volumn": "4587.59" , "item_change": "1.03" },{"item_start_time": "2017/4/7 0:00:00", "item_end_time": "2017/4/7 0:00:00", "item_start_price": "12.67", "item_end_price": "12.64" , "item_highest_price": "12.8" , "item_lowest_price": "12.62" , "item_deal": "41252" , "item_volumn": "5233.7" , "item_change": "1.18" },{"item_start_time": "2017/4/10 0:00:00", "item_end_time": "2017/4/10 0:00:00", "item_start_price": "12.65", "item_end_price": "12.03" , "item_highest_price": "12.69" , "item_lowest_price": "12" , "item_deal": "88386" , "item_volumn": "10791.55" , "item_change": "2.52" },{"item_start_time": "2017/4/11 0:00:00", "item_end_time": "2017/4/11 0:00:00", "item_start_price": "11.98", "item_end_price": "12.18" , "item_highest_price": "12.29" , "item_lowest_price": "11.9" , "item_deal": "50643" , "item_volumn": "6102.91" , "item_change": "1.45" },{"item_start_time": "2017/4/12 0:00:00", "item_end_time": "2017/4/12 0:00:00", "item_start_price": "12.22", "item_end_price": "12.17" , "item_highest_price": "12.3" , "item_lowest_price": "12.11" , "item_deal": "41043" , "item_volumn": "5004.08" , "item_change": "1.17" },{"item_start_time": "2017/4/13 0:00:00", "item_end_time": "2017/4/13 0:00:00", "item_start_price": "12.17", "item_end_price": "12.1" , "item_highest_price": "12.17" , "item_lowest_price": "12.01" , "item_deal": "29956" , "item_volumn": "3618.35" , "item_change": "0.85" },{"item_start_time": "2017/4/14 0:00:00", "item_end_time": "2017/4/14 0:00:00", "item_start_price": "12.05", "item_end_price": "11.7" , "item_highest_price": "12.1" , "item_lowest_price": "11.67" , "item_deal": "46524" , "item_volumn": "5517.34" , "item_change": "1.33" },{"item_start_time": "2017/4/17 0:00:00", "item_end_time": "2017/4/17 0:00:00", "item_start_price": "11.7", "item_end_price": "11.8" , "item_highest_price": "11.88" , "item_lowest_price": "11.63" , "item_deal": "40022" , "item_volumn": "4693.41" , "item_change": "1.14" },{"item_start_time": "2017/4/18 0:00:00", "item_end_time": "2017/4/18 0:00:00", "item_start_price": "11.83", "item_end_price": "11.7" , "item_highest_price": "11.9" , "item_lowest_price": "11.68" , "item_deal": "29973" , "item_volumn": "3537.46" , "item_change": "0.86" },{"item_start_time": "2017/4/19 0:00:00", "item_end_time": "2017/4/19 0:00:00", "item_start_price": "11.7", "item_end_price": "11.36" , "item_highest_price": "11.7" , "item_lowest_price": "11.2" , "item_deal": "40144" , "item_volumn": "4561.74" , "item_change": "1.15" },{"item_start_time": "2017/4/20 0:00:00", "item_end_time": "2017/4/20 0:00:00", "item_start_price": "11.37", "item_end_price": "11.32" , "item_highest_price": "11.49" , "item_lowest_price": "11.18" , "item_deal": "31067" , "item_volumn": "3514.07" , "item_change": "0.89" },{"item_start_time": "2017/4/21 0:00:00", "item_end_time": "2017/4/21 0:00:00", "item_start_price": "11.23", "item_end_price": "11.1" , "item_highest_price": "11.35" , "item_lowest_price": "11" , "item_deal": "30478" , "item_volumn": "3406.26" , "item_change": "0.87" },{"item_start_time": "2017/4/24 0:00:00", "item_end_time": "2017/4/24 0:00:00", "item_start_price": "10.99", "item_end_price": "10.27" , "item_highest_price": "10.99" , "item_lowest_price": "10.26" , "item_deal": "45142" , "item_volumn": "4765.76" , "item_change": "1.29" },{"item_start_time": "2017/4/25 0:00:00", "item_end_time": "2017/4/25 0:00:00", "item_start_price": "10.35", "item_end_price": "10.18" , "item_highest_price": "10.43" , "item_lowest_price": "10" , "item_deal": "36775" , "item_volumn": "3743.37" , "item_change": "1.05" },{"item_start_time": "2017/4/26 0:00:00", "item_end_time": "2017/4/26 0:00:00", "item_start_price": "10.42", "item_end_price": "11.2" , "item_highest_price": "11.2" , "item_lowest_price": "10.42" , "item_deal": "45459" , "item_volumn": "4996.02" , "item_change": "1.3" },{"item_start_time": "2017/4/27 0:00:00", "item_end_time": "2017/4/27 0:00:00", "item_start_price": "11.5", "item_end_price": "11.4" , "item_highest_price": "11.75" , "item_lowest_price": "11.2" , "item_deal": "146226" , "item_volumn": "16788.35" , "item_change": "4.17" },{"item_start_time": "2017/4/28 0:00:00", "item_end_time": "2017/4/28 0:00:00", "item_start_price": "11.6", "item_end_price": "11.42" , "item_highest_price": "11.6" , "item_lowest_price": "11.21" , "item_deal": "67440" , "item_volumn": "7648.49" , "item_change": "1.92" },{"item_start_time": "2017/5/2 0:00:00", "item_end_time": "2017/5/2 0:00:00", "item_start_price": "11.49", "item_end_price": "11.48" , "item_highest_price": "11.49" , "item_lowest_price": "11.25" , "item_deal": "44134" , "item_volumn": "5012.69" , "item_change": "1.26" },{"item_start_time": "2017/5/3 0:00:00", "item_end_time": "2017/5/3 0:00:00", "item_start_price": "11.36", "item_end_price": "11.35" , "item_highest_price": "11.45" , "item_lowest_price": "11.17" , "item_deal": "47587" , "item_volumn": "5373.44" , "item_change": "1.36" },{"item_start_time": "2017/5/4 0:00:00", "item_end_time": "2017/5/4 0:00:00", "item_start_price": "11.34", "item_end_price": "11.28" , "item_highest_price": "11.36" , "item_lowest_price": "11.15" , "item_deal": "36308" , "item_volumn": "4083.3" , "item_change": "1.04" },{"item_start_time": "2017/5/5 0:00:00", "item_end_time": "2017/5/5 0:00:00", "item_start_price": "11.18", "item_end_price": "10.77" , "item_highest_price": "11.21" , "item_lowest_price": "10.75" , "item_deal": "40196" , "item_volumn": "4424.99" , "item_change": "1.15" },{"item_start_time": "2017/5/8 0:00:00", "item_end_time": "2017/5/8 0:00:00", "item_start_price": "10.81", "item_end_price": "10.78" , "item_highest_price": "11" , "item_lowest_price": "10.71" , "item_deal": "31831" , "item_volumn": "3450.05" , "item_change": "0.91" },{"item_start_time": "2017/5/9 0:00:00", "item_end_time": "2017/5/9 0:00:00", "item_start_price": "10.8", "item_end_price": "10.97" , "item_highest_price": "10.98" , "item_lowest_price": "10.74" , "item_deal": "25430" , "item_volumn": "2760.96" , "item_change": "0.73" },{"item_start_time": "2017/5/10 0:00:00", "item_end_time": "2017/5/10 0:00:00", "item_start_price": "10.94", "item_end_price": "10.74" , "item_highest_price": "10.99" , "item_lowest_price": "10.67" , "item_deal": "38704" , "item_volumn": "4206.49" , "item_change": "1.1" },{"item_start_time": "2017/5/11 0:00:00", "item_end_time": "2017/5/11 0:00:00", "item_start_price": "10.75", "item_end_price": "10.7" , "item_highest_price": "10.78" , "item_lowest_price": "10.2" , "item_deal": "32616" , "item_volumn": "3433.22" , "item_change": "0.93" },{"item_start_time": "2017/5/12 0:00:00", "item_end_time": "2017/5/12 0:00:00", "item_start_price": "10.69", "item_end_price": "10.81" , "item_highest_price": "10.95" , "item_lowest_price": "10.52" , "item_deal": "43759" , "item_volumn": "4710.3" , "item_change": "1.25" },{"item_start_time": "2017/5/15 0:00:00", "item_end_time": "2017/5/15 0:00:00", "item_start_price": "10.89", "item_end_price": "10.82" , "item_highest_price": "10.92" , "item_lowest_price": "10.73" , "item_deal": "24041" , "item_volumn": "2602.3" , "item_change": "0.69" },{"item_start_time": "2017/5/16 0:00:00", "item_end_time": "2017/5/16 0:00:00", "item_start_price": "10.8", "item_end_price": "11.17" , "item_highest_price": "11.19" , "item_lowest_price": "10.61" , "item_deal": "40021" , "item_volumn": "4375.62" , "item_change": "1.14" },{"item_start_time": "2017/5/17 0:00:00", "item_end_time": "2017/5/17 0:00:00", "item_start_price": "11.14", "item_end_price": "11.06" , "item_highest_price": "11.32" , "item_lowest_price": "11.03" , "item_deal": "39527" , "item_volumn": "4411.55" , "item_change": "1.13" },{"item_start_time": "2017/5/18 0:00:00", "item_end_time": "2017/5/18 0:00:00", "item_start_price": "11.01", "item_end_price": "11.09" , "item_highest_price": "11.09" , "item_lowest_price": "10.86" , "item_deal": "33870" , "item_volumn": "3725.53" , "item_change": "0.97" },{"item_start_time": "2017/5/19 0:00:00", "item_end_time": "2017/5/19 0:00:00", "item_start_price": "10.95", "item_end_price": "10.89" , "item_highest_price": "11.07" , "item_lowest_price": "10.87" , "item_deal": "20280" , "item_volumn": "2220.08" , "item_change": "0.58" },{"item_start_time": "2017/5/22 0:00:00", "item_end_time": "2017/5/22 0:00:00", "item_start_price": "10.85", "item_end_price": "10.75" , "item_highest_price": "10.96" , "item_lowest_price": "10.55" , "item_deal": "24600" , "item_volumn": "2642.22" , "item_change": "0.7" },{"item_start_time": "2017/5/23 0:00:00", "item_end_time": "2017/5/23 0:00:00", "item_start_price": "10.66", "item_end_price": "10.38" , "item_highest_price": "10.74" , "item_lowest_price": "10.23" , "item_deal": "30862" , "item_volumn": "3228.4" , "item_change": "0.88" },{"item_start_time": "2017/5/24 0:00:00", "item_end_time": "2017/5/24 0:00:00", "item_start_price": "10.36", "item_end_price": "10.61" , "item_highest_price": "10.61" , "item_lowest_price": "10.16" , "item_deal": "23521" , "item_volumn": "2445.85" , "item_change": "0.67" },{"item_start_time": "2017/5/25 0:00:00", "item_end_time": "2017/5/25 0:00:00", "item_start_price": "10.57", "item_end_price": "10.64" , "item_highest_price": "10.66" , "item_lowest_price": "10.3" , "item_deal": "27474" , "item_volumn": "2897.76" , "item_change": "0.78" },{"item_start_time": "2017/5/26 0:00:00", "item_end_time": "2017/5/26 0:00:00", "item_start_price": "10.7", "item_end_price": "10.72" , "item_highest_price": "10.96" , "item_lowest_price": "10.7" , "item_deal": "32122" , "item_volumn": "3482.07" , "item_change": "0.92" },{"item_start_time": "2017/5/31 0:00:00", "item_end_time": "2017/5/31 0:00:00", "item_start_price": "10.99", "item_end_price": "10.73" , "item_highest_price": "11.07" , "item_lowest_price": "10.72" , "item_deal": "23372" , "item_volumn": "2540.88" , "item_change": "0.67" },{"item_start_time": "2017/6/1 0:00:00", "item_end_time": "2017/6/1 0:00:00", "item_start_price": "10.65", "item_end_price": "10.34" , "item_highest_price": "10.73" , "item_lowest_price": "10.34" , "item_deal": "22736" , "item_volumn": "2395" , "item_change": "0.65" },{"item_start_time": "2017/6/2 0:00:00", "item_end_time": "2017/6/2 0:00:00", "item_start_price": "10.26", "item_end_price": "10.52" , "item_highest_price": "10.55" , "item_lowest_price": "10.02" , "item_deal": "29430" , "item_volumn": "3028.77" , "item_change": "0.84" },{"item_start_time": "2017/6/5 0:00:00", "item_end_time": "2017/6/5 0:00:00", "item_start_price": "10.52", "item_end_price": "10.49" , "item_highest_price": "10.6" , "item_lowest_price": "10.41" , "item_deal": "16319" , "item_volumn": "1714.89" , "item_change": "0.47" },{"item_start_time": "2017/6/6 0:00:00", "item_end_time": "2017/6/6 0:00:00", "item_start_price": "10.49", "item_end_price": "10.56" , "item_highest_price": "10.57" , "item_lowest_price": "10.41" , "item_deal": "14963" , "item_volumn": "1572.69" , "item_change": "0.43" },{"item_start_time": "2017/6/7 0:00:00", "item_end_time": "2017/6/7 0:00:00", "item_start_price": "10.54", "item_end_price": "10.82" , "item_highest_price": "10.84" , "item_lowest_price": "10.5" , "item_deal": "37728" , "item_volumn": "4053.91" , "item_change": "1.08" },{"item_start_time": "2017/6/8 0:00:00", "item_end_time": "2017/6/8 0:00:00", "item_start_price": "10.81", "item_end_price": "10.77" , "item_highest_price": "10.94" , "item_lowest_price": "10.71" , "item_deal": "29766" , "item_volumn": "3216.89" , "item_change": "0.85" },{"item_start_time": "2017/6/9 0:00:00", "item_end_time": "2017/6/9 0:00:00", "item_start_price": "10.72", "item_end_price": "10.8" , "item_highest_price": "10.81" , "item_lowest_price": "10.5" , "item_deal": "18852" , "item_volumn": "2015.04" , "item_change": "0.54" },{"item_start_time": "2017/6/12 0:00:00", "item_end_time": "2017/6/12 0:00:00", "item_start_price": "10.75", "item_end_price": "10.56" , "item_highest_price": "10.76" , "item_lowest_price": "10.51" , "item_deal": "20045" , "item_volumn": "2128.27" , "item_change": "0.57" },{"item_start_time": "2017/6/13 0:00:00", "item_end_time": "2017/6/13 0:00:00", "item_start_price": "10.51", "item_end_price": "10.59" , "item_highest_price": "10.69" , "item_lowest_price": "10.41" , "item_deal": "17318" , "item_volumn": "1831.16" , "item_change": "0.49" },{"item_start_time": "2017/6/14 0:00:00", "item_end_time": "2017/6/14 0:00:00", "item_start_price": "10.66", "item_end_price": "10.55" , "item_highest_price": "10.66" , "item_lowest_price": "10.5" , "item_deal": "18771" , "item_volumn": "1983.7" , "item_change": "0.54" },{"item_start_time": "2017/6/15 0:00:00", "item_end_time": "2017/6/15 0:00:00", "item_start_price": "10.71", "item_end_price": "11.61" , "item_highest_price": "11.61" , "item_lowest_price": "10.71" , "item_deal": "72554" , "item_volumn": "8287.54" , "item_change": "2.07" }] }'
    
    var htmlObj = $.ajax({ url: "api/get_k_line.aspx?gid=<%=gid%>", async: false });
    var price = 0;
    var settle = 0;
    var open = 0;
    var rate = 0;
    var max = 0;
    var min = 0;
    var span_price = document.getElementById("price");
    var span_settle = document.getElementById("settle");
    var span_open = document.getElementById("open");
    var span_rate = document.getElementById("rate");
    var span_max = document.getElementById("max");
    var span_min = document.getElementById("min");


    var stock_data_json = htmlObj.responseText;
    var stock_data = eval('(' + stock_data_json + ')');
    
    var item_today = stock_data.items[stock_data.items.length - 1];
    var item_yesterday = stock_data.items[stock_data.items.length - 2];

    



    price = item_today.item_end_price;
    open = item_today.item_start_price;
    settle = item_yesterday.item_end_price;
    min = item_today.item_lowest_price;
    max = item_today.item_highest_price;
    rate = Math.round((price - settle) * 100 / settle, 2);

    span_price.innerHTML = span_price.innerHTML + " <font color='" + ((price > settle) ? "red" : ((price == settle) ? "black" : "green")) + "' > "
        + price.toString() + " </font> ";

    span_rate.innerHTML = span_rate.innerHTML + " <font color='" + ((price > settle) ? "red" : ((price == settle) ? "black" : "green")) + "' > "
        + rate.toString() + "% </font> ";

    span_settle.innerHTML = span_settle.innerHTML  + " " + settle.toString() + " ";

    span_open.innerHTML = span_open.innerHTML + " <font color='" + ((open > settle) ? "red" : ((open == settle) ? "black" : "green")) + "' > " + open.toString() + " </font> ";

    span_max.innerHTML = span_max.innerHTML + " <font color='" + ((max > settle) ? "red" : ((max == settle) ? "black" : "green")) + "' > " + max.toString() + " </font> ";

    span_min.innerHTML = span_min.innerHTML + " <font color='" + ((min > settle) ? "red" : ((min == settle) ? "black" : "green")) + "' > " + min.toString() + " </font> ";


    var svg = document.getElementById("svg");
    var min_k_line_width = 5;
    var k_line_width = min_k_line_width;
    var k_line_map_width = 0;
    var k_line_map_height = 0;
    var k_line_map_x = 0;
    var k_line_map_y = 0;
    var stock_data_start_index = 0;
    var stock_data_end_index = 0;
    var k_line_max_count_in_map = 0;
    var k_line_count_in_map = 0;
    var stock_max_price = 0;
    var stock_min_price = 0;

    var computed_max_price = <%=Util.GetSafeRequestValue(Request, "maxprice", "0")%>;
    var computed_min_price = <%=Util.GetSafeRequestValue(Request, "minprice", "0")%>;

    

    var svg_width = window.innerWidth-25;
    var svg_height = window.innerHeight-50;
    var draw_state = false;
    function ready_draw() {
        hide_high_light_point_1();
        var btn_draw = document.getElementById("btn_draw");
        if (!draw_state) {
            btn_draw.style.backgroundColor = "blue";
        }
        else
        {
            btn_draw.style.backgroundColor = "white";
        }
        draw_state = !draw_state;
    }
    function init() {
        svg.innerHTML = "";
        //-25是为了保证svg图不出窗口，不出现滚动条。
        svg.style.width = svg_width;
        svg.style.height = svg_height;
        //设定K线图本身的宽和高，缩进的地方是留白，填写坐标用。
        k_line_map_width = svg_width - 150;
        k_line_map_height = svg_height - 50;

        k_line_max_count_in_map = parseInt(k_line_map_width / min_k_line_width) - 1;
        if (stock_data.items.length > k_line_max_count_in_map)
        {
            k_line_count_in_map = k_line_max_count_in_map;
        }
        else{
            k_line_count_in_map = stock_data.items.length;
        }
        stock_data_end_index = stock_data.items.length - 1;
        stock_data_start_index = stock_data_end_index + 1 - k_line_count_in_map;
        k_line_width = parseInt(min_k_line_width * (k_line_max_count_in_map / k_line_count_in_map));
        //K线图在整个SVG图当中的位置，当然k线图的宽高，都要小于SVG的宽高，缩进的地方是留白，填写坐标用。
        k_line_map_x = parseInt(k_line_width/2);
        k_line_map_y = 25;
        stock_max_price = get_max_price(stock_data.items, stock_data_start_index, stock_data_end_index);
        stock_min_price = get_min_price(stock_data.items, stock_data_start_index, stock_data_end_index)
        var line_min = createLine("line_min", 0, get_y_value(stock_min_price),
            k_line_map_width + k_line_map_x + parseInt(k_line_width/2), get_y_value(stock_min_price),
            "1px", "rgb(255,0,0)", "2,2");
        //line_min.setAttributeNS(xmlns,"stroke-dasharray", "2,2");
        svg.appendChild(line_min);
        var text_min = createTextBox("txt_min", k_line_map_width + k_line_map_x + parseInt(k_line_width/2) + 10,
            get_y_value(stock_min_price),  stock_min_price.toString(), "15", "rgb(255,0,0)");
        svg.appendChild(text_min);
        var line_191 = createLine("line_191", 0, get_y_value((stock_max_price - stock_min_price) * 0.191 + stock_min_price),
            k_line_map_width + k_line_map_x + parseInt(k_line_width/2), get_y_value((stock_max_price - stock_min_price) * 0.191+ stock_min_price),
            "1px", "rgb(255,0,0)", "2,15");
        svg.appendChild(line_191);
        var text_191 = createTextBox("txt_191",
            k_line_map_width + k_line_map_x + parseInt(k_line_width/2) + 10, get_y_value((stock_max_price - stock_min_price) * 0.191+ stock_min_price),
            "19.1% " + (Math.round(((stock_max_price - stock_min_price) * 0.191+ stock_min_price)*100)/100).toString(), "15", "rgb(255,0,0)");
        svg.appendChild(text_191);
        var line_382 = createLine("line_382", 0, get_y_value((stock_max_price - stock_min_price) * 0.382+stock_min_price),
            k_line_map_width + k_line_map_x + parseInt(k_line_width/2), get_y_value((stock_max_price - stock_min_price) * 0.382+ stock_min_price),
            "1px", "rgb(255,0,0)", "2,15");
        svg.appendChild(line_382);
        var text_382 = createTextBox("txt_382",
            k_line_map_width + k_line_map_x + parseInt(k_line_width/2) + 10, get_y_value((stock_max_price - stock_min_price) * 0.382+ stock_min_price),
            "38.2% " + (Math.round(((stock_max_price - stock_min_price) * 0.382+ stock_min_price)*100)/100).toString(), "15", "rgb(255,0,0)");
        svg.appendChild(text_382);
        var line_half = createLine("line_half", 0, get_y_value((stock_max_price - stock_min_price) * 0.5+stock_min_price),
            k_line_map_width + k_line_map_x + parseInt(k_line_width/2), get_y_value((stock_max_price - stock_min_price) * 0.5+ stock_min_price),
            "1px", "rgb(255,0,0)", "2,15");
        svg.appendChild(line_half);
        var text_50 = createTextBox("txt_50",
            k_line_map_width + k_line_map_x + parseInt(k_line_width/2) + 10, get_y_value((stock_max_price - stock_min_price) * 0.50+ stock_min_price),
            "50% " + (Math.round(((stock_max_price - stock_min_price) * 0.50+ stock_min_price)*100)/100).toString(), "15", "rgb(255,0,0)");
        svg.appendChild(text_50);
        var line_618 = createLine("line_618", 0, get_y_value((stock_max_price - stock_min_price) * 0.618+stock_min_price),
            k_line_map_width + k_line_map_x + parseInt(k_line_width/2), get_y_value((stock_max_price - stock_min_price) * 0.618+ stock_min_price),
            "1px", "rgb(255,0,0)", "2,15");
        svg.appendChild(line_618);
        var text_618 = createTextBox("txt_618",
            k_line_map_width + k_line_map_x + parseInt(k_line_width/2)+10, get_y_value((stock_max_price - stock_min_price) * 0.618+ stock_min_price),
            "61.8% " + (Math.round(((stock_max_price - stock_min_price) * 0.618+ stock_min_price)*100)/100).toString(), "15", "rgb(255,0,0)");
        svg.appendChild(text_618);
        var line_809 = createLine("line_809", 0, get_y_value((stock_max_price - stock_min_price) * 0.809+stock_min_price),
            k_line_map_width + k_line_map_x + parseInt(k_line_width/2), get_y_value((stock_max_price - stock_min_price) * 0.809+ stock_min_price),
            "1px", "rgb(255,0,0)", "2,15");
        svg.appendChild(line_809);
        var text_809 = createTextBox("txt_809",
            k_line_map_width + k_line_map_x + parseInt(k_line_width/2) + 10, get_y_value((stock_max_price - stock_min_price) * 0.809+ stock_min_price),
            "80.9% " + (Math.round(((stock_max_price - stock_min_price) * 0.809+ stock_min_price)*100)/100).toString(), "15", "rgb(255,0,0)");
        svg.appendChild(text_809);
        var line_max = createLine("line_max", 0, get_y_value(stock_max_price),
            k_line_map_width + k_line_map_x + parseInt(k_line_width/2), get_y_value(stock_max_price),
            "1px", "rgb(255,0,0)", "2,2");
        svg.appendChild(line_max);
        var text_max = createTextBox("txt_max",
            k_line_map_width + k_line_map_x + parseInt(k_line_width/2) + 10, get_y_value((stock_max_price - stock_min_price) + stock_min_price),
            (Math.round(((stock_max_price - stock_min_price) + stock_min_price)*100)/100).toString(), "15", "rgb(255,0,0)");
        svg.appendChild(text_max);
        for(var i = stock_data_end_index; i >= stock_data_start_index && i >=0 ; i--) {
            draw_k_line(i, stock_data.items[i].item_start_price, stock_data.items[i].item_end_price,
                stock_data.items[i].item_highest_price, stock_data.items[i].item_lowest_price);
        }

        //var poly_line = createPolyLine("poly_line", "0,0 100,100 200,200 300,300", "1", "green");
        //svg.appendChild(poly_line);
        draw_3_3_line();

        if (computed_max_price > 0 && computed_min_price >= 0) {
            display_gold_line_between_prices(computed_min_price, computed_max_price);
        }


    }
    function draw_3_3_line() {
        var points_array = "";
        var prev_x = -1;
        var prev_y = -1;
        for(i = stock_data_end_index; i >= stock_data_start_index; i--) {
            if (i - 6 >= 0 ) {
                var x = get_x_value(i);
                var avg_price = (parseFloat(stock_data.items[i-5].item_end_price) +  parseFloat(stock_data.items[i-4].item_end_price)
                    + parseFloat(stock_data.items[i-3].item_end_price))/3;
                if (prev_x != -1 && prev_y != -1 ) {
                    var line_3_3 = createLine("line_3_3_" + i.toString(), prev_x, prev_y, x, get_y_value(avg_price), "1", "green");
                    svg.appendChild(line_3_3);
                }
                prev_x = x;
                prev_y = get_y_value(avg_price);
            }
        }
    }
    function get_y_value(price) {
        return parseInt(k_line_map_y + k_line_map_height * (stock_max_price - price)/(stock_max_price - stock_min_price));
    }
    function get_price(y) {
        var max_y = get_y_value(stock_max_price);
        var min_y = get_y_value(stock_min_price);
        if (min_y >= y && max_y <= y) {
            var price = stock_min_price + (stock_max_price-stock_min_price) * (y - min_y)/(max_y - min_y);
            return price;
        }
        else {
            return 0;
        }
    }
    function get_x_value(item_index) {
        var x_val = k_line_map_x + (item_index - stock_data_start_index) * k_line_width;
        return parseInt(x_val);

    }
    function get_item_index(x) {
        var idx = (x/k_line_width) + stock_data_start_index - k_line_map_x;
        return Math.min(parseInt(idx), stock_data_end_index);
    }
    function draw_k_line(item_index, start_price, end_price, highest_price, lowest_price) {
        var k_line_color = "rgb(255,0,0)";
        if (end_price < start_price) {
            color = "rgb(0,255,0)";
        }
        else if (end_price == start_price ) {
            color = "rgb(100,100,100)";
        }
        else {
            color = "rgb(255,0,0)";
        }
        var x = get_x_value(item_index);
        var upper_limit = Math.max(start_price, end_price);
        var lower_limit = Math.min(start_price, end_price);

        if (highest_price > upper_limit) {
            var upper_shaddow_line = createLine("shaddow_upper_" + item_index.toString(), x, get_y_value(highest_price), x, get_y_value(upper_limit), "1px", color);
            upper_shaddow_line.setAttributeNS(xmlns, "name", "k_line_upper");
            svg.appendChild(upper_shaddow_line);
        }
        if (upper_limit == lower_limit){
            var k_line = createLine("k_" + item_index.toString(), x, get_y_value(upper_limit)-1, x, get_y_value(lower_limit)+1,
                (k_line_width-1).toString() + "px", color);
            k_line.setAttributeNS(xmlns, "name", "k_line");
            svg.appendChild(k_line);
        }
        else {
            var k_line = createLine("k_" + item_index.toString(), x, get_y_value(upper_limit), x, get_y_value(lower_limit),
                (k_line_width-1).toString() + "px", color);
            k_line.setAttributeNS(xmlns, "name", "k_line");
            svg.appendChild(k_line);
        }
        if (lowest_price < lower_limit) {
            var lower_shaddow_line = createLine("shaddow_lower_" + item_index, x, get_y_value(lower_limit), x, get_y_value(lowest_price), "1px", color);
            lower_shaddow_line.setAttributeNS(xmlns, "name", "k_line_lower");
            svg.appendChild(lower_shaddow_line);
        }
    }
    function mouse_move(evt) {
        show_price_date(evt);
        if (draw_state){
            draw_gold_line(evt);
        }
    }
    function show_hide_box(evt) {
        alert(evt);
    }
    function mouse_down(evt) {
        if (draw_state) {
            if (gold_line_current_high_light_position=="min") {
                gold_line_min_idx = gold_line_current_idx;
                gold_line_min_price = stock_data.items[gold_line_min_idx].item_lowest_price;
            }
            else if (gold_line_current_high_light_position=="max"){
                gold_line_max_idx = gold_line_current_idx;
                gold_line_max_price = stock_data.items[gold_line_max_idx].item_highest_price;
            }
        }
    }
    function mouse_up(evt) {
        if (draw_state) {

            if (gold_line_max_idx == -1) {
                gold_line_max_idx = gold_line_another_idx;
            }
            if (gold_line_min_idx == -1){
                gold_line_min_idx = gold_line_another_idx;
            }
            hide_gold_line();
            if (gold_line_min_idx != gold_line_another_idx || gold_line_max_idx != gold_line_another_idx) {
                display_gold_line_between_prices(stock_data.items[gold_line_min_idx].item_lowest_price,
                    stock_data.items[gold_line_max_idx].item_highest_price);
            }
            hide_high_light_point_1();
            hide_high_light_point_2();
            draw_state = false;
            gold_line_another_idx = -1;
            gold_line_max_idx = -1;
            gold_line_min_idx = -1;
            var btn_draw = document.getElementById("btn_draw");
            btn_draw.style.backgroundColor = "white";
        }
    }

    
</script>
</html>
