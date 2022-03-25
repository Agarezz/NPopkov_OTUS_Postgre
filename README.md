# Домашнее задание 4 - Логический уровень PostgreSQL 
>создайте новый кластер PostgresSQL 13 (на выбор - GCE, CloudSQL)

:white_check_mark: Сделан ВМ в Yandex Cloud с Ubuntu 20.04

>зайдите в созданный кластер под пользователем postgres

```sudo -u postgres psql```
:white_check_mark:

>создайте новую базу данных testdb

```CREATE DATABASE testdb;```
:white_check_mark:

>зайдите в созданную базу данных под пользователем postgres

```\c testdb```
:white_check_mark:

>создайте новую схему testnm

```CREATE SCHEMA testnm;```
:white_check_mark:

>создайте новую таблицу t1 с одной колонкой c1 типа integer

```CREATE TABLE t1 (c1 int4);```
:white_check_mark:

>вставьте строку со значением c1=1

```INSERT INTO t1 VALUES (1);```
:white_check_mark:

>создайте новую роль readonly

```CREATE ROLE readonly;```
:white_check_mark:

>дайте новой роли право на подключение к базе данных testdb

```GRANT CONNECT ON DATABASE testdb TO readonly;```
:white_check_mark:

>дайте новой роли право на использование схемы testnm

```GRANT USAGE ON SCHEMA testnm TO GROUP readonly;```
:white_check_mark:

>дайте новой роли право на select для всех таблиц схемы testnm

```
GRANT SELECT ON ALL TABLES IN SCHEMA testnm TO GROUP readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA testnm GRANT SELECT ON TABLES TO readonly;
```
:white_check_mark:

>создайте пользователя testread с паролем test123

```CREATE USER testread WITH PASSWORD 'test123';```
:white_check_mark:

>дайте роль readonly пользователю testread

```GRANT readonly TO testread;```
:white_check_mark:

>зайдите под пользователем testread в базу данных testdb

```sudo psql -U testread -d testdb -h 127.0.0.1 -W```
:white_check_mark:

>сделайте select * from t1;

ERROR:  permission denied for table t1
:negative_squared_cross_mark:

>получилось? (могло если вы делали сами не по шпаргалке и не упустили один существенный момент про который позже)

Нет

>напишите что именно произошло в тексте домашнего задания

Ошибка ERROR:  permission denied for table t1

>у вас есть идеи почему? ведь права то дали?

Я создал таблицу t1 без указания схемы - она создалась в схеме public по search_path (схемы "user" не существует), это можно посмотреть с помощью \dt. А на эту схему у юзера прав нет.

\dt t1
|Schema | Name | Type  |  Owner |
|-----:|:-----:|:-----:|:-----|
|public | t1   | table | postgres|

>посмотрите на список таблиц
>подсказка в шпаргалке под пунктом 20
>а почему так получилось с таблицей (если делали сами и без шпаргалки то может у вас все нормально)

см выше

>вернитесь в базу данных testdb под пользователем postgres

```
\q
sudo -u postgres psql
\c testdb
```
:white_check_mark:

>удалите таблицу t1

`DROP TABLE t1;`
:white_check_mark:

>создайте ее заново но уже с явным указанием имени схемы testnm

```CREATE TABLE testnm.t1 (c1 int4);```
:white_check_mark:

>вставьте строку со значением c1=1

```INSERT INTO testnm.t1 VALUES (1);```
:white_check_mark:

>зайдите под пользователем testread в базу данных testdb

```
\q
sudo psql -U testread -d testdb -h 127.0.0.1 -W
```
:white_check_mark:

>сделайте select * from testnm.t1;

`select * from testnm.t1;`
:white_check_mark:

>получилось?

Да

>есть идеи почему? если нет - смотрите шпаргалку

Потому, что теперь таблица находится в схеме, к которой у юзера есть права на селект.

>как сделать так чтобы такое больше не повторялось? если нет идей - смотрите шпаргалку

Сначала не понял о чем речь)
Посмотрел шпаргалку - я изначально сделал `ALTER default privileges in SCHEMA testnm grant SELECT on TABLEs to readonly;`, см выше, поэтому таких проблем у меня не было.
:white_check_mark:

>сделайте select * from testnm.t1;
>получилось?
>есть идеи почему? если нет - смотрите шпаргалку
>сделайте select * from testnm.t1;
>получилось?

Всё получилось, т.к. см выше

>ура!
>теперь попробуйте выполнить команду

```
create table t2(c1 integer);
insert into t2 values (2);
```
:white_check_mark:

>а как так? нам же никто прав на создание таблиц и insert в них под ролью readonly?

Потому, что мы снова создали таблицу без схемы - в public

>есть идеи как убрать эти права? если нет - смотрите шпаргалку

Нужно отобрать права у паблика

```
\q
sudo -u postgres psql
REVOKE CREATE ON SCHEMA PUBLIC FROM public;
REVOKE ALL ON DATABASE testdb FROM public;
ALTER DEFAULT PRIVILEGES REVOKE ALL ON TABLE FROM public;
ALTER DEFAULT PRIVILEGES REVOKE ALL ON SCHEMAS FROM public;
```
:white_check_mark:

>если вы справились сами то расскажите что сделали и почему, если смотрели шпаргалку - объясните что сделали и почему выполнив указанные в ней команды

`ALTER default privileges in SCHEMA testnm grant SELECT on TABLEs to readonly;` написал сам, погуглив как выдавать права на схемы.
По удалению прав на паблик посмотрел шпаргалку, последнюю строчку погуглил.
`REVOKE CREATE ON SCHEMA public FROM public;` - отбирает права на создание объектов у роли public на схему public
`REVOKE ALL ON DATABASE testdb FROM public;` - отбирает все права на объекты БД у роли public
`ALTER DEFAULT PRIVILEGES REVOKE ALL ON TABLE FROM public; ALTER DEFAULT PRIVILEGES REVOKE ALL ON SCHEMAS FROM public;` - права по умолчанию не будут выдаваться на объекты в будущем

>теперь попробуйте выполнить команду create table t3(c1 integer); insert into t2 values (2);

Получилось
:white_check_mark:

>расскажите что получилось и почему 

Я сделал это под postgres, у него superuser - права не проверяются
