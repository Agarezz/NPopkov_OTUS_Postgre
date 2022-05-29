# NPopkov_OTUS_Postgre
Репозиторий для ДЗ по курсу OTUS PostgreSQL
# Домашнее задание 9 - Виды и устройство репликации в PostgreSQL

Созданы 4 ВМ, везде установлен PostgreSQL 14  
1. 10.128.0.17  
2. 10.128.0.22  
3. 10.128.0.36  
4. 10.128.0.31  

### На 1 ВМ создаем таблицы test для записи, test2 для запросов на чтение
На ВМ1:  
``` sql
CREATE TABLE test1 (id int4);
CREATE TABLE test2 (id int4);
```  

### Создаем публикацию таблицы test
На ВМ1:  
``` sql
ALTER SYSTEM SET wal_level = logical;
```  
``` console
sudo pg_ctlcluster 14 main restart
```  
``` sql
CREATE PUBLICATION test1_pub FOR TABLE test1;
CREATE PUBLICATION test1_pub2 FOR TABLE test1;
CREATE USER repuser WITH SUPERUSER PASSWORD '12345';
```  

### На 2 ВМ создаем таблицы test2 для записи, test для запросов на чтение
На ВМ2:  
``` sql
CREATE TABLE test1 (id int4);
CREATE TABLE test2 (id int4);
```  

### Создаем публикацию таблицы test2
На ВМ2:  
``` sql
ALTER SYSTEM SET wal_level = logical;
```  
``` console
sudo pg_ctlcluster 14 main restart
```  
``` sql
CREATE PUBLICATION test2_pub FOR TABLE test2;
CREATE PUBLICATION test2_pub2 FOR TABLE test2;
CREATE USER repuser WITH SUPERUSER PASSWORD '12345';
```  

### подписываемся на публикацию таблицы test1 с ВМ №1, подписываемся на публикацию таблицы test2 с ВМ №2
На ВМ1: 
``` console
sudo nano /etc/postgresql/14/main/pg_hba.conf
```  
Добавляем:  
host	all		repuser	10.128.0.22/32		scram-sha-256  
host	all		repuser	10.128.0.36/32		scram-sha-256  

``` console
sudo nano /etc/postgresql/14/main/postgresql.conf
```  
Раскоменчиваем:  
listen_address = '*'  

``` sql
CREATE SUBSCRIPTION test2_sub
CONNECTION 'host=10.128.0.22 port=5432 user=repuser password=12345 dbname=postgres' 
PUBLICATION test2_pub WITH (copy_data = true);
```  

На ВМ2:  
``` console
sudo nano /etc/postgresql/14/main/pg_hba.conf
```  
Добавляем:  
host	all		repuser	10.128.0.17/32		scram-sha-256  
host	all		repuser	10.128.0.36/32		scram-sha-256  

``` console
sudo nano /etc/postgresql/14/main/postgresql.conf
```  
Раскоменчиваем:  
listen_address = '*'   

``` sql
CREATE SUBSCRIPTION test1_sub 
CONNECTION 'host=10.128.0.17 port=5432 user=repuser password=12345 dbname=postgres' 
PUBLICATION test1_pub WITH (copy_data = true);
```  

### 3 ВМ использовать как реплику для чтения и бэкапов (подписаться на таблицы из ВМ №1 и №2)
На ВМ3:  
``` console
sudo nano /etc/postgresql/14/main/pg_hba.conf
```  
Добавляем:  
host	replication		repuser	10.128.0.31/32		scram-sha-256  

``` console
sudo nano /etc/postgresql/14/main/postgresql.conf
```  
Добавляем:  
listen_address = '*' 
hot_standby = on
hot_standby_feedback = on

``` sql
ALTER SYSTEM SET wal_level = replica;
```  
``` console
sudo pg_ctlcluster 14 main restart
```  
``` sql
CREATE TABLE test1 (id int4);
CREATE TABLE test2 (id int4);
CREATE SUBSCRIPTION test1_sub2 
CONNECTION 'host=10.128.0.17 port=5432 user=repuser password=12345 dbname=postgres' 
PUBLICATION test1_pub2 WITH (copy_data = true);
CREATE SUBSCRIPTION test2_sub2
CONNECTION 'host=10.128.0.22 port=5432 user=repuser password=12345 dbname=postgres' 
PUBLICATION test2_pub2 WITH (copy_data = true);
CREATE USER repuser WITH SUPERUSER PASSWORD '12345';
```  

###Задание со звездочкой* реализовать горячее реплицирование для высокой доступности на 4ВМ. Источником должна выступать ВМ №3. Написать с какими проблемами столкнулись.
На ВМ4:  

``` console
sudo rm -rf /var/lib/postgresql/14/main
sudo -u postgres pg_basebackup -h 10.128.0.36 -u repuser -p 5432 -R -D /var/lib/postgresql/14/main
```  
``` console
sudo nano /etc/postgresql/14/main/postgresql.conf
```  
Добавляем:  
listen_address = '*' 

``` console
sudo pg_ctlcluster 14 main start
```  

Проверяем наличие репликации на ВМ3
``` sql
SELECT * FROM pg_stat_replication \gx
```  
>>-[ RECORD 1 ]----+------------------------------  
>>pid              | 12571  
>>usesysid         | 16395  
>>usename          | repuser  
>>application_name | 14/main  
>>client_addr      | 10.128.0.31  
>>client_hostname  |  
>>client_port      | 36742  
>>backend_start    | 2022-05-29 22:50:58.602584+00  
>>backend_xmin     |  
>>state            | streaming  
>>sent_lsn         | 0/3000060  
>>write_lsn        | 0/3000060  
>>flush_lsn        | 0/3000060  
>>replay_lsn       | 0/3000060  
>>write_lag        |  
>>flush_lag        |  
>>replay_lag       |  
>>sync_priority    | 0  
>>sync_state       | async  
>>reply_time       | 2022-05-29 22:52:08.809411+00  

Вставляем запись на ВМ1:
``` sql
INSERT INTO test1 VALUES(1);
```  

Проверяем на ВМ2,ВМ3,ВМ4
``` sql
SELECT * FROM test1;
```  
На всех ВМ одинаковый результат:
>> id  
>>----  
>>  1  
>>(1 row)  

Вставляем запись на ВМ2:
``` sql
INSERT INTO test2 VALUES(1);
```  

Проверяем на ВМ1,ВМ3,ВМ4
``` sql
SELECT * FROM test2;
```  
На всех ВМ одинаковый результат:
>> id  
>>----  
>>  1  
>>(1 row) 

