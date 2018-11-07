<%@ Page Language="C#" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="System.Data" %>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        string[] gidArr = Util.GetAllGids();
        Regex regIn = new Regex("id=\"inVolume\".+>\\d+\\.*\\d*</td>");
        Regex regOut = new Regex("id=\"outVolume\".+>\\d+\\.*\\d*</td>");
        Match matchIn, matchOut;
        foreach (string gid in gidArr)
        {
            string content = "";
            try
            {
                content = Util.GetWebContent("http://stockdata.stock.hexun.com/newstock.html?c=" + gid.Substring(2, 6) + "&m=1");
                matchIn = regIn.Match(content);
                matchOut = regOut.Match(content);
                if (matchIn.Success && matchOut.Success)
                {
                    string inContent = matchIn.Value;
                    string outContent = matchOut.Value;
                }
            }
            catch(Exception err)
            {
                Response.Write(err.ToString());
            }
        }
    }
</script>