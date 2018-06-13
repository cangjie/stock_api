<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Threading" %>
<script runat="server">

    public string postedStr1 = "sz300653,正海生物,75.710,68.720,75.970,68.720,3279613,238067803.880,2018-06-13 14:45:24";

    //public string postedStr1 = "sz000800,一汽轿车,11.640,11.790,12.080,11.600,18052758,214539717.260,2018-01-22 11:35:00;sz000014,沙河股份,13.020,13.000,13.200,12.770,3606593,46557765.090,2018-01-22 11:35:00;sz300686,智动力,23.010,23.330,23.390,22.530,1362800,31251032.000,2018-01-22 11:35:03;sz002873,新天药业,43.400,43.930,44.300,42.610,614400,26637086.000,2018-01-22 11:35:00";

    public static Queue postStrQueue = new Queue();

    // public static SqlConnection conn = new SqlConnection();
    // public static SqlCommand cmd = new SqlCommand("", conn);


    protected void Page_Load(object sender, EventArgs e)
    {
        postedStr1 = (new System.IO.StreamReader(Request.InputStream)).ReadToEnd();

        postStrQueue.Enqueue(postedStr1);

        string[] itemArr = postedStr1.Split(';');

        ThreadStart ts = new ThreadStart(DealData);
        Thread t = new Thread(ts);
        t.Start();




        Response.Write(postedStr1);
    }

    public static void DealData()
    {

        SqlConnection conn = new SqlConnection(System.Configuration.ConfigurationSettings.AppSettings["constr"].Trim());
        SqlCommand cmd = new SqlCommand("", conn);
        conn.Open();
        string postedStr = "";
        try
        {
            postedStr = postStrQueue.Dequeue().ToString();
        }
        catch
        {
            return;
        }
        if (postedStr.Trim().Equals(""))
        {
            return;
        }
        string[] items = postedStr.Split(';');
        for (int i = 0; i < items.Length; i++)
        {
            try
            {
                string[] data = items[i].Split(',');
                //int j = InsertTimeline(data, cmd);

                UpdateKLineDB(data, cmd);
                UpdateKLinCache(data);


            }
            catch
            {

            }
            System.Diagnostics.Debug.WriteLine("Deal " + i.ToString() + " items.");
        }
        conn.Close();
        cmd.Dispose();
        conn.Dispose();
    }

    public static int InsertTimeline(string[] data, SqlCommand cmd)
    {
        bool exsists = false;
        cmd.CommandText = "select 'a' from " + data[0].Trim() + "_timeline where ticktime = '" + data[8].Trim() + "' ";
        SqlDataReader sqlReader = cmd.ExecuteReader();
        if (sqlReader.Read())
        {
            exsists = true;
        }
        sqlReader.Close();
        int ret = 0;
        if (!exsists)
        {
            cmd.CommandText = " insert into " + data[0].Trim() + "_timeline (symbol, [name], trade, [open], [high], [low], volume, amount, ticktime ) values ('"
                + data[0].Trim() + "' , '" + data[1].Trim() + "' , '" + data[3].Trim() + "' , '" + data[2].Trim() + "' , '" + data[4].Trim() + "' , '"
                + data[5].Trim() + "' , '" + data[6].Trim() + "' , '" + data[7].Trim() + "' , '" + data[8].Trim() + "' )";
            ret = cmd.ExecuteNonQuery();

        }
        return ret;
    }

    public static void UpdateKLineDB(string[] data, SqlCommand cmd)
    {
        string gid = data[0].Trim();
        DateTime tickTime = DateTime.Parse(data[8].Trim());
        cmd.CommandText = " select 'a' from " + gid.Trim() + "_k_line where [type] = 'day' and start_date >= '" + tickTime.ToShortDateString() + "' ";
        bool exists = false;
        SqlDataReader sqlReader = cmd.ExecuteReader();
        if (sqlReader.Read())
        {
            exists = true;
        }
        sqlReader.Close();
        int i = 0;
        if (exists)
        {
            cmd.CommandText = "update " + gid.Trim() + "_k_line set settle = " + data[3].Trim() + ", highest = " + data[4].Trim() + ", lowest = " + data[5].Trim()
                 + ", volume = " + data[6].Trim() + ", amount = " + data[7].Trim() + " where [type] = 'day' and start_date >= '" + tickTime.ToShortDateString() + "' ";
        }
        else
        {
            cmd.CommandText = "insert into " + gid.Trim() + "_k_line (gid, start_date, [type], [open], settle, highest, lowest, volume, amount, ext_data, create_date) values ('" + gid.Trim()
                + "' , '" + tickTime.ToShortDateString() + " 9:30' , 'day', " + data[2].Trim() + " , " + data[3].Trim() + " , " + data[4].Trim() + " , "
                + data[5].Trim() + " , " + data[6].Trim() + " , " + data[7].Trim() + ", '', getdate() ) ";
        }
        i = cmd.ExecuteNonQuery();
    }

    public static void UpdateKLinCache(string[] data)
    {
        string gid = data[0].Trim();
        KLine[] kArr = Stock.LoadLocalKLine(gid, "day");
        if (kArr.Length == 0)
        {
            kArr = Stock.LoadLocalKLineFromDB(gid, "day");
            CachedKLine cNew1 = new CachedKLine();
            cNew1.gid = gid.Trim();
            cNew1.type = "day";
            cNew1.kLine = kArr;
            cNew1.lastUpdate = DateTime.Now;
            KLineCache.UpdateKLineInCache(cNew1);
            return;
        }

        KLine lastKLine = kArr[kArr.Length - 1];
        if (lastKLine.startDateTime.Date == DateTime.Parse(data[8].Trim()).Date)
        {
            lastKLine.endPrice = double.Parse(data[3].Trim());
            lastKLine.amount = double.Parse(data[7].Trim());
            lastKLine.volume = int.Parse(data[6].Trim());
            kArr[kArr.Length - 1] = lastKLine;

        }
        else
        {
            kArr = Stock.LoadLocalKLineFromDB(gid, "day");
        }
        CachedKLine cNew = new CachedKLine();
        cNew.gid = gid.Trim();
        cNew.type = "day";
        cNew.kLine = kArr;
        cNew.lastUpdate = DateTime.Now;
        KLineCache.UpdateKLineInCache(cNew);
    }


</script>