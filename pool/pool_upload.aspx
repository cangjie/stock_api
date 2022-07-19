<%@ Page Language="C#" %>
<%@ Import Namespace="System.IO" %>
<!DOCTYPE html>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {

    }

    protected void btn_Click(object sender, EventArgs e)
    {
        Stream s = uploadFile.PostedFile.InputStream;
        StreamReader sr = new StreamReader(s);
        string str = sr.ReadToEnd();
        sr.Close();
        s.Close();
        string timeStamp = Util.GetLongTimeStamp(DateTime.Now).Trim();
        foreach (string gid in str.Split('\r'))
        {
            try
            {
                if (!gid.Trim().Equals(""))
                {
                    DBHelper.InsertData("pool", new string[,] { { "gid", "varchar", gid.Trim().ToLower() }, { "batch_id", "varchar", timeStamp.Trim().Replace("'", "") } });
                }
                
            }
            catch
            {

            }
            info.Text = "上传成功。";
        }
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>股票池更新</title>
</head>
<body>
    <form id="form1" runat="server">
        <div>
            <input runat="server" type="file" id="uploadFile" />&nbsp;<asp:Button runat="server" ID="btn" Text=" 上 传 " OnClick="btn_Click" />
        </div>
        <div><asp:Label runat="server" ID="info"  ></asp:Label></div>
    </form>
</body>
</html>
