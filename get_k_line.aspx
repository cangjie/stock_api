﻿<%@ Page Language="C#" %>
<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        string gid = Util.GetSafeRequestValue(Request, "gid", "sz002579");
        DateTime startDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "start", "2017-3-1"));
        DateTime endDate = DateTime.Parse(Util.GetSafeRequestValue(Request, "end", "2017-6-15"));
        KLine[] kArr = KLine.GetKLine("day", gid, startDate, endDate);
        string jsonStr = "{\"type\": \"day\", \"gid\": \"" + gid.Trim() + "\", "
            + "\"start_time\": \"" + startDate.ToShortDateString()+"\", \"end_time\": \"" + endDate.ToShortDateString() + "\" , ";
        string itemJsonStr = "";
        foreach (KLine k in kArr)
        {
            if (!itemJsonStr.Trim().Equals(""))
            {
                itemJsonStr = itemJsonStr + ",";
            }
            itemJsonStr = itemJsonStr + "{\"item_start_time\": \"" + k.startDateTime.ToString() + "\", "
                + "\"item_end_time\": \"" + k.endDateTime.ToString() + "\", "
                + "\"item_start_price\": \"" + k.startPrice.ToString() + "\", "
                + "\"item_end_price\": \"" + k.endPrice.ToString() + "\" , "
                + "\"item_highest_price\": \"" + k.highestPrice.ToString() + "\" , "
                + "\"item_lowest_price\": \"" + k.lowestPrice.ToString() + "\" , "
                + "\"item_deal\": \"" + k.deal.ToString() + "\" , "
                + "\"item_volumn\": \"" + k.volume.ToString() + "\" , "
                + "\"item_change\": \"" + k.change.ToString() + "\" }";
        }
        jsonStr = jsonStr + "  \"items\": [" + itemJsonStr.Trim() + "] }";
        Response.Write(jsonStr);
    }
</script>