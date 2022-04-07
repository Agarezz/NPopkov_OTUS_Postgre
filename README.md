# Домашнее задание 7 - Блокировки
### Настройте сервер так, чтобы в журнал сообщений сбрасывалась информация о блокировках, удерживаемых более 200 миллисекунд  
``` sql
ALTER SYSTEM SET log_lock_waits = on;
ALTER SYSTEM SET deadlock_timeout = 200;
SELECT pg_reload_conf();
```  
### Воспроизведите ситуацию, при которой в журнале появятся такие сообщения  

Первая сессия  
``` sql
CREATE TABLE test1 (id int, val int);
INSERT INTO test1 VALUES(0,1),(1,2);
\set AUTOCOMMIT off
BEGIN;
UPDATE test1 SET val = val + 1 WHERE id = 0;
```

Вторая сессия  
``` sql
\set AUTOCOMMIT off
BEGIN;
UPDATE test1 SET val = val - 1 WHERE id = 0;
```

Третья сессия
``` console
sudo tail -n 10 /var/log/postgresql/postgresql-14-main.log
```
> 2022-04-07 12:44:29.598 UTC [7316] postgres@postgres LOG:  process 7316 still waiting for ShareLock on transaction 739 after 200.156 ms  
> 2022-04-07 12:44:29.598 UTC [7316] postgres@postgres DETAIL:  Process holding the lock: 7193. Wait queue: 7316.  
> 2022-04-07 12:44:29.598 UTC [7316] postgres@postgres CONTEXT:  while updating tuple (0,1) in relation "test1"  
> 2022-04-07 12:44:29.598 UTC [7316] postgres@postgres STATEMENT:  UPDATE test1 SET val = val - 1 WHERE id = 0;  

Потом commit в обеих сессиях, чтобы отпустить блокировку  

### Смоделируйте ситуацию обновления одной и той же строки тремя командами UPDATE в разных сеансах  

Первая сессия  
``` sql
BEGIN;
SELECT txid_current(), pg_backend_pid();
UPDATE test1 SET val = val + 1 WHERE id = 0;
```  
>747, 7193  

Вторая сессия  
``` sql
BEGIN;
SELECT txid_current(), pg_backend_pid();
UPDATE test1 SET val = val + 1 WHERE id = 0;
```  
>748, 7316

Третья сессия  
``` sql
\set AUTOCOMMIT off
BEGIN;
SELECT txid_current(), pg_backend_pid();
UPDATE test1 SET val = val + 1 WHERE id = 0;
```  
>749, 7468   

### Изучите возникшие блокировки в представлении pg_locks и убедитесь, что все они понятны. Пришлите список блокировок и объясните, что значит каждая  
Четвертая сессия  
``` sql
SELECT pid,
       locktype,
       CASE locktype
         WHEN 'relation' THEN relation::regclass::text
         WHEN 'transactionid' THEN transactionid::text
         WHEN 'tuple' THEN relation::regclass::text||':'||tuple::text
       END AS lockid,
       mode,
       granted
FROM pg_locks
WHERE locktype in ('relation','transactionid','tuple')
AND (locktype != 'relation' OR relation = 'test1'::regclass);
```  
| pid  |   locktype    |  lockid  |       mode       | granted| Коммент |
|-----:|:-------------:|:--------:|:----------------:|:------:|:--------|
| 7468 | relation      | test1    | RowExclusiveLock | t      |Блокировка обновляемой строки транзакцией 3|
| 7316 | relation      | test1    | RowExclusiveLock | t      |Блокировка обновляемой строки транзакцией 2|
| 7193 | relation      | test1    | RowExclusiveLock | t      |Блокировка обновляемой строки транзакцией 1|
| 7468 | transactionid | 749      | ExclusiveLock    | t      |Транзакция 3 блокирует свой transactionid на время изменений (чтобы другие транзакции могли на эту блокировку ссылаться, если хотят изменить заблокированные ей строки)|
| 7316 | transactionid | 747      | ShareLock        | f      |Транзакция 2 пытается сделать share блокировку на транзакцию 1, так как ей нужна строка, которую заблокировала транзакция 1. По сути - транзакция 2 показывает, что ждет транзакцию 1.|
| 7316 | tuple         | test1:28 | ExclusiveLock    | t      |Транзакция 2 блокирует очередь блокировок test1:28 (granted = t), на изменения в таблице test1|
| 7316 | transactionid | 748      | ExclusiveLock    | t      |Транзакция 2 блокирует свой transactionid на время изменений|
| 7468 | tuple         | test1:28 | ExclusiveLock    | f      |Транзакция 3 стоит в очереди блокировок test1:28 (granted = f)|
| 7193 | transactionid | 747      | ExclusiveLock    | t      |Транзакция 1 блокирует свой transactionid на время изменений|  

Последовательность не выполняется потому что:
1. Транзакция 1 взяла блокировку на строку и на свой transactionid
2. Транзакция 2 взяла блокировку на строку и, увидев, что строка уже занята транзакцией 1, запросила ShareLock на transactionid транзакции 1 и ждет.
3. В момент прихода транзакции 3 была образована очередь 28, и транзакция 2 взяла блокировку на неё.
3. Транзакция 3 запросила блокировку на очередь 28 и ждет.

commit во всех сессиях, чтобы отпустить блокировки

### Воспроизведите взаимоблокировку трех транзакций

Подготовка:  
``` sql
DELETE FROM test1;
INSERT INTO test1 VALUES(0,1),(1,1),(2,1);
```  

Первая сессия  
``` sql
BEGIN;
SELECT txid_current(), pg_backend_pid();
UPDATE test1 SET val = val + 1 WHERE id = 0;
```  
757, 7926  

Вторая сессия 
``` sql
BEGIN;
SELECT txid_current(), pg_backend_pid();
UPDATE test1 SET val = val + 1 WHERE id = 1;
```  
758, 7316  

Третья сессия  
``` sql
BEGIN;
SELECT txid_current(), pg_backend_pid();
UPDATE test1 SET val = val + 1 WHERE id = 2;
```  
759, 7468  

Снова первая сессия, блокируемся со второй
``` sql
UPDATE test1 SET val = val + 1 WHERE id = 1;
```  

Вторая сессия, блокируемся с третьей  
``` sql
UPDATE test1 SET val = val + 1 WHERE id = 2;
```  

Третья сессия, блокируемся с первой, замыкаем круг  
``` sql
UPDATE test1 SET val = val + 1 WHERE id = 0;
```  

> ERROR:  deadlock detected  
> DETAIL:  Process 7468 waits for ShareLock on transaction 757; blocked by process 7926.  
> Process 7926 waits for ShareLock on transaction 758; blocked by process 7316.  
> Process 7316 waits for ShareLock on transaction 759; blocked by process 7468.  
> HINT:  See server log for query details.  
> CONTEXT:  while updating tuple (0,33) in relation "test1"  

### Можно ли разобраться в ситуации постфактум, изучая журнал сообщений?  
В принципе, да:  
``` console
sudo tail -n 30 /var/log/postgresql/postgresql-14-main.log
```

> 2022-04-07 14:43:24.410 UTC [7926] postgres@postgres LOG:  process 7926 still waiting for ShareLock on transaction 758 after 200.142 ms  
> 2022-04-07 14:43:24.410 UTC [7926] postgres@postgres DETAIL:  Process holding the lock: 7316. Wait queue: 7926.  
> 2022-04-07 14:43:24.410 UTC [7926] postgres@postgres CONTEXT:  while updating tuple (0,34) in relation "test1"  
> 2022-04-07 14:43:24.410 UTC [7926] postgres@postgres STATEMENT:  UPDATE test1 SET val = val + 1 WHERE id = 1;  
> 2022-04-07 14:43:30.346 UTC [7316] postgres@postgres LOG:  process 7316 still waiting for ShareLock on transaction 759 after 200.134 ms  
> 2022-04-07 14:43:30.346 UTC [7316] postgres@postgres DETAIL:  Process holding the lock: 7468. Wait queue: 7316.  
> 2022-04-07 14:43:30.346 UTC [7316] postgres@postgres CONTEXT:  while updating tuple (0,35) in relation "test1"  
> 2022-04-07 14:43:30.346 UTC [7316] postgres@postgres STATEMENT:  UPDATE test1 SET val = val + 1 WHERE id = 2;  
> 2022-04-07 14:43:35.099 UTC [7468] postgres@postgres LOG:  process 7468 detected deadlock while waiting for ShareLock on transaction 757 after 200.195 ms  
> 2022-04-07 14:43:35.099 UTC [7468] postgres@postgres DETAIL:  Process holding the lock: 7926. Wait queue: .  
> 2022-04-07 14:43:35.099 UTC [7468] postgres@postgres CONTEXT:  while updating tuple (0,33) in relation "test1"  
> 2022-04-07 14:43:35.099 UTC [7468] postgres@postgres STATEMENT:  UPDATE test1 SET val = val + 1 WHERE id = 0;  
> 2022-04-07 14:43:35.099 UTC [7468] postgres@postgres ERROR:  deadlock detected  
> 2022-04-07 14:43:35.099 UTC [7468] postgres@postgres DETAIL:  Process 7468 waits for ShareLock on transaction 757; blocked by process 7926.  
>         Process 7926 waits for ShareLock on transaction 758; blocked by process 7316.  
>         Process 7316 waits for ShareLock on transaction 759; blocked by process 7468.  
>         Process 7468: UPDATE test1 SET val = val + 1 WHERE id = 0;  
>         Process 7926: UPDATE test1 SET val = val + 1 WHERE id = 1;  
>         Process 7316: UPDATE test1 SET val = val + 1 WHERE id = 2;  
> 2022-04-07 14:43:35.099 UTC [7468] postgres@postgres HINT:  See server log for query details.  
> 2022-04-07 14:43:35.099 UTC [7468] postgres@postgres CONTEXT:  while updating tuple (0,33) in relation "test1"  
> 2022-04-07 14:43:35.099 UTC [7468] postgres@postgres STATEMENT:  UPDATE test1 SET val = val + 1 WHERE id = 0;  
> 2022-04-07 14:43:35.099 UTC [7316] postgres@postgres LOG:  process 7316 acquired ShareLock on transaction 759 after 4952.602 ms  
> 2022-04-07 14:43:35.099 UTC [7316] postgres@postgres CONTEXT:  while updating tuple (0,35) in relation "test1"  
> 2022-04-07 14:43:35.099 UTC [7316] postgres@postgres STATEMENT:  UPDATE test1 SET val = val + 1 WHERE id = 2;  

В блоке сообщений после "deadlock detected" есть все айдишники процессов и видно, что это закольцованная блокировка:  
> Process 7468 waits for ShareLock on transaction 757; blocked by process 7926.  
> Process 7926 waits for ShareLock on transaction 758; blocked by process 7316.  
> Process 7316 waits for ShareLock on transaction 759; blocked by process 7468.  
И запросы тоже приведены  

### Могут ли две транзакции, выполняющие единственную команду UPDATE одной и той же таблицы (без where), заблокировать друг друга?  
Могут, так как блокировки на строки накладываются не сразу заранее, а постепенно, по мере обновления строк. Если порядок обновления строк у двух транзакций будет отличаться, они могут войти в дедлок.  

### Попробуйте воспроизвести такую ситуацию  

Сделаем в таблице побольше строк с разными значениями  
``` sql
DELETE FROM test1;
INSERT INTO test1 VALUES(0,1),(1,2),(2,3),(3,4),(4,5),(5,6),(6,7);
```  

Создадим индекс с сортировкой по убыванию - в противоположность тому, как вставляли  
``` sql
CREATE INDEX ON test1(val DESC);
```  

Создадим функцию, которая будет обновлять стоки очень медленно  
``` sql
CREATE FUNCTION inc_slow(n numeric) RETURNS numeric AS $$
  SELECT pg_sleep(1);
  SELECT n + 100.00;
```  

Первая сессия. Запустим обновление c применением функции в порядке по умолчанию:  
``` sql
UPDATE test1 SET val = inc_slow(val);
```  
Вторая сессия. Отключим фуллсканы и добавим условие по индексированной колонке, чтобы вынудить оптимизатор использовать ранее созданный индекс и также запустим обновление:  
``` sql
SET enable_seqscan = off;
UPDATE test1 SET val = inc_slow(val) WHERE val < 100;
```  
Получаем дедлок:  
> ERROR:  deadlock detected  
> DETAIL:  Process 7926 waits for ShareLock on transaction 767; blocked by process 7316.  
> Process 7316 waits for ShareLock on transaction 766; blocked by process 7926.  
> HINT:  See server log for query details.  
> CONTEXT:  while updating tuple (0,56) in relation "test1"  