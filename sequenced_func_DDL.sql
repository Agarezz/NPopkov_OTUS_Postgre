create or replace function range_dissect_sfunc(state_range_arr daterange[], new_range daterange) returns daterange[]
  language plpgsql
  STABLE
  strict
as
$body$
declare
  i integer := 1;
  k integer;                        
  arr_len integer := array_length(state_range_arr,1);
  dissected_ranges_arr daterange[];
BEGIN
   IF arr_len IS NULL THEN RETURN ARRAY[new_range]; END IF;

   WHILE i <= arr_len and lower(new_range) >= upper(state_range_arr[i])
   LOOP
      i := i + 1;
   END LOOP;

   IF lower(state_range_arr[i]) >= upper(new_range)
      OR state_range_arr[i] IS NULL
      OR arr_len IS NULL
      THEN RETURN state_range_arr[1:i-1] || new_range || state_range_arr[i:arr_len];
   END IF;
  
   IF state_range_arr[i] = new_range
      THEN RETURN state_range_arr;
   END IF;

   IF lower(new_range) <> lower(state_range_arr[i]) THEN
      dissected_ranges_arr = ARRAY[daterange(LEAST(lower(new_range),lower(state_range_arr[i]))
                                    ,GREATEST(lower(new_range),lower(state_range_arr[i])))];
   END IF;
  
   dissected_ranges_arr = dissected_ranges_arr
                     || daterange(GREATEST(lower(new_range),lower(state_range_arr[i]))
                              ,upper(state_range_arr[i]));

   k := i;
   WHILE k <= arr_len and upper(new_range) > lower(state_range_arr[k+1])
   LOOP
      IF upper(state_range_arr[k]) < lower(state_range_arr[k+1])
         THEN dissected_ranges_arr = dissected_ranges_arr
                              || daterange(upper(state_range_arr[k]), lower(state_range_arr[k+1]));
      END IF;
     
      dissected_ranges_arr = dissected_ranges_arr
                        || state_range_arr[k+1]; 
      k := k + 1;
   end loop;

   IF upper(new_range) < upper(state_range_arr[k])
      THEN dissected_ranges_arr = dissected_ranges_arr
                           || daterange(lower(state_range_arr[k]),upper(new_range));

   END IF;
  
   IF upper(new_range) <>  upper(state_range_arr[k])
      THEN dissected_ranges_arr = dissected_ranges_arr
                           || daterange(LEAST(upper(new_range),upper(state_range_arr[k]))
                                    ,GREATEST(upper(new_range), upper(state_range_arr[k])));
   END IF;
                    
   RETURN state_range_arr[1:i-1] || dissected_ranges_arr || state_range_arr[k+1:arr_len];
end;
$body$;

DROP AGGREGATE IF EXISTS range_dissect(daterange);
CREATE AGGREGATE range_dissect(daterange)
(
    sfunc = s_grnplm_ld_fin_mis3_lab02d_cib.fn_lcc2_range_dissect_sfunc,
    stype = daterange[],
    initcond = '{}',
    parallel = safe
);

create or replace function range_dissect_finalfunc(arr daterange[]) returns daterange[]
  language plpgsql
  STABLE
  strict
as
$body$
BEGIN
   RETURN (WITH CTE AS
         (SELECT prd
          FROM   UNNEST(arr) t (prd))
         SELECT array_agg(prd)
         FROM   (SELECT daterange(start_dt, LEAD(start_dt) OVER (ORDER by start_dt)) prd
               FROM   (SELECT lower(prd) AS start_dt
                     FROM   CTE
                     UNION
                     SELECT upper(prd) AS end_dt
                     FROM   CTE)sub
               ) sub
               WHERE upper(prd) IS NOT null
         );
END
$body$;

CREATE AGGREGATE range_dissect_3ff(daterange)
(
    sfunc = array_append,
    combinefunc = array_cat,
    finalfunc = range_dissect_finalfunc,
    stype = daterange[],
    initcond = '{}',
    parallel = safe
);