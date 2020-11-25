<%@ Page Language="C#" %>
<%@ Import Namespace="System.Collections" %>
<!DOCTYPE html>

<script runat="server">

    public ArrayList gidGoldArr = new ArrayList();

    public static Core.RedisClient rc = new Core.RedisClient("52.81.252.140");

    protected void Page_Load(object sender, EventArgs e)
    {
        string[] gidArr = Util.GetAllGids();
        foreach (string gid in gidArr)
        {
            KLine[] klineMonth = Stock.LoadMonthKLine(gid, rc);
            KLine.ComputeMACD(klineMonth);
            KLine.ComputeRSV(klineMonth);
            KLine.ComputeKDJ(klineMonth);

            KLine lastKLine = klineMonth[klineMonth.Length - 1];
            if (lastKLine.macd > 0 && lastKLine.j > lastKLine.d)
            {
                gidGoldArr.Add(gid);
                try
                {
                    DBHelper.InsertData("alert_month_k_line_gold", new string[,] { {"alert_date", "datetime", DateTime.Now.ToShortDateString() },
                        {"gid", "varchar", gid } });
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
            <%foreach (string gid in gidGoldArr)
                {
                    Response.Write(gid.Trim() + "<br/>");
                }%>
        </div>
    </form>
</body>
</html>
