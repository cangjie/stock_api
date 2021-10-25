using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using StackExchange.Redis;
using System.Collections;


    public class RedisClient
    {
        public ConnectionMultiplexer redis;
        public IDatabase redisDb;

        public RedisClient(string address)
        {
            redis = ConnectionMultiplexer.Connect(address);
            redisDb = redis.GetDatabase();
        }

        public void Dispose()
        {
            redis.Dispose();
        }


        public static string[] GetKeys(string key, RedisClient rc)
        {
            var server = rc.redis.GetServer("127.0.0.1:6379");
            ArrayList keysArr = new ArrayList();
            var keyArr = server.Keys(pattern: key);
            int i = 0;
            string r = "";
            foreach (var k in keyArr)
            {
                r = r + (r.Trim().Equals("") ? "" : ",") + (string)k;
                i++;
            }
            /*
            string[] keyStringArr = new string[i];
            i = 0;
            foreach (var k in keyArr)
            {
                keyStringArr[i] = (string)k;
                i++;
            }
            

            return keyStringArr;
            */
            return r.Split(',');
        }
    }

