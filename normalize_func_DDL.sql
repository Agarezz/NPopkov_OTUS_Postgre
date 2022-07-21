CREATE OR REPLACE FUNCTION normalize_sfunc(state_range_arr daterange[], new_range daterange)
   RETURNS daterange[]
   LANGUAGE PLPGSQL
   STABLE
   STRICT
AS
$body$
DECLARE
  i integer := 1;
  k integer;
  arr_len constant integer := array_length(state_range_arr,1);
BEGIN
   WHILE i <= arr_len
        AND LOWER(new_range) > UPPER(state_range_arr[i])
   LOOP
      i := i + 1;
   END LOOP;
  
   k := i;
   WHILE k <= arr_len
        AND UPPER(new_range) >= LOWER(state_range_arr[k])
   LOOP
      k := k + 1;
   END LOOP;
  
   RETURN state_range_arr[1:i-1] || ARRAY[daterange(LEAST(LOWER(new_range), LOWER(state_range_arr[i])), GREATEST(UPPER(new_range), UPPER(state_range_arr[k-1]))) ] || state_range_arr[k:arr_len];
END;
$body$;

create or replace function range_combinefunc_sort(arr1 daterange[], arr2 daterange[]) returns daterange[]
  language plpgsql
  STABLE
  strict
as
$body$
DECLARE
m daterange;
i int := 0;
res daterange[] := '{}';
BEGIN
   FOREACH m IN ARRAY ARRAY(SELECT UNNEST(arr1 || arr2) ORDER BY 1)
   LOOP
      IF res[i] @> m THEN NULL;
      ELSEIF
         m && res[i] OR m -|- res[i] THEN
         res[i] = res[i] + m;
      ELSE
         i = i + 1;
         res[i] = m;
      END IF;
   END LOOP;
   RETURN res;
end;
$body$;


CREATE OR REPLACE FUNCTION range_combinefunc_nosort(arr1 daterange[], arr2 daterange[]) returns daterange[]
  LANGUAGE plpgsql
  STABLE
  STRICT
AS
$body$
DECLARE
m daterange;
i int := 0;
k int := 0;
c int := 0;
arr1len int := array_length(arr1,1);
arr2len int := array_length(arr2,1);
res daterange[] := '{}';
BEGIN
   WHILE i <= arr1len - 1 OR k <= arr2len - 1
   LOOP
      IF arr1[i] <= arr2[k]
         OR arr2[k] IS NULL THEN
            IF res[c] IS NULL THEN res[c] = arr1[i];
            ELSEIF res[c] && arr1[i]
                  OR res[c] -|- arr1[i]
               THEN res[c] = res[c] + arr1[i];
            ELSE
               c = c + 1;
               res[c] = arr1[i];
            END IF;
            i = i + 1;
      ELSE
         IF res[c] IS NULL THEN res[c] = arr2[k];
         ELSEIF res[c] && arr2[k]
               OR res[c] -|- arr2[k]
            THEN res[c] = res[c] + arr2[k];
         ELSE
            c = c + 1;
            res[c] = arr2[k];
         END IF;
         k = k + 1;
      END IF;
   END LOOP;
   RETURN res;
END;
$body$;

create or replace function range_combinefunc_sql(arr1 daterange[], arr2 daterange[]) returns daterange[]
  language SQL
  STABLE
  strict
as
$body$
	SELECT ARRAY_AGG( daterange(t.start_dt,  t.end_dt,'[]'))
	FROM ( SELECT t.start_dt
			   ,  MAX(t.end_dt) OVER (PARTITION BY t.gr_flg) AS end_dt
			   ,  MIN(t.start_dt) OVER (PARTITION BY t.gr_flg) AS min_start_dt
		   FROM ( SELECT start_dt
		   			   , end_dt
					   , SUM(t.intersect_flg) OVER (ORDER BY start_dt ROWS UNBOUNDED PRECEDING) AS gr_flg
				  FROM ( SELECT  LOWER(prd) AS start_dt
				  				,UPPER(prd)-1 AS end_dt
				  				,CASE WHEN LAG(UPPER(prd), 1) OVER (ORDER BY LOWER(prd)) >= LOWER(prd) THEN 0
								 	ELSE 1
							    END AS intersect_flg
						 FROM UNNEST(arr1||arr2) t (prd)
						 WHERE LOWER(prd) < UPPER(prd)
						) t
				) t
		 ) t
	WHERE t.start_dt = t.min_start_dt;
$body$;

create or replace function range_finalfunc_sort(arr daterange[]) returns daterange[]
  language plpgsql
  STABLE
  strict
as
$body$
DECLARE
m daterange;
i int := 0;
res daterange[] := '{}';
BEGIN
   FOREACH m IN ARRAY ARRAY(SELECT UNNEST(arr) ORDER BY 1)
   LOOP
      IF res[i] @> m THEN NULL;
      ELSEIF
         m && res[i] OR m -|- res[i] THEN
         res[i] = res[i] + m;
      ELSE
         i = i + 1;
         res[i] = m;
      END IF;
   END LOOP;
   RETURN res;
END
$body$;


create or replace function range_finalfunc_sql(arr daterange[]) returns daterange[]
  language SQL
  STABLE
  strict
as
$body$
	SELECT ARRAY_AGG( daterange(t.start_dt,  t.end_dt,'[]'))
	FROM ( SELECT t.start_dt
			   ,  MAX(t.end_dt) OVER (PARTITION BY t.gr_flg) AS end_dt
			   ,  MIN(t.start_dt) OVER (PARTITION BY t.gr_flg) AS min_start_dt
		   FROM ( SELECT start_dt
		   			   , end_dt
					   , SUM(t.intersect_flg) OVER (ORDER BY start_dt ROWS UNBOUNDED PRECEDING) AS gr_flg
				  FROM ( SELECT   LOWER(prd) AS start_dt
				  				, UPPER(prd)-1 AS end_dt
				  				,CASE WHEN LAG(UPPER(prd), 1) OVER (ORDER BY prd) >= LOWER(prd) THEN 0
								 	ELSE 1
							    END AS intersect_flg
						 FROM UNNEST(arr) t (prd)
						 WHERE LOWER(prd) IS NOT NULL
						 	   AND UPPER(prd) IS NOT NULL
						) t
				) t
		 ) t
	WHERE t.start_dt = t.min_start_dt;
$body$;


DROP AGGREGATE IF EXISTS normalize_agg_s(daterange);
CREATE AGGREGATE normalize_agg_s(daterange)
(
    sfunc = normalize_sfunc,
    stype = daterange[],
    initcond = '{}'
);

DROP AGGREGATE IF EXISTS normalize_agg_s_csort(daterange);
CREATE AGGREGATE normalize_agg_s_csort(daterange)
(
    sfunc = normalize_sfunc,
    combinefunc = range_combinefunc_sort,
    stype = daterange[],
    initcond = '{}'
);

DROP AGGREGATE IF EXISTS normalize_agg_s_cnosort(daterange);
CREATE AGGREGATE normalize_agg_s_cnosort(daterange)
(
    sfunc = normalize_sfunc,
    combinefunc = range_combinefunc_nosort,
    stype = daterange[],
    initcond = '{}'
);
	
DROP AGGREGATE IF EXISTS normalize_agg_s_csql(daterange);
CREATE AGGREGATE normalize_agg_s_csql(daterange)
(
    sfunc = normalize_sfunc,
    combinefunc = range_combinefunc_sql,
    stype = daterange[],
    initcond = '{}'
);

DROP AGGREGATE IF EXISTS normalize_agg_aa_csort(daterange);
CREATE AGGREGATE normalize_agg_aa_csort(daterange)
(
    sfunc = array_append,
    combinefunc = range_combinefunc_sort,
    stype = daterange[],
    initcond = '{}'
);

DROP AGGREGATE IF EXISTS normalize_agg_aa_cnosort(daterange);
CREATE AGGREGATE normalize_agg_aa_cnosort(daterange)
(
    sfunc = array_append,
    combinefunc = range_combinefunc_nosort,
    stype = daterange[],
    initcond = '{}'
);

DROP AGGREGATE IF EXISTS normalize_agg_aa_csql(daterange);
CREATE AGGREGATE normalize_agg_aa_csql(daterange)
(
    sfunc = array_append,
    combinefunc = range_combinefunc_sql,
    stype = daterange[],
    initcond = '{}'
);
	
DROP AGGREGATE IF EXISTS normalize_agg_aa_ac_fsort(daterange);
CREATE AGGREGATE normalize_agg_aa_ac_fsort(daterange)
(
    sfunc = array_append,
    combinefunc = array_cat,
    finalfunc = range_finalfunc_sort,
    stype = daterange[],
    initcond = '{}'
);

DROP AGGREGATE IF EXISTS normalize_agg_aa_fsort(daterange);
CREATE AGGREGATE normalize_agg_aa_fsort(daterange)
(
    sfunc = array_append,   
    finalfunc = range_finalfunc_sort,
   stype = daterange[],
    initcond = '{}'
);

DROP AGGREGATE IF EXISTS normalize_agg_aa_ac_fsql(daterange);
CREATE AGGREGATE normalize_agg_aa_ac_fsql(daterange)
(
    sfunc = array_append,
    combinefunc = array_cat,
    finalfunc = range_finalfunc_sql,
    stype = daterange[],
    initcond = '{}'
);

DROP AGGREGATE IF EXISTS normalize_agg_aa_fsql(daterange);
CREATE AGGREGATE normalize_agg_aa_fsql(daterange)
(
    sfunc = array_append,   
    finalfunc = range_finalfunc_sql,
    stype = daterange[],
    initcond = '{}'
);


 