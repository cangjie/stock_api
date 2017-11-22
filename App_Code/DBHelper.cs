using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;
using System.Data.SqlClient;

/// <summary>
/// Summary description for DBHelper
/// </summary>
public class DBHelper
{
    public DBHelper()
    {
        //
        // TODO: Add constructor logic here
        //
    }

    public static int GetMaxValue(string tableName, string fieldName, string connectionString)
    {
        int maxId = 0;
        SqlConnection conn = new SqlConnection(connectionString);
        SqlCommand cmd = new SqlCommand("  select max( " + fieldName.Trim() + " ) from " + tableName.Trim(), conn);
        conn.Open();
        SqlDataReader dr = cmd.ExecuteReader();
        if (dr.Read())
        {
            maxId = dr.GetInt32(0);
        }
        dr.Close();
        conn.Close();
        cmd.Dispose();
        conn.Dispose();
        return maxId;
    }

    public static KeyValuePair<string, KeyValuePair<SqlDbType, object>>[] ConvertStringArryToKeyValuePairArray(string[,] parameters)
    {
        KeyValuePair<string, KeyValuePair<SqlDbType, object>>[] parametersKeyValuePairArr
            = new KeyValuePair<string, KeyValuePair<SqlDbType, object>>[parameters.Length / 3];
        for (int i = 0; i < parameters.Length / 3; i++)
        {
            parametersKeyValuePairArr[i] = new KeyValuePair<string, KeyValuePair<SqlDbType, object>>(parameters[i, 0].Trim(),
                new KeyValuePair<SqlDbType, object>(GetSqlDbType(parameters[i, 1].Trim()), (object)parameters[i, 2].Trim()));
        }
        return parametersKeyValuePairArr;
    }

    public static SqlDbType GetSqlDbType(string type)
    {
        SqlDbType sqlType;
        switch (type.ToLower())
        {
            case "int":
                sqlType = SqlDbType.Int;
                break;
            case "varchar":
                sqlType = SqlDbType.VarChar;
                break;
            case "datetime":
                sqlType = SqlDbType.DateTime;
                break;
            case "test":
                sqlType = SqlDbType.Text;
                break;
            case "bigint":
                sqlType = SqlDbType.BigInt;
                break;
            default:
                sqlType = SqlDbType.VarChar;
                break;
        }
        return sqlType;
    }

    public static int UpdateData(string tableName, string[,] updateParameters, string[,] keyParameters, string connectionString)
    {
        return UpdateData(tableName, ConvertStringArryToKeyValuePairArray(updateParameters),
            ConvertStringArryToKeyValuePairArray(keyParameters), connectionString);
    }

    public static int UpdateData(string tableName,
        KeyValuePair<string, KeyValuePair<SqlDbType, object>>[] updateParameters,
        KeyValuePair<string, KeyValuePair<SqlDbType, object>>[] keyParameters)
    {
        return UpdateData(tableName, updateParameters, keyParameters, Util.conStr);
    }

    public static int UpdateData(string tableName,
        KeyValuePair<string, KeyValuePair<SqlDbType, object>>[] updateParameters,
        KeyValuePair<string, KeyValuePair<SqlDbType, object>>[] keyParameters, string connectionString)
    {
        SqlCommand cmd = new SqlCommand();

        string setClause = "";
        foreach (KeyValuePair<string, KeyValuePair<SqlDbType, object>> parameter in updateParameters)
        {
            setClause = setClause + ", " + parameter.Key.Trim() + "  = @" + parameter.Key.Trim().Replace("[", "").Replace("]", "") + "  ";
            cmd.Parameters.Add("@" + parameter.Key.Trim().Replace("[", "").Replace("]", ""), parameter.Value.Key);
            cmd.Parameters["@" + parameter.Key.Trim().Replace("[", "").Replace("]", "")].Value = parameter.Value.Value;
        }
        if (setClause.StartsWith(","))
            setClause = setClause.Remove(0, 1);

        string whereClause = "";
        foreach (KeyValuePair<string, KeyValuePair<SqlDbType, object>> parameter in keyParameters)
        {
            whereClause = whereClause + "and " + parameter.Key.Trim() + "  = @" + parameter.Key.Trim().Replace("[","").Replace("]","") + "  ";
            cmd.Parameters.Add("@" + parameter.Key.Trim().Replace("[", "").Replace("]", ""), parameter.Value.Key);
            cmd.Parameters["@" + parameter.Key.Trim().Replace("[", "").Replace("]", "")].Value = parameter.Value.Value;
        }
        if (whereClause.StartsWith("and"))
            whereClause = whereClause.Remove(0, 3);

        cmd.CommandText = " update " + tableName.Trim() + "  set " + setClause.Trim() + "  where " + whereClause.Trim();

        SqlConnection conn = new SqlConnection(connectionString.Trim());
        cmd.Connection = conn;

        conn.Open();
        int i = cmd.ExecuteNonQuery();
        conn.Close();

        cmd.Parameters.Clear();
        cmd.Dispose();
        conn.Dispose();

        return i;
    }

    public static int DeleteData(string tableName, string[,] parameters, string connectionString)
    {
        return DeleteData(tableName, ConvertStringArryToKeyValuePairArray(parameters), connectionString);
    }

    public static int DeleteData(string tableName, KeyValuePair<string, KeyValuePair<SqlDbType, object>>[] parameters, string connectionString)
    {
        if (parameters.Length == 0)
            return 0;
        SqlConnection conn = new SqlConnection(connectionString.Trim());
        SqlCommand cmd = new SqlCommand();
        string whereClause = "";
        foreach (KeyValuePair<string, KeyValuePair<SqlDbType, object>> parameter in parameters)
        {
            whereClause = whereClause + "and " + parameter.Key.Trim() + "  = @" + parameter.Key.Trim() + "  ";
            cmd.Parameters.Add("@" + parameter.Key.Trim(), parameter.Value.Key);
            cmd.Parameters["@" + parameter.Key.Trim()].Value = parameter.Value.Value;
        }
        if (whereClause.StartsWith("and"))
            whereClause = whereClause.Remove(0, 3);

        cmd.CommandText = " delete " + tableName.Trim() + " where  " + whereClause;
        cmd.Connection = conn;
        conn.Open();
        int i = cmd.ExecuteNonQuery();
        conn.Close();
        cmd.Dispose();
        conn.Dispose();
        return i;
    }

    public static int InsertData(string tableName, string[,] parameters)
    {
        return InsertData(tableName, parameters, Util.conStr);
    }

    public static int InsertData(string tableName, KeyValuePair<string, KeyValuePair<SqlDbType, object>>[] parameters)
    {
        return InsertData(tableName, parameters, Util.conStr);
    }

    public static int InsertData(string tableName, string[,] parameters, string connectionString)
    {
        return InsertData(tableName, ConvertStringArryToKeyValuePairArray(parameters), connectionString);
    }

    public static int InsertData(string tableName, KeyValuePair<string, KeyValuePair<SqlDbType, object>>[] parameters, string connectionString)
    {
        SqlConnection conn = new SqlConnection(connectionString.Trim());
        SqlCommand cmd = new SqlCommand();
        string fieldClause = "";
        string valuesClause = "";
        foreach (KeyValuePair<string, KeyValuePair<SqlDbType, object>> param in parameters)
        {
            fieldClause = fieldClause + "," + param.Key.Trim();
            valuesClause = valuesClause + ",@" + param.Key.Replace("[","").Replace("]","").Trim();
            cmd.Parameters.Add("@" + param.Key.Replace("[", "").Replace("]", "").Trim(), param.Value.Key);
            cmd.Parameters["@" + param.Key.Replace("[", "").Replace("]", "").Trim()].Value = param.Value.Value;
        }
        fieldClause = fieldClause.Remove(0, 1);
        valuesClause = valuesClause.Remove(0, 1);
        string sql = " insert into dbo.[" + tableName.Trim() + "]  ( "
            + fieldClause + " )  values (" + valuesClause + " )  ";
        cmd.Connection = conn;
        cmd.CommandText = sql;
        conn.Open();
        int i = cmd.ExecuteNonQuery();
        conn.Close();
        cmd.Parameters.Clear();
        cmd.Dispose();
        conn.Dispose();
        return i;
    }

    public static DataTable GetDataTable(string sql)
    {
        return GetDataTable(sql, Util.conStr);
    }

    public static DataTable GetDataTable(string sql, string connectionString)
    {
        DataTable dt = new DataTable();

        SqlDataAdapter da = new SqlDataAdapter(sql, connectionString.Trim());
        da.Fill(dt);
        da.Dispose();
        return dt;
    }

    public static DataTable GetDataTable(string sql, KeyValuePair<string, KeyValuePair<SqlDbType, object>>[] paramAr)
    {
        return GetDataTable(sql, paramAr, Util.conStr);
    }

    public static DataTable GetDataTable(string sql, KeyValuePair<string, KeyValuePair<SqlDbType, object>>[] paramArr, string connectionString)
    {
        DataTable dt = new DataTable();

        SqlDataAdapter da = new SqlDataAdapter(sql, connectionString.Trim());
        foreach (KeyValuePair<string, KeyValuePair<SqlDbType, object>> param in paramArr)
        {
            da.SelectCommand.Parameters.Add(param.Key.Trim(), param.Value.Key);
            da.SelectCommand.Parameters[param.Key.Trim()].Value = param.Value.Value;
        }
        da.Fill(dt);
        da.SelectCommand.Parameters.Clear();
        da.Dispose();
        return dt;
    }

    public static int GetMaxId(string tableName)
    {
        DataTable dt = GetDataTable(" select max([id]) from " + tableName.Replace("'", "").Trim());
        int id = 0;
        if (dt.Rows.Count == 1)
            id = int.Parse(dt.Rows[0][0].ToString());
        dt.Dispose();
        return id;
    }

}