# Домашнее задание 6 - Работа с журналами
### Настройте выполнение контрольной точки раз в 30 секунд
``` sql
ALTER SYSTEM SET checkpoint_timeout = '30s';
\q
```
``` console
sudo pg_ctlcluster 13 main reload
```  
:white_check_mark:
### 10 минут c помощью утилиты pgbench подавайте нагрузку, измерьте, какой объем журнальных файлов был сгенерирован за это время
``` sql
SELECT pg_current_wal_insert_lsn();
\q
```
Запоминаем текущую позицию LSN  
0/CDACEE68  

```  console
sudo -u postgres pgbench -c 8 -P 60 -T 600 postgres
```

По окончании читаем новый LSN  

``` sql
SELECT pg_current_wal_lsn(), pg_current_wal_insert_lsn();
```

|pg_current_wal_lsn | pg_current_wal_insert_lsn|
|------------|--------------|
| 0/EA5D9578  | 0/EA5D9578|  

Весь буфер WAL записан на диск. Вычисляем разницу:  

``` sql
SELECT pg_size_pretty('0/EA5D9578'::pg_lsn - '0/CDACEE68'::pg_lsn);
```
459.04 мегабайт  
:white_check_mark:
### Оцените, какой объем приходится в среднем на одну контрольную точку

459.04/(600/30) = ~23МБ  
:white_check_mark:  
### Проверьте данные статистики: все ли контрольные точки выполнялись точно по расписанию

``` sql
SELECT * FROM pg_stat_bgwriter \gx
```

>-[ RECORD 1 ]---------+------------------------------  
>checkpoints_timed     | 311  
>checkpoints_req       | 0  
>checkpoint_write_time | 8832885  
>checkpoint_sync_time  | 1465  
>buffers_checkpoint    | 143021  
>buffers_clean         | 0  
>maxwritten_clean      | 0  
>buffers_backend       | 52841  
>buffers_backend_fsync | 0  
>buffers_alloc         | 52217  
>stats_reset           | 2022-04-01 20:35:48.097898+00  

checkpoints_req = 0 - все контрольные точки выполнились по расписанию  
:white_check_mark:
### Почему так произошло?

Не понял вопрос. Всё отработало штатно, видимо скорости SSD хватило.  

### Сравните tps в синхронном/асинхронном режиме утилитой pgbench

Синхронный режим включен по умолчанию, запускаем тест  
``` console
sudo -u postgres pgbench -c 8 -P 60 -T 600 postgres
```

>transaction type: <builtin: TPC-B (sort of)>  
>scaling factor: 1  
>query mode: simple  
>number of clients: 8  
>number of threads: 1  
>duration: 600 s  
>number of transactions actually processed: 355640  
>latency average = 13.493 ms  
>latency stddev = 15.117 ms  
>tps = 592.722139 (including connections establishing)  
>tps = 592.724062 (excluding connections establishing)  

``` sql
ALTER SYSTEM SET synchronous_commit = off;
```
``` console
sudo pg_ctlcluster 13 main reload
sudo -u postgres pgbench -c 8 -P 60 -T 600 postgres
```

>transaction type: <builtin: TPC-B (sort of)>  
>scaling factor: 1  
>query mode: simple  
>number of clients: 8  
>number of threads: 1  
>duration: 600 s  
>number of transactions actually processed: 2822628  
>latency average = 1.694 ms  
>latency stddev = 1.022 ms  
>tps = 4704.319029 (including connections establishing)  
>tps = 4704.335367 (excluding connections establishing)  

в 8 раз быстрее!  
:white_check_mark:  
### Объясните полученный результат

При синхронной записи WAL при коммите каждая транзакция ждет записи всех журнальных записей, относящихся к ней, на диск.
При асинхронной записи транзакциям не приходится ждать, поэтому возврат контроля во время commit происходит намного быстрее.

### Создайте новый кластер с включенной контрольной суммой страниц

Создал новый кластер
``` console
sudo pg_ctlcluster 14 main stop
sudo -u postgres /usr/lib/postgresql/14/bin/pg_checksums --enable -D "/var/lib/postgresql/14/main"
```
>Checksum operation completed  
>Files scanned:  931  
>Blocks scanned: 3216  
>pg_checksums: syncing data directory  
>pg_checksums: updating control file  
>Checksums enabled in cluster  

``` console
sudo pg_ctlcluster 14 main start
```
:white_check_mark:  
### Создайте таблицу, вставьте несколько значений
``` sql
CREATE TABLE test (id int);
INSERT INTO test SELECT g FROM generate_series(1,100) AS g(n);
SELECT pg_relation_filepath('test');
```  
файлы таблицы: base/13760/16384  
:white_check_mark:  
### Выключите кластер
``` console
sudo pg_ctlcluster 14 main stop
```
:white_check_mark:  
### Измените пару байт в таблице
``` console
sudo -u postgres dd if=/dev/zero of=/var/lib/postgresql/14/main/base/13760/16384 oflag=dsync conv=notrunc bs=1 count=8
```

>=notrunc bs=1 count=8  
>8+0 records in  
>8+0 records out  
>8 bytes copied, 0.00810796 s, 1.0 kB/s  
:white_check_mark:  
### Включите кластер и сделайте выборку из таблицы
``` console
sudo pg_ctlcluster 14 main start
sudo -u postgres psql
```
``` sql
select * from test;
```  
>WARNING:  page verification failed, calculated checksum 11466 but expected 58271  
>ERROR:  invalid page in block 0 of relation base/13760/16384  

### Что и почему произошло

Ошибка - контрольная сумма первой страницы таблицы (заголовка) не сошлась с сохраненным в базе значением  

### как проигнорировать ошибку и продолжить работу
``` sql
SET ignore_checksum_failure = on;
select * from test;
```  
:white_check_mark: