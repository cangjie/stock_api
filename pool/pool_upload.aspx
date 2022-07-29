<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.IO" %>
<!DOCTYPE html>

<script runat="server">

    public string currentTimeStamp = "";
    public string prevTimeStamp = "";
    public string sort = "anchor_date desc";


    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            dg.DataSource = GetData();
            dg.DataBind();
        }
    }

    protected void btn_Click(object sender, EventArgs e)
    {
        DataTable dtOri = GetData();
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
                    DataRow[] drOriArr = dtOri.Select("gid = '" + gid.Trim() + "' ");
                    if (drOriArr.Length > 0)
                    {
                        try
                        {
                            if (!drOriArr[0]["anchor"].ToString().Trim().Equals(""))
                            {
                                DateTime anchorDate = DateTime.Parse(drOriArr[0]["anchor"].ToString());
                                DBHelper.InsertData("pool", new string[,] { { "gid", "varchar", gid.Trim().ToLower() },
                                    { "batch_id", "varchar", timeStamp.Trim().Replace("'", "") },
                                    {"anchor_date", "datetime", anchorDate.Year.ToString() + "-" + anchorDate.Month.ToString() + "-" + anchorDate.Day.ToString() } });
                            }
                            else
                            {
                                DBHelper.InsertData("pool", new string[,] { { "gid", "varchar", gid.Trim().ToLower() }, { "batch_id", "varchar", timeStamp.Trim().Replace("'", "") } });
                            }

                        }
                        catch
                        {
                            DBHelper.InsertData("pool", new string[,] { { "gid", "varchar", gid.Trim().ToLower() }, { "batch_id", "varchar", timeStamp.Trim().Replace("'", "") } });
                        }
                    }
                    else
                    {
                        DBHelper.InsertData("pool", new string[,] { { "gid", "varchar", gid.Trim().ToLower() }, { "batch_id", "varchar", timeStamp.Trim().Replace("'", "") } });
                    }
                }

            }
            catch
            {

            }
            info.Text = "上传成功。";
            dg.DataSource = GetData();
            dg.EditItemIndex = -1;
            dg.DataBind();
        }
    }

    protected void btnAddNew_Click(object sender, EventArgs e)
    {
        GetData();
        try
        {
            DateTime anhorDate = DateTime.Parse(txtDate.Text.Trim());
            string gid = txtGid.Text.Trim();
            if (gid.Length == 6)
            {
                if (gid.StartsWith("60"))
                {
                    gid = "sh" + gid.Trim();
                }
                else
                {
                    gid = "sz" + gid.Trim();
                }
            }
            DBHelper.InsertData("pool", new string[,] { { "gid", "varchar", gid.Trim()},
                { "anchor_date", "datetime", anhorDate.Year.ToString() + "-" + anhorDate.Month.ToString() + "-" + anhorDate.Day.ToString()},
                {"batch_id", "varchar", currentTimeStamp.Trim() } });
            dg.DataSource = GetData();
            dg.EditItemIndex = -1;
            dg.DataBind();
            txtDate.Text = "";
            txtGid.Text = "";
        }
        catch
        {

        }


    }

    public DataTable GetData()
    {
        DataTable dtTimeStamp = DBHelper.GetDataTable(" select distinct batch_id from pool order by batch_id desc  ");
        if (dtTimeStamp.Rows.Count > 0)
        {
            currentTimeStamp = dtTimeStamp.Rows[0]["batch_id"].ToString().Trim();
            if (dtTimeStamp.Rows.Count > 1)
            {
                prevTimeStamp = dtTimeStamp.Rows[1]["batch_id"].ToString().Trim();
            }
        }
        dtTimeStamp.Dispose();
        DataTable dt = new DataTable();
        dt.Columns.Add("gid");
        dt.Columns.Add("anchor");
        dt.Columns.Add("name");
        DataTable dtOri = DBHelper.GetDataTable(" select * from pool where batch_id = '" + currentTimeStamp.Trim() + "' ");

        string currentSort = "anchor_date desc";

        if (sort.Trim().Equals("gid"))
        {
            currentSort = "gid";
        }

        DataRow[] drArrOri = dtOri.Select("", currentSort);
        foreach (DataRow drOri in drArrOri)
        {
            DataRow dr = dt.NewRow();
            dr["gid"] = drOri["gid"].ToString().Trim();
            Stock s = new Stock(drOri["gid"].ToString().Trim());
            dr["name"] = s.Name.Trim();

            if (!drOri["anchor_date"].ToString().Trim().Equals(""))
            {
                DateTime aDate = DateTime.Parse(drOri["anchor_date"].ToString().Trim());
                dr["anchor"] = aDate.Year.ToString() + "-" + aDate.Month.ToString() + "-" + aDate.Day.ToString();
            }
            else
            {
                dr["anchor"] = "";
            }


            dt.Rows.Add(dr);
        }

        if (sort.Trim().Equals("name"))
        {
            DataTable dtNew = dt.Clone();
            foreach(DataRow dr in dt.Select("", "name"))
            {
                DataRow drNew = dtNew.NewRow();
                drNew[0] = dr[0];
                drNew[1] = dr[1];
                drNew[2] = dr[2];
                dtNew.Rows.Add(drNew);
            }
            return dtNew;
        }
        else
        {
            return dt;
        }
    }




    protected void dg_DeleteCommand(object source, DataGridCommandEventArgs e)
    {
        string gid = dg.Items[e.Item.ItemIndex].Cells[2].Text.Trim();
        GetData();
        DBHelper.DeleteData("pool", new string[,] { { "gid", "varchar", gid.Trim() }, { "batch_id", "varchar", currentTimeStamp } }, Util.conStr);
        dg.DataSource = GetData();
        dg.EditItemIndex = -1;
        dg.DataBind();

    }

    protected void dg_EditCommand(object source, DataGridCommandEventArgs e)
    {
        try
        {
            sort = ViewState["sort"].ToString().Trim();
        }
        catch
        {

        }
        dg.DataSource = GetData();
        dg.EditItemIndex = e.Item.ItemIndex;
        dg.DataBind();
    }

    protected void dg_UpdateCommand(object source, DataGridCommandEventArgs e)
    {
        GetData();
        string inputDate = ((TextBox)dg.Items[e.Item.ItemIndex].Cells[4].Controls[0]).Text.Trim();
        try
        {
            DateTime.Parse(inputDate);
            string gid = dg.Items[e.Item.ItemIndex].Cells[2].Text.Trim();
            DBHelper.UpdateData("pool", new string[,] { { "anchor_date", "datetime", inputDate } },
                new string[,] { { "gid", "varchar", gid }, { "batch_id", "varchar", currentTimeStamp.Trim() } }, Util.conStr.Trim());

        }
        catch
        {

        }
        try
        {
            sort = ViewState["sort"].ToString().Trim();
        }
        catch
        {

        }
        dg.DataSource = GetData();
        dg.EditItemIndex = -1;
        dg.DataBind();
    }

    protected void dg_CancelCommand(object source, DataGridCommandEventArgs e)
    {
        try
        {
            sort = ViewState["sort"].ToString().Trim();
        }
        catch
        {

        }
        dg.DataSource = GetData();
        dg.EditItemIndex = -1;
        dg.DataBind();
    }

    protected void dg_SortCommand(object source, DataGridSortCommandEventArgs e)
    {
        sort = e.SortExpression.Trim();
        ViewState["sort"] = sort;
        dg.DataSource = GetData();
        dg.EditItemIndex = -1;
        dg.DataBind();
    }

    protected void Button1_Click(object sender, EventArgs e)
    {
        try
        {
            sort = ViewState["sort"].ToString().Trim();
        }
        catch
        {

        }
        DataTable dt = GetData();
        string content = "";
        foreach (DataRow dr in dt.Rows)
        {
            string gid = dr["gid"].ToString().Trim();
            content += gid + "\r\n";
        }
        Response.Clear();
        Response.ContentType = "text/plain";
        Response.Headers.Add("Content-Disposition", "attachment; filename=pool.txt");
        Response.Write(content.Trim());
        Response.End();
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
            &nbsp;&nbsp;&nbsp;&nbsp;
            <asp:Button runat="server" ID="Button1" Text=" 下 载 " OnClick="Button1_Click" />
        </div>
        <div><asp:Label runat="server" ID="info"  ></asp:Label></div>
        <div> </div>
        <div>逐个添加 代码：<asp:TextBox ID="txtGid" runat="server" ></asp:TextBox> 时间点：<asp:TextBox ID="txtDate" runat="server"></asp:TextBox> <asp:Button ID="btnAddNew" runat="server" Text=" 添 加 " OnClick="btnAddNew_Click" /></div>
        <div>
            <asp:DataGrid ID="dg" runat="server"  Width="100%" AutoGenerateColumns="False" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" Font-Size="Small" GridLines="Vertical" OnDeleteCommand="dg_DeleteCommand" OnEditCommand="dg_EditCommand" OnUpdateCommand="dg_UpdateCommand" OnCancelCommand="dg_CancelCommand" AllowSorting="True" OnSortCommand="dg_SortCommand" >
                <AlternatingItemStyle BackColor="#DCDCDC" />
                <Columns>
                    <asp:ButtonColumn CommandName="Delete" Text="删除"></asp:ButtonColumn>
                    <asp:EditCommandColumn CancelText="取消" EditText="编辑" UpdateText="更新"></asp:EditCommandColumn>
                    <asp:BoundColumn DataField="gid" HeaderText="代码" ReadOnly="True" SortExpression="gid"></asp:BoundColumn>
                    <asp:BoundColumn DataField="name" HeaderText="名称" ReadOnly="True" SortExpression="name"></asp:BoundColumn>
                    <asp:BoundColumn DataField="anchor" HeaderText="时间点" SortExpression="anchor"></asp:BoundColumn>
                </Columns>
                <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
                <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
                <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
                <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
                <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
            </asp:DataGrid>
        </div>
    </form>
</body>
</html>
