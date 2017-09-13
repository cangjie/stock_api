<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script runat="server">

    //public static Queue queue = new Queue();

    protected void Page_Load(object sender, EventArgs e)
    {
       
        string[] gidArr = Util.GetAllGids();
        for (int i = 0; i < gidArr.Length; i++)
        {
           
            Stock s = new Stock(gidArr[i]);
            s.LoadKLineDay();

            for (int j = 1; j < s.kLineDay.Length - 1; j++)
            {
                
                if (s.IsLimitUp(j))
                {
                    LimitUp.SaveLimitUp(s.gid.Trim(), DateTime.Parse(s.kLineDay[j].startDateTime.ToShortDateString()), s.kLineDay[j - 1].endPrice,
                        s.kLineDay[j].startPrice, s.kLineDay[j].endPrice, s.kLineDay[j].volume);
                }
            }
        }
    }


</script>
