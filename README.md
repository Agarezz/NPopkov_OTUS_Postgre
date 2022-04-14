# Домашнее задание 8 - Нагрузочное тестирование и тюнинг PostgreSQL
### развернуть виртуальную машину любым удобным способом, поставить на неё PostgreSQL 14 из пакетов собираемых postgres.org

Готово. ВМ на яндекс клуад, 2 vCPU, 4 ГБ Ram, HDD. 

### настроить кластер PostgreSQL 14 на максимальную производительность не обращая внимание на возможные проблемы с надежностью в случае аварийной перезагрузки виртуальной машины
### нагрузить кластер через утилиту sysbench-tpcc или через утилиту pgbench
### написать какого значения tps удалось достичь, показать какие параметры в какие значения устанавливали и почему

Не сказано под какой характер нагрузки нужна настройка на макс производительность, буду исходить из OLTP.  
Для референса сначала трестируем на дефолтных настройках:  
``` console
sudo -u postgres pgbench -i
sudo -u postgres pgbench -c 20 -P 60 -T 1200 postgres
```  
>> transaction type: <builtin: TPC-B (sort of)>  
>> scaling factor: 1  
>> query mode: simple  
>> number of clients: 20  
>> number of threads: 1  
>> duration: 1200 s  
>> number of transactions actually processed: 709318  
>> latency average = 33.788 ms  
>> latency stddev = 28.892 ms  
>> initial connection time = 39.608 ms  
>> tps = 591.095492 (without initial connection time)  

Берем настройки под целевой ворклоад с PGTune  
``` console
sudo -u postgres psql
```  
``` sql
ALTER SYSTEM SET max_connections = 20;
ALTER SYSTEM SET shared_buffers = '1GB';
ALTER SYSTEM SET effective_cache_size = '3GB';
ALTER SYSTEM SET maintenance_work_mem = '256MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 4;
ALTER SYSTEM SET effective_io_concurrency = 2;
ALTER SYSTEM SET work_mem = '52428kB';
ALTER SYSTEM SET min_wal_size = '2GB';
ALTER SYSTEM SET max_wal_size = '8GB';
ALTER SYSTEM SET max_worker_processes = 2;
ALTER SYSTEM SET max_parallel_workers_per_gather = 1;
ALTER SYSTEM SET max_parallel_workers = 2;
ALTER SYSTEM SET max_parallel_maintenance_workers = 1;
\q
```  
``` console
sudo pg_ctlcluster 14 main restart
sudo -u postgres pgbench -c 20 -P 60 -T 600 postgres
```  

>> transaction type: <builtin: TPC-B (sort of)>  
>> scaling factor: 1  
>> query mode: simple  
>> number of clients: 20  
>> number of threads: 1  
>> duration: 600 s  
>> number of transactions actually processed: 364389  
>> latency average = 32.885 ms  
>> latency stddev = 28.200 ms  
>> initial connection time = 37.522 ms  
>> tps = 607.284101 (without initial connection time)  
Изменения незначительные...  

Выключаем синхронные коммиты  
``` sql
ALTER SYSTEM SET synchronous_commit = off;  
```  

Выключаем принудительный сброс кэша на диск  
``` sql
ALTER SYSTEM SET fsync='off';  
```  

Понижаем уровень логирования  
``` sql
ALTER SYSTEM SET wal_level = minimal;  
ALTER SYSTEM SET max_wal_senders = 0;  
```  

Отключаем запись полных страниц WAL  
``` sql
ALTER SYSTEM SET full_page_writes = off;  
```  

Отключаем фоновую запись буферов, чтобы буферы не писались только во время чекпоинтов  
``` sql
ALTER SYSTEM SET bgwriter_lru_maxpages = 0;  
```  

Отключаем архивацию WAL  
``` sql
ALTER SYSTEM SET archive_mode = off;  
```  

Повышаем shared_buffers до 40% ram  
``` sql
ALTER SYSTEM SET shared_buffers = '1638MB';
```  

work_mem - не трогаем, итак уже 50 МБ, pg_bench не дает тяжелой аналитической нагрузки, все запросы простые.  
maintenance_work_mem - такой нагрузки будет очень мало, только автовакуум, нет смысла повышать.  
effective_cache_size - уже достаточно большой (3/4 от общей оперативки), сложных запросов не ожидается, нет смысла повышать.
huge_pages - не получилось включить, сервер не стартует. Возможно, нужны какие-то доп настройки на уровне ОС.

``` console
sudo pg_ctlcluster 14 main restart
sudo -u postgres pgbench -c 20 -P 60 -T 600 postgres
```  

>> transaction type: <builtin: TPC-B (sort of)>  
>> scaling factor: 1  
>> query mode: simple  
>> number of clients: 20  
>> number of threads: 1  
>> duration: 600 s  
>> number of transactions actually processed: 1481687  
>> latency average = 8.033 ms  
>> latency stddev = 5.964 ms  
>> initial connection time = 40.731 ms  
>> tps = 2469.472542 (without initial connection time)  

Ускорились в 4 раза.  