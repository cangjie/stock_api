using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for KLineCache
/// </summary>
public class KLineCache
{
    public static string[] allGid = new string[0];

    public static CachedKLine[] kLineDayCache = new CachedKLine[allGid.Length];

    public KLineCache()
    {
        //
        // TODO: Add constructor logic here
        //
    }

    public static void UpdateKLineInCache(CachedKLine c)
    {
        bool exsits = false;
        int firstBlankIndex = -1;
        for (int i = 0; i < kLineDayCache.Length; i++)
        {
            if (kLineDayCache[i].gid == null)
            {
                if (firstBlankIndex == -1)
                {
                    firstBlankIndex = i;
                }
            }
            else
            {
                if (c.gid.Trim().Equals(kLineDayCache[i].gid.Trim()))
                {
                    exsits = true;
                    kLineDayCache[i] = c;
                    break;
                }
            }
        }
        if (!exsits)
        {
            kLineDayCache[firstBlankIndex] = c;
        }
    }

    public static CachedKLine GetKLineCache(string gid)
    {
        CachedKLine c = new CachedKLine();
        c.gid = "";
        foreach (CachedKLine ck in kLineDayCache)
        {
            if (ck.gid != null && ck.gid.Trim().Equals(gid))
            {
                c = ck;
                break;
            }
        }
        return c;
    }

    public static int GetLoadedItemsCount()
    {
        int count = 0;
        foreach (CachedKLine c in kLineDayCache)
        {
            if (c.gid != null)
            {
                count++;
            }
        }
        return count;
    }
}