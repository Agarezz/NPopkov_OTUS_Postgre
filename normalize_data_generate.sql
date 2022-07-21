DROP TABLE IF EXISTS test_historical_data;
CREATE UNLOGGED TABLE test_historical_data
(
	id int4 NOT NULL,
	val1 int8,
	val2 int8,
	val3 int8,
	start_dt DATE NOT NULL,
	end_dt DATE NOT NULL
)
WITH (
	APPENDONLY = TRUE,
	COMPRESSTYPE = ZSTD,
	COMPRESSLEVEL = 1,
	ORIENTATION = row,
	OIDS = false
)
DISTRIBUTED BY (id);

DO $$
BEGIN
   FOR i IN 1 .. 4000 LOOP
   INSERT INTO test_historical_data
   (id, val1, val2, val3, start_dt, end_dt)
   SELECT
      i AS id,
      round((3)*random())::int8 AS val1,
      99999999999 AS val2,
      99999999999 AS val3,
      d::date AS start_dt,
      (LEAD(d::date, 1, DATE '2022-07-02') OVER (ORDER BY d::date ) - '1 day'::INTERVAL)::date AS end_dt
   FROM generate_series(DATE '2022-01-01', DATE '2022-06-30', '1 day'::INTERVAL*CEIL(5*random())) AS t(d);
   END LOOP;
END $$;

DO $$
BEGIN
   FOR i IN 4001 .. 6000 LOOP
   INSERT INTO test_historical_data
   (id, val1, val2, val3, start_dt, end_dt)
   SELECT
      i AS id,
      round((3)*random())::int8 AS val1,
      99999999999 AS val2,
      99999999999 AS val3,
      d::date AS start_dt,
      (LEAD(d::date, 1, DATE '2022-07-02') OVER (ORDER BY d::date ) - '1 day'::INTERVAL)::date AS end_dt
   FROM generate_series(DATE '2022-01-01', DATE '2022-06-30', '1 day'::INTERVAL*CEIL(3*random())) AS t(d);
   END LOOP;
END $$;

DO $$
BEGIN
   FOR i IN 6001 .. 10000 LOOP
   INSERT INTO test_historical_data
   (id, val1, val2, val3, start_dt, end_dt)
   SELECT
      i AS id,
      round((3)*random())::int8 AS val1,
      99999999999 AS val2,
      99999999999 AS val3,
      d::date AS start_dt,
      (LEAD(d::date, 1, DATE '2022-07-02') OVER (ORDER BY d::date ) - '1 day'::INTERVAL)::date AS end_dt
   FROM generate_series(DATE '2022-01-01', DATE '2022-06-30', '1 day'::INTERVAL*CEIL(10*random())) AS t(d);
   END LOOP;
END $$;

DO $$
BEGIN
   FOR i IN 10001 .. 13000 LOOP
   INSERT INTO test_historical_data
   (id, val1, val2, val3, start_dt, end_dt)
   SELECT
      i AS id,
      round((1)*random())::int8 AS val1,
      99999999999 AS val2,
      99999999999 AS val3,
      d::date AS start_dt,
      (LEAD(d::date, 1, DATE '2022-07-02') OVER (ORDER BY d::date ) - '1 day'::INTERVAL)::date AS end_dt
   FROM generate_series(DATE '2022-01-01', DATE '2022-06-30', '1 day'::INTERVAL*CEIL(5*random())) AS t(d);
   END LOOP;
END $$;

DO $$
BEGIN
   FOR i IN 13001 .. 16000 LOOP
   INSERT INTO test_historical_data
   (id, val1, val2, val3, start_dt, end_dt)
   SELECT
      i AS id,
      round((1)*random())::int8 AS val1,
      99999999999 AS val2,
      99999999999 AS val3,
      d::date AS start_dt,
      (LEAD(d::date, 1, DATE '2022-07-02') OVER (ORDER BY d::date ) - '1 day'::INTERVAL)::date AS end_dt
   FROM generate_series(DATE '2022-01-01', DATE '2022-06-30', '1 day'::INTERVAL*CEIL(3*random())) AS t(d);
   END LOOP;
END $$;

DO $$
BEGIN
   FOR i IN 16001 .. 20000 LOOP
   INSERT INTO test_historical_data
   (id, val1, val2, val3, start_dt, end_dt)
   SELECT
      i AS id,
      999 AS val1,
      99999999999 AS val2,
      99999999999 AS val3,
      d::date AS start_dt,
      (LEAD(d::date, 1, DATE '2022-07-02') OVER (ORDER BY d::date ) - '1 day'::INTERVAL)::date AS end_dt
   FROM generate_series(DATE '2022-01-01', DATE '2022-06-30', '1 day'::INTERVAL*CEIL(5*random())) AS t(d);
   END LOOP;
END $$;

ANALYZE test_historical_data;

SELECT count(*) FROM test_historical_data;

--1677278

TABLE test_historical_data limit 100;