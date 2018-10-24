<%@ Page Language="C#" %>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        string[] gidArr = Util.GetAllGids();

        foreach (string gid in gidArr)
        {
            try
            {
                string content = Util.GetWebContent("https://finance.sina.com.cn/realstock/company/" + gid + "/nc.shtml");
                int startIndex = content.IndexOf("totalcapital = ");
                if (startIndex >= 0)
                {
                    content = content.Substring(startIndex, content.Length - startIndex);
                    content = content.Substring(0, content.IndexOf(";"));
                    content = content.Replace("totalcapital =", "").Trim();
                    double capital = double.Parse(content) * 10000;
                    DBHelper.DeleteData("capital", new string[,] { { "gid", "varchar", gid.Trim() } }, Util.conStr);
                    DBHelper.InsertData("capital", new string[,] { { "gid", "varchar", gid.Trim() }, {"total_volume", "float", capital.ToString() } });
                }
            }
            catch
            {

            }
        }
    }
</script>