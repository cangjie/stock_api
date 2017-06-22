<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            dg.DataSource = GetData();
            dg.DataBind();
        }

    }

    public DataTable GetData()
    {
        return DBHelper.GetDataTable(" select * from stock_alert order by create_date  ");
    }

    protected void btn_Click(object sender, EventArgs e)
    {
        DataTable dt = GetData();
        DataRow dr = dt.NewRow();
        dt.Rows.Add(dr);
        dg.DataSource = dt;
        dg.EditItemIndex = dt.Rows.Count - 1;
        dg.DataBind();
    }

    protected void dg_EditCommand(object source, DataGridCommandEventArgs e)
    {
        dg.DataSource = GetData();
        dg.EditItemIndex = e.Item.ItemIndex;
        dg.DataBind();
    }

    protected void dg_DeleteCommand(object source, DataGridCommandEventArgs e)
    {
        string gid = dg.Items[e.Item.ItemIndex].Cells[2].Text.Trim();
        DBHelper.DeleteData("stock_alert", new string[,] { { "gid", "varchar", gid } }, Util.conStr.Trim());
        dg.DataSource = GetData();
        dg.DataBind();
    }

    protected void dg_UpdateCommand(object source, DataGridCommandEventArgs e)
    {
        string gid = ((TextBox)e.Item.Cells[2].Controls[0]).Text.Trim();
        string name =  ((TextBox)e.Item.Cells[3].Controls[0]).Text.Trim();
        string topF3 = ((TextBox)e.Item.Cells[4].Controls[0]).Text.Trim();
        string topF5 = ((TextBox)e.Item.Cells[5].Controls[0]).Text.Trim();
        string bottomF3 = ((TextBox)e.Item.Cells[6].Controls[0]).Text.Trim();
        string bottomF5 = ((TextBox)e.Item.Cells[7].Controls[0]).Text.Trim();
        DBHelper.DeleteData("stock_alert", new string[,] { { "gid", "varchar", gid } }, Util.conStr.Trim());
        DBHelper.InsertData("stock_alert", new string[,] {
            { "gid", "varchar", gid}, { "name", "varchar", name.Trim()}, { "top_f3", "float", topF3.Trim()},
            { "top_f5", "varchar", topF5.Trim()}, { "bottom_f3", "varchar", bottomF3.Trim()},
            { "bottom_f5", "varchar", bottomF5.Trim()}
        });

        dg.DataSource = GetData();
        dg.EditItemIndex = -1;
        dg.DataBind();
    }

    protected void dg_CancelCommand(object source, DataGridCommandEventArgs e)
    {
        dg.DataSource = GetData();
        dg.EditItemIndex = -1;
        dg.DataBind();
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <table style="width:100%" >
            <tr>
                <td><asp:Button ID="btn" runat="server" Text=" 添 加 " OnClick="btn_Click" /></td>
            </tr>
            <tr>
                <td><asp:DataGrid ID="dg" runat="server" Width="100%" AutoGenerateColumns="False" BackColor="White" BorderColor="#999999" BorderStyle="None" BorderWidth="1px" CellPadding="3" GridLines="Vertical" OnEditCommand="dg_EditCommand" OnDeleteCommand="dg_DeleteCommand" OnUpdateCommand="dg_UpdateCommand" OnCancelCommand="dg_CancelCommand" >
                    <AlternatingItemStyle BackColor="#DCDCDC" />
                    <Columns>
                        <asp:ButtonColumn CommandName="Delete" Text="删除"></asp:ButtonColumn>
                        <asp:EditCommandColumn CancelText="取消" EditText="编辑" UpdateText="修改"></asp:EditCommandColumn>
                        <asp:BoundColumn DataField="gid" HeaderText="代码"></asp:BoundColumn>
                        <asp:BoundColumn DataField="name" HeaderText="名称"></asp:BoundColumn>
                        <asp:BoundColumn DataField="top_f3" HeaderText="压力位F3"></asp:BoundColumn>
                        <asp:BoundColumn DataField="top_f5" HeaderText="压力位F5"></asp:BoundColumn>
                        <asp:BoundColumn DataField="bottom_f3" HeaderText="支撑位F3"></asp:BoundColumn>
                        <asp:BoundColumn DataField="bottom_f5" HeaderText="支撑位F5"></asp:BoundColumn>
                    </Columns>
                    <FooterStyle BackColor="#CCCCCC" ForeColor="Black" />
                    <HeaderStyle BackColor="#000084" Font-Bold="True" ForeColor="White" />
                    <ItemStyle BackColor="#EEEEEE" ForeColor="Black" />
                    <PagerStyle BackColor="#999999" ForeColor="Black" HorizontalAlign="Center" Mode="NumericPages" />
                    <SelectedItemStyle BackColor="#008A8C" Font-Bold="True" ForeColor="White" />
                    </asp:DataGrid></td>
            </tr>
        </table>
    </div>
    </form>
</body>
</html>
