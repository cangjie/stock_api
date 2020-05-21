<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<!DOCTYPE html>

<script runat="server">

    public DataTable dt = new DataTable();

    public DateTime currentDate = DateTime.Now.Date;

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            dt = DBHelper.GetDataTable(" select * from alert_foot_reverse where alert_date = '" + currentDate.ToShortDateString() + "'  order by  kdj,macd,limit_up_times desc " );
        }
    }

    public string FormatFloat(double num)
    {
        num = Math.Round(num, 2);
        string str = num.ToString();
        if (str.Split('.').Length == 1)
        {
            str = str + ".00";
        }
        else
        {
            str = str.Split('.')[0].Trim() + "." + str.Split('.')[1].PadRight(2, '0');
        }
        return str;
    }
</script>

<html>
<head runat="server">
    <link rel="stylesheet" href="css/bootstrap.css" />
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">


    
    
    <title>无影脚</title>
</head>
<body>
    <div class="container">
        <div class="row justify-content-md-center" >
            <div class="col" ><b>代码</b></div>
            <div class="col" ><b>名称</b></div> 
            <div class="col-7" >
                <div class="container">
                    <div class="row justify-content-md-center" >
                        <div class="col" ><b>形态</b></div>
                        <div class="col" ><b>KDJ</b></div>
                        <div class="col"><b>MACD</b></div>
                        <div class="col"><b>幅度</b></div>
                        <div class="col"><b>前高</b></div>
                        <div class="col"><b>F3</b></div>
                        <div class="col"><b>F5</b></div>
                        <div class="col"><b>前低</b></div>
                        <div class="col"><b>买入</b></div>
                    </div>
                </div>
            </div>
            <div class="col"><b>无影价</b></div>
            <div class="col"><b>无影时</b></div>
            <div class="col"><b>无影幅度</b></div>
        </div>
        <%
            foreach (DataRow dr in dt.Rows)
            {
                bool invalid = false;
                if (int.Parse(dr["valid"].ToString().Trim()) == 0)
                {
                    invalid = true;
                }
            %>
        <div class="row">
            <div class="col-12" ><hr /></div>
        </div>

        <div class="row" >
            <div class="col" <% if (invalid)
                { %> style="text-decoration:line-through" <%} %> ><%=dr["gid"].ToString() %></div>
            <div class="col" <% if (invalid)
                { %> style="text-decoration:line-through" <%} %> ><%=dr["name"].ToString() %></div> 
            <div class="col-7" >
                <div class="container">
                    <div class="row" >
                        <%
                            double highest = double.Parse(dr["highest"].ToString().Trim());
                            double lowest = double.Parse(dr["lowest"].ToString().Trim());
                            %>
                        <div class="col" <% if (invalid)
                { %> style="text-decoration:line-through" <%} %>><%=dr["shape"].ToString().Trim() %></div>
                        <div class="col text-right" <% if (invalid)
                { %> style="text-decoration:line-through" <%} %> ><%=dr["kdj"].ToString().Trim() %></div>
                        <div class="col text-right" <% if (invalid)
                { %> style="text-decoration:line-through" <%} %> ><%=dr["macd"].ToString().Trim() %></div>
                        <div class="col text-right" <% if (invalid)
                { %> style="text-decoration:line-through" <%} %> ><%=FormatFloat(100*(highest-lowest)/lowest) %>%</div>
                        <div class="col text-right" <% if (invalid)
                { %> style="text-decoration:line-through" <%} %> ><%=FormatFloat(highest) %></div>
                        <div class="col text-right" <% if (invalid)
                { %> style="text-decoration:line-through" <%} %> ><%=FormatFloat(highest - (highest-lowest)*0.382) %></div>
                        <div class="col text-right" <% if (invalid)
                { %> style="text-decoration:line-through" <%} %> ><%=FormatFloat(highest - (highest-lowest)*0.618) %></div>
                        <div class="col text-right" <% if (invalid)
                { %> style="text-decoration:line-through" <%} %> ><%=FormatFloat(lowest) %></div>
                        <div class="col text-right" <% if (invalid)
                { %> style="text-decoration:line-through" <%} %> ><%=FormatFloat(double.Parse(dr["buy_price"].ToString().Trim())) %></div>
                    </div>
                </div>
            </div>
            <div class="col text-right" <% if (invalid)
                { %> style="text-decoration:line-through" <%} %> ><%=FormatFloat(double.Parse(dr["no_shaddow_price"].ToString().Trim())) %></div>
            <div class="col" <% if (invalid)
                { %> style="text-decoration:line-through" <%} %> ><%=DateTime.Parse(dr["no_shaddow_time"].ToString().Trim()).ToShortTimeString()%></div>
            <div class="col text-right" <% if (invalid)
                { %> style="text-decoration:line-through" <%} %> ><%=FormatFloat(100*double.Parse(dr["no_shaddow_rate"].ToString().Trim())) %>%</div>
        </div>
        <%
            }
            %>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/jquery@3.4.1/dist/jquery.slim.min.js" integrity="sha384-J6qa4849blE2+poT4WnyKhv5vZF5SrPo0iEjwBvKU7imGFAV0wwj1yYfoRSJoZ+n" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js" integrity="sha384-Q6E9RHvbIyZFJoft+2mJbHaEWldlvI9IOYy5n3zV9zzTtmI3UksdQRVvoxMfooAo" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.4.1/dist/js/bootstrap.min.js" integrity="sha384-wfSDF2E50Y2D1uUdj0O3uMBJnjuUD4Ih7YwaYd1iqfktj0Uod8GCExl3Og8ifwB6" crossorigin="anonymous"></script>

</body>
</html>
