DROP TABLE IF EXISTS test_npopkov_agrmnt_sequence_results;
DO
$do$
DECLARE
loops integer := 2;
ts timestamp;
classic_time INTERVAL;
main_time INTERVAL;
hash_time INTERVAL;
classic_time_arr INTERVAL[] := '{}';
main_time_arr INTERVAL[] := '{}';
hash_time_arr INTERVAL[] := '{}';
BEGIN
  
   FOR i IN 0 .. loops
   LOOP

   DROP TABLE IF EXISTS test_npopkov_agrmnt_attr_h_3al;
   DROP TABLE IF EXISTS test_npopkov_agrmnt_attr_h_main;
   DROP TABLE IF EXISTS test_npopkov_agrmnt_attr_h_hash;
  
   ts = CLOCK_TIMESTAMP();
  
   CREATE TEMPORARY TABLE test_npopkov_agrmnt_attr_h_3al
   AS 
   WITH
   CTE_Attributes AS
   (
   SELECT
   *
   ,daterange(start_dt, end_dt+1) AS prd
   FROM данные AS t
   WHERE 1=1
   --AND agrmnt_id IN (5903367217,5826759817)
   AND attr_id IN (5, 247 ,248 ,249 ,250 ,251 ,252 ,253 ,254)
   ),
  
   CTE_Ranges AS
   (
   SELECT
      agrmnt_id ,
      start_dt ,
      LEAD(start_dt, 1, DATE'9999-12-31') OVER (PARTITION BY agrmnt_id ORDER BY START_dt) AS end_dt
   FROM(SELECT agrmnt_id , start_dt
       FROM CTE_Attributes
       UNION
       SELECT agrmnt_id , end_dt -1 AS start_dt
       FROM CTE_Attributes) sub )
  
   SELECT
   dt.Agrmnt_id
   ,max(CASE attr_id WHEN 5 THEN val_int END) AS att_5
   ,max(CASE attr_id WHEN 247 THEN val_int END) AS att_247
   ,max(CASE attr_id WHEN 248 THEN val_int END) AS att_248
   ,max(CASE attr_id WHEN 249 THEN val_int END) AS att_249
   ,max(CASE attr_id WHEN 250 THEN val_int END) AS att_250
   ,max(CASE attr_id WHEN 251 THEN val_int END) AS att_251
   ,max(CASE attr_id WHEN 252 THEN val_int END) AS att_252
   ,max(CASE attr_id WHEN 253 THEN val_int END) AS att_253
   ,max(CASE attr_id WHEN 254 THEN val_int END) AS att_254
   FROM CTE_Ranges AS dt
   LEFT JOIN CTE_Attributes AS Attr ON attr.agrmnt_id = dt.agrmnt_id
                              and attr.start_dt <= dt.start_dt
                              AND attr.end_dt >= dt.end_dt
   GROUP BY 1
   WITH DATA
   DISTRIBUTED BY (agrmnt_id);

   classic_time = CLOCK_TIMESTAMP() - ts;

   ts = CLOCK_TIMESTAMP();

   CREATE TEMPORARY TABLE test_npopkov_agrmnt_attr_h_main
   AS
   WITH
   CTE_Attributes AS
   (
   SELECT
   *
   ,daterange(start_dt, end_dt+1) AS prd
   FROM данные AS t
   WHERE 1=1
   --AND agrmnt_id IN (5903367217,5826759817)
   AND attr_id IN (5, 247 ,248 ,249 ,250 ,251 ,252 ,253 ,254)
   ),
  
   CTE_Ranges AS
   ( SELECT
   agrmnt_id
   ,UNNEST(range_dissect(prd)) AS prd
   FROM CTE_Attributes
   GROUP BY 1
   )
  
   SELECT
   dt.Agrmnt_id
   ,max(CASE attr_id WHEN 5 THEN val_int END) AS att_5
   ,max(CASE attr_id WHEN 247 THEN val_int END) AS att_247
   ,max(CASE attr_id WHEN 248 THEN val_int END) AS att_248
   ,max(CASE attr_id WHEN 249 THEN val_int END) AS att_249
   ,max(CASE attr_id WHEN 250 THEN val_int END) AS att_250
   ,max(CASE attr_id WHEN 251 THEN val_int END) AS att_251
   ,max(CASE attr_id WHEN 252 THEN val_int END) AS att_252
   ,max(CASE attr_id WHEN 253 THEN val_int END) AS att_253
   ,max(CASE attr_id WHEN 254 THEN val_int END) AS att_254
   FROM CTE_Ranges AS dt
   LEFT JOIN CTE_Attributes AS Attr ON attr.agrmnt_id = dt.agrmnt_id and attr.prd @> dt.prd
   GROUP BY 1
   WITH DATA
   DISTRIBUTED BY (agrmnt_id);
  
   main_time = CLOCK_TIMESTAMP() - ts;

   ts = CLOCK_TIMESTAMP();

   CREATE TEMPORARY TABLE test_npopkov_agrmnt_attr_h_hash
   AS 
   WITH
   CTE_Attributes AS
   (
   SELECT
   *
   ,daterange(start_dt, end_dt+1) AS prd
   FROM данеые t
   WHERE 1=1
   --AND agrmnt_id IN (5903367217,5826759817)
   AND attr_id IN (5, 247 ,248 ,249 ,250 ,251 ,252 ,253 ,254)
   ),
  
   CTE_Ranges AS
   ( SELECT
   agrmnt_id
   ,UNNEST(range_dissect_3ff(prd)) AS prd
   FROM CTE_Attributes
   GROUP BY 1
   )
  
   SELECT
   dt.Agrmnt_id
   ,max(CASE attr_id WHEN 5 THEN val_int END) AS att_5
   ,max(CASE attr_id WHEN 247 THEN val_int END) AS att_247
   ,max(CASE attr_id WHEN 248 THEN val_int END) AS att_248
   ,max(CASE attr_id WHEN 249 THEN val_int END) AS att_249
   ,max(CASE attr_id WHEN 250 THEN val_int END) AS att_250
   ,max(CASE attr_id WHEN 251 THEN val_int END) AS att_251
   ,max(CASE attr_id WHEN 252 THEN val_int END) AS att_252
   ,max(CASE attr_id WHEN 253 THEN val_int END) AS att_253
   ,max(CASE attr_id WHEN 254 THEN val_int END) AS att_254
   FROM CTE_Ranges AS dt
   LEFT JOIN CTE_Attributes AS Attr ON attr.agrmnt_id = dt.agrmnt_id and attr.prd @> dt.prd
   GROUP BY 1
   WITH DATA
   DISTRIBUTED BY (agrmnt_id);

   hash_time = CLOCK_TIMESTAMP() - ts;

   classic_time_arr[i] = classic_time;
   main_time_arr[i] = main_time;
   hash_time_arr[i] = hash_time;
  
   END LOOP;

   CREATE TEMPORARY TABLE test_npopkov_agrmnt_sequence_results
   AS
   SELECT 'classic' AS Typ, UNNEST(classic_time_arr) AS Tim
   UNION ALL
   SELECT 'main', UNNEST(main_time_arr)
   UNION ALL
   SELECT 'hash', UNNEST(hash_time_arr)
   WITH DATA
   DISTRIBUTED randomly;

END;
$do$;

SELECT
Typ,
to_char(avg(Tim), 'SS.MS') AS avgg,
to_char(median(Tim), 'SS.MS') AS med
FROM test_npopkov_agrmnt_sequence_results
GROUP BY 1
ORDER BY 1,2;

 