<%@ Page Language="C#" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="System.Data" %>
<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        Regex r = new Regex("\\d+\\.*\\d*,\\d+\\.*\\d*");
        DateTime volumeDate = DateTime.Now.Date;
        if (Util.IsTransacDay(volumeDate))
        {
            string[] gidArr = Util.GetAllGids();
            //gidArr = new string[] { "sh600093" };
            foreach (string gid in gidArr)
            {
                DataTable dt = DBHelper.GetDataTable(" select * from io_volume where gid = '" + gid.Trim() + "' and trans_date = '" + volumeDate.ToShortDateString() + "' ");
                if (dt.Rows.Count == 0)
                {
                    string jsonContent = "";
                    try
                    {
                        jsonContent = Util.GetWebContent("http://vip.stock.finance.sina.com.cn/quotes_service/view/CN_TransListV2.php?num=1&symbol=" + gid.Trim());
                    }
                    catch
                    {
                        Response.Write("Firewall forbidden.");
                        break;
                    }
                    int startIndex = jsonContent.IndexOf("var trade_INVOL_OUTVOL=[");
                    jsonContent = jsonContent.Substring(startIndex, jsonContent.Length - startIndex);
                    Match m = r.Match(jsonContent);
                    if (m.Success)
                    {
                        string temp = m.Value.Trim();
                        try
                        {
         
                            DBHelper.InsertData("io_volume", new string[,] { {"trans_date", "datetime", volumeDate.ToShortDateString() }, {"gid", "varchar", gid.Trim() }
                                , {"in_volume", "float", m.Value.Trim().Split(',')[0].Trim() }, {"out_volume", "float", m.Value.Split(',')[1].Trim() } });
            
                        }
                        catch
                        {

                        }
                    }
                    System.Threading.Thread.Sleep(1000);
                }
                dt.Dispose();


                
                
            }
        }
    }
</script>