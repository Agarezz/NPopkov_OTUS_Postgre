DROP TABLE IF EXISTS tt_test_results;
CREATE TABLE tt_test_results
(
	sTest TEXT,
	nRun  int2,
	tTime INTERVAL
)
DISTRIBUTED randomly;

DO
$do$
DECLARE
loops integer := 10;
ts timestamp;
classic_time INTERVAL;
normalize_agg_aa_ac_fsort_time 	INTERVAL;
normalize_agg_aa_ac_fsql_time 	INTERVAL;
normalize_agg_aa_fsort_time 	INTERVAL;
normalize_agg_aa_fsql_time 		INTERVAL;
normalize_agg_aa_cnosort_time 	INTERVAL;
normalize_agg_aa_csort_time 	INTERVAL;
normalize_agg_aa_csql_time 		INTERVAL;
normalize_agg_s_time 			INTERVAL;
normalize_agg_s_cnosort_time 	INTERVAL;
normalize_agg_s_csort_time 		INTERVAL;
normalize_agg_s_csql_time 		INTERVAL;
BEGIN

	
   FOR i IN 0 .. loops
   LOOP
  
		DROP TABLE IF EXISTS tt_test_normalize_classic;
		DROP TABLE IF EXISTS tt_test_normalize_agg_aa_ac_fsort;
		DROP TABLE IF EXISTS tt_test_normalize_agg_aa_ac_fsql;
		DROP TABLE IF EXISTS tt_test_normalize_agg_aa_fsort;
		DROP TABLE IF EXISTS tt_test_normalize_agg_aa_fsql;
		DROP TABLE IF EXISTS tt_test_normalize_agg_aa_cnosort;
		DROP TABLE IF EXISTS tt_test_normalize_agg_aa_csort;
		DROP TABLE IF EXISTS tt_test_normalize_agg_aa_csql;
		DROP TABLE IF EXISTS tt_test_normalize_agg_s;
		DROP TABLE IF EXISTS tt_test_normalize_agg_s_cnosort;
		DROP TABLE IF EXISTS tt_test_normalize_agg_s_csort;
		DROP TABLE IF EXISTS tt_test_normalize_agg_s_csql;
     	
		CREATE TEMPORARY TABLE tt_test_normalize_classic (LIKE test_historical_data) WITH (APPENDONLY = TRUE,COMPRESSTYPE = ZSTD,COMPRESSLEVEL = 1,ORIENTATION = row,OIDS = false) DISTRIBUTED BY (id);
		CREATE TEMPORARY TABLE tt_test_normalize_agg_aa_ac_fsort (LIKE test_historical_data) WITH (APPENDONLY = TRUE,COMPRESSTYPE = ZSTD,COMPRESSLEVEL = 1,ORIENTATION = row,OIDS = false) DISTRIBUTED BY (id);
		CREATE TEMPORARY TABLE tt_test_normalize_agg_aa_ac_fsql (LIKE test_historical_data) WITH (APPENDONLY = TRUE,COMPRESSTYPE = ZSTD,COMPRESSLEVEL = 1,ORIENTATION = row,OIDS = false) DISTRIBUTED BY (id);
		CREATE TEMPORARY TABLE tt_test_normalize_agg_aa_fsort (LIKE test_historical_data) WITH (APPENDONLY = TRUE,COMPRESSTYPE = ZSTD,COMPRESSLEVEL = 1,ORIENTATION = row,OIDS = false) DISTRIBUTED BY (id);
		CREATE TEMPORARY TABLE tt_test_normalize_agg_aa_fsql (LIKE test_historical_data) WITH (APPENDONLY = TRUE,COMPRESSTYPE = ZSTD,COMPRESSLEVEL = 1,ORIENTATION = row,OIDS = false) DISTRIBUTED BY (id);
		CREATE TEMPORARY TABLE tt_test_normalize_agg_aa_cnosort (LIKE test_historical_data) WITH (APPENDONLY = TRUE,COMPRESSTYPE = ZSTD,COMPRESSLEVEL = 1,ORIENTATION = row,OIDS = false) DISTRIBUTED BY (id);
		CREATE TEMPORARY TABLE tt_test_normalize_agg_aa_csort (LIKE test_historical_data) WITH (APPENDONLY = TRUE,COMPRESSTYPE = ZSTD,COMPRESSLEVEL = 1,ORIENTATION = row,OIDS = false) DISTRIBUTED BY (id);
		CREATE TEMPORARY TABLE tt_test_normalize_agg_aa_csql (LIKE test_historical_data) WITH (APPENDONLY = TRUE,COMPRESSTYPE = ZSTD,COMPRESSLEVEL = 1,ORIENTATION = row,OIDS = false) DISTRIBUTED BY (id);
		CREATE TEMPORARY TABLE tt_test_normalize_agg_s (LIKE test_historical_data) WITH (APPENDONLY = TRUE,COMPRESSTYPE = ZSTD,COMPRESSLEVEL = 1,ORIENTATION = row,OIDS = false) DISTRIBUTED BY (id);
		CREATE TEMPORARY TABLE tt_test_normalize_agg_s_cnosort (LIKE test_historical_data) WITH (APPENDONLY = TRUE,COMPRESSTYPE = ZSTD,COMPRESSLEVEL = 1,ORIENTATION = row,OIDS = false) DISTRIBUTED BY (id);
		CREATE TEMPORARY TABLE tt_test_normalize_agg_s_csort (LIKE test_historical_data) WITH (APPENDONLY = TRUE,COMPRESSTYPE = ZSTD,COMPRESSLEVEL = 1,ORIENTATION = row,OIDS = false) DISTRIBUTED BY (id);
		CREATE TEMPORARY TABLE tt_test_normalize_agg_s_csql (LIKE test_historical_data) WITH (APPENDONLY = TRUE,COMPRESSTYPE = ZSTD,COMPRESSLEVEL = 1,ORIENTATION = row,OIDS = false) DISTRIBUTED BY (id);
     
      ts = CLOCK_TIMESTAMP();
  
      INSERT INTO tt_test_normalize_classic
      (id, val1, val2, val3, start_dt, end_dt)
      select 
          id, val1, val2, val3,
          t.start_dt,      
          t.end_dt
      from (
          select
              id, val1, val2, val3,
              t.start_dt,      
              max(t.end_dt) over (partition by id, val1, val2, val3, t.gr_flg) as end_dt,
              min(t.start_dt) over (partition by id, val1, val2, val3, t.gr_flg) as min_start_dt
          from (
              select
                  id, val1, val2, val3,
                  t.start_dt,
                  t.end_dt,
                  sum(t.eq_flg) over (partition by id, val1, val2, val3 order by t.start_dt rows unbounded preceding) as gr_flg
              from (
                  select
                      id, val1, val2, val3,
                      t.start_dt,
                      t.end_dt, 
                      case
                          when lag(t.end_dt, 1) over (partition by id, val1, val2, val3 order by t.start_dt) >= t.start_dt - 1 then 0
                          else 1
                      end as eq_flg 
                  from test_historical_data t
                  WHERE t.start_dt <= t.end_dt
              ) t
          ) t
      ) t
      where t.start_dt = t.min_start_dt;
     
      classic_time = CLOCK_TIMESTAMP() - ts;

      ts = CLOCK_TIMESTAMP();
  
      INSERT INTO tt_test_normalize_agg_aa_ac_fsort
      (id, val1, val2, val3, start_dt, end_dt)
      SELECT id, val1, val2, val3, lower(prd) AS start_dt, upper(prd)-1 AS end_dt
      FROM(  SELECT id, val1, val2, val3,
             	    UNNEST (normalize_agg_aa_ac_fsort(daterange(start_dt, end_dt,'[]'))) AS prd
	         FROM   test_historical_data AS t
	         WHERE  t.start_dt <= t.end_dt
	         GROUP  BY 1,2,3,4) t;
  
      normalize_agg_aa_ac_fsort_time = CLOCK_TIMESTAMP() - ts;
 
 
  	  ts = CLOCK_TIMESTAMP();
  
      INSERT INTO tt_test_normalize_agg_aa_ac_fsql
      (id, val1, val2, val3, start_dt, end_dt)
      SELECT id, val1, val2, val3, lower(prd) AS start_dt, upper(prd)-1 AS end_dt
      FROM(  SELECT id, val1, val2, val3,
             	    UNNEST (normalize_agg_aa_ac_fsql(daterange(start_dt, end_dt,'[]'))) AS prd
	         FROM   test_historical_data AS t
	         WHERE  t.start_dt <= t.end_dt
	         GROUP  BY 1,2,3,4) t;
  
      normalize_agg_aa_ac_fsql_time = CLOCK_TIMESTAMP() - ts;
     
      ts = CLOCK_TIMESTAMP();
  
      INSERT INTO tt_test_normalize_agg_aa_fsort
      (id, val1, val2, val3, start_dt, end_dt)
      SELECT id, val1, val2, val3, lower(prd) AS start_dt, upper(prd)-1 AS end_dt
      FROM(  SELECT id, val1, val2, val3,
             	    UNNEST (normalize_agg_aa_fsort(daterange(start_dt, end_dt,'[]'))) AS prd
	         FROM   test_historical_data AS t
	         WHERE  t.start_dt <= t.end_dt
	         GROUP  BY 1,2,3,4) t;
  
      normalize_agg_aa_fsort_time = CLOCK_TIMESTAMP() - ts;
     
      ts = CLOCK_TIMESTAMP();
  
      INSERT INTO tt_test_normalize_agg_aa_fsql
      (id, val1, val2, val3, start_dt, end_dt)
      SELECT id, val1, val2, val3, lower(prd) AS start_dt, upper(prd)-1 AS end_dt
      FROM(  SELECT id, val1, val2, val3,
             	    UNNEST (normalize_agg_aa_fsql(daterange(start_dt, end_dt,'[]'))) AS prd
	         FROM   test_historical_data AS t
	         WHERE  t.start_dt <= t.end_dt
	         GROUP  BY 1,2,3,4) t;
  
      normalize_agg_aa_fsql_time = CLOCK_TIMESTAMP() - ts;
     
      ts = CLOCK_TIMESTAMP();
  
      INSERT INTO tt_test_normalize_agg_aa_cnosort
      (id, val1, val2, val3, start_dt, end_dt)
      SELECT id, val1, val2, val3, lower(prd) AS start_dt, upper(prd)-1 AS end_dt
      FROM(  SELECT id, val1, val2, val3,
             	    UNNEST (normalize_agg_aa_cnosort(daterange(start_dt, end_dt,'[]'))) AS prd
	         FROM   test_historical_data AS t
	         WHERE  t.start_dt <= t.end_dt
	         GROUP  BY 1,2,3,4) t;
  
      normalize_agg_aa_cnosort_time = CLOCK_TIMESTAMP() - ts;
     
      ts = CLOCK_TIMESTAMP();
  
      INSERT INTO tt_test_normalize_agg_aa_csort
      (id, val1, val2, val3, start_dt, end_dt)
      SELECT id, val1, val2, val3, lower(prd) AS start_dt, upper(prd)-1 AS end_dt
      FROM(  SELECT id, val1, val2, val3,
             	    UNNEST (normalize_agg_aa_csort(daterange(start_dt, end_dt,'[]'))) AS prd
	         FROM   test_historical_data AS t
	         WHERE  t.start_dt <= t.end_dt
	         GROUP  BY 1,2,3,4) t;
  
      normalize_agg_aa_csort_time = CLOCK_TIMESTAMP() - ts;
     
     
      ts = CLOCK_TIMESTAMP();
  
      INSERT INTO tt_test_normalize_agg_aa_csql
      (id, val1, val2, val3, start_dt, end_dt)
      SELECT id, val1, val2, val3, lower(prd) AS start_dt, upper(prd)-1 AS end_dt
      FROM(  SELECT id, val1, val2, val3,
             	    UNNEST (normalize_agg_aa_csql(daterange(start_dt, end_dt,'[]'))) AS prd
	         FROM   test_historical_data AS t
	         WHERE  t.start_dt <= t.end_dt
	         GROUP  BY 1,2,3,4) t;
  
      normalize_agg_aa_csql_time = CLOCK_TIMESTAMP() - ts;
     
      ts = CLOCK_TIMESTAMP();
  
      INSERT INTO tt_test_normalize_agg_s
      (id, val1, val2, val3, start_dt, end_dt)
      SELECT id, val1, val2, val3, lower(prd) AS start_dt, upper(prd)-1 AS end_dt
      FROM(  SELECT id, val1, val2, val3,
             	    UNNEST (normalize_agg_s(daterange(start_dt, end_dt,'[]'))) AS prd
	         FROM   test_historical_data AS t
	         WHERE  t.start_dt <= t.end_dt
	         GROUP  BY 1,2,3,4) t;
  
      normalize_agg_s_time = CLOCK_TIMESTAMP() - ts;
     
      ts = CLOCK_TIMESTAMP();
  
      INSERT INTO tt_test_normalize_agg_s_cnosort
      (id, val1, val2, val3, start_dt, end_dt)
      SELECT id, val1, val2, val3, lower(prd) AS start_dt, upper(prd)-1 AS end_dt
      FROM(  SELECT id, val1, val2, val3,
             	    UNNEST (normalize_agg_s_cnosort(daterange(start_dt, end_dt,'[]'))) AS prd
	         FROM   test_historical_data AS t
	         WHERE  t.start_dt <= t.end_dt
	         GROUP  BY 1,2,3,4) t;
  
      normalize_agg_s_cnosort_time = CLOCK_TIMESTAMP() - ts;
     
      ts = CLOCK_TIMESTAMP();
  
      INSERT INTO tt_test_normalize_agg_s_csort
      (id, val1, val2, val3, start_dt, end_dt)
      SELECT id, val1, val2, val3, lower(prd) AS start_dt, upper(prd)-1 AS end_dt
      FROM(  SELECT id, val1, val2, val3,
             	    UNNEST (normalize_agg_s_csort(daterange(start_dt, end_dt,'[]'))) AS prd
	         FROM   test_historical_data AS t
	         WHERE  t.start_dt <= t.end_dt
	         GROUP  BY 1,2,3,4) t;
  
      normalize_agg_s_csort_time = CLOCK_TIMESTAMP() - ts;
     
      ts = CLOCK_TIMESTAMP();
  
      INSERT INTO tt_test_normalize_agg_s_csql
      (id, val1, val2, val3, start_dt, end_dt)
      SELECT id, val1, val2, val3, lower(prd) AS start_dt, upper(prd)-1 AS end_dt
      FROM(  SELECT id, val1, val2, val3,
             	    UNNEST (normalize_agg_s_csql(daterange(start_dt, end_dt,'[]'))) AS prd
	         FROM   test_historical_data AS t
	         WHERE  t.start_dt <= t.end_dt
	         GROUP  BY 1,2,3,4) t;
  
      normalize_agg_s_csql_time = CLOCK_TIMESTAMP() - ts;
  
      INSERT INTO tt_test_results
      (sTest, tTime)
      VALUES
     	('classic'					 ,classic_time					),
     	('normalize_agg_aa_ac_fsort' ,normalize_agg_aa_ac_fsort_time),
		('normalize_agg_aa_ac_fsql'  ,normalize_agg_aa_ac_fsql_time ),
		('normalize_agg_aa_fsort'    ,normalize_agg_aa_fsort_time   ),
		('normalize_agg_aa_fsql'     ,normalize_agg_aa_fsql_time    ),
		('normalize_agg_aa_cnosort'	 ,normalize_agg_aa_cnosort_time	),
		('normalize_agg_aa_csort'	 ,normalize_agg_aa_csort_time	),
		('normalize_agg_aa_csql'     ,normalize_agg_aa_csql_time    ),
		('normalize_agg_s'           ,normalize_agg_s_time          ),
		('normalize_agg_s_cnosort'   ,normalize_agg_s_cnosort_time  ),
		('normalize_agg_s_csort'     ,normalize_agg_s_csort_time    ),
		('normalize_agg_s_csql'      ,normalize_agg_s_csql_time     )
		;
  
   END LOOP;

END
$do$
;

SELECT
sTest,
to_char(avg(tTime), 'SS.MS') AS avg_time,
to_char(median(tTime), 'SS.MS') AS median_time
FROM tt_test_results
GROUP BY 1
ORDER BY 1,2;



/*
SELECT count (*) FROM tt_test_normalize_classic;
SELECT count (*) FROM tt_test_normalize_agg_aa_ac_fsort;
SELECT count (*) FROM tt_test_normalize_agg_aa_ac_fsql;
SELECT count (*) FROM tt_test_normalize_agg_aa_csql;
SELECT count (*) FROM tt_test_normalize_agg_aa_cnosort;
SELECT count (*) FROM tt_test_normalize_agg_aa_csort;
SELECT count (*) FROM tt_test_normalize_agg_aa_fsort;
SELECT count (*) FROM tt_test_normalize_agg_aa_fsql;
SELECT count (*) FROM tt_test_normalize_agg_s;
SELECT count (*) FROM tt_test_normalize_agg_s_cnosort;
SELECT count (*) FROM tt_test_normalize_agg_s_csort;
SELECT count (*) FROM tt_test_normalize_agg_s_csql;
*/




/*
5 run 800k rows
classic	00.945	00.971
normalize_agg_aa_ac_fsort	01.165	01.145
normalize_agg_aa_ac_fsql	01.454	01.442
normalize_agg_aa_csql	00.327	00.331
normalize_agg_aa_fsort	01.032	01.056
normalize_agg_aa_fsql	01.438	01.417
normalize_agg_s	01.338	01.383
normalize_agg_s_cnosort	01.378	01.471
normalize_agg_s_csort	01.336	01.379
normalize_agg_s_csql	01.520	01.552
*/


/*
10 run 1600k rows
classic	01.360	01.360
normalize_agg_aa_ac_fsort	01.430	01.430
normalize_agg_aa_ac_fsql	02.027	02.027
normalize_agg_aa_csql	00.852	00.852
normalize_agg_aa_fsort	01.832	01.832
normalize_agg_aa_fsql	01.983	01.983
normalize_agg_s	02.743	02.743
normalize_agg_s_cnosort	03.477	03.477
normalize_agg_s_csort	03.289	03.289
normalize_agg_s_csql	03.778	03.778*/
