# Домашнее задание 11 - Работа с индексами, join'ами  
## Секционировать большую таблицу из демо базы flights  
В качестве демо базы в задании 10 у меня была не flights а дамп со stackoverflow, поэтому буду секционировать её - таблицу t_Posts.

``` sql
CREATE TABLE t_posts (
	id int4 NULL,
	posttypeid int4 NULL,
	acceptedanswerid int4 NULL,
	creationdate timestamptz NULL,
	score int4 NULL,
	viewcount int4 NULL,
	"Body" text NULL,
	owneruserid int4 NULL,
	lasteditoruserid int4 NULL,
	lasteditdate timestamptz NULL,
	lastactivitydate timestamptz NULL,
	"Title" text NULL,
	"Tags" text NULL,
	answercount int4 NULL,
	commentcount int4 NULL,
	contentlicense text NULL
);
```  

Партиционирование зависит от характера запросов к таблице, поэтому первым делом определяем варианты использования:  
1. Поиск постов полнотекстовым поиском по полю Body или Title без ограничений по пользователю и дате  
2. Выборка данных по посту\постам и джойн всех связанных ответов  
3. Поиск вопросов без принятых ответов  

Для кейса 1 партиционированием ничего не сделать

# Для 2 кейса
Посты отличаются по PostTypeId = 1, ответы на них - PostTypeId > 1, при джойне одного на другое они с такими фильтрами будут доставаться, соответствено:  

``` sql
ALTER TABLE t_posts RENAME to t_posts_old;

CREATE TABLE t_posts (
	id int4 NULL,
	posttypeid int4 NULL,
	acceptedanswerid int4 NULL,
	creationdate timestamptz NULL,
	score int4 NULL,
	viewcount int4 NULL,
	"Body" text NULL,
	owneruserid int4 NULL,
	lasteditoruserid int4 NULL,
	lasteditdate timestamptz NULL,
	lastactivitydate timestamptz NULL,
	"Title" text NULL,
	"Tags" text NULL,
	answercount int4 NULL,
	commentcount int4 NULL,
	contentlicense text NULL
)
PARTITION BY LIST(posttypeid);

CREATE TABLE questions  
	PARTITION OF t_posts   
	FOR VALUES IN (1);
  
CREATE TABLE answers  
	PARTITION OF t_posts 
	FOR VALUES DEFAULT;  
  
INSERT INTO t_posts  
SELECT * FROM t_posts_old;  
```  

Проверим как работает:  
``` sql
EXPLAIN  
SELECT pq."Body" AS Question  
	  ,pa."Body" AS Answer  
FROM   t_Posts AS pq  
LEFT   JOIN (t_PostLinks AS pl  
			 INNER JOIN t_Posts AS pa ON pa.Id = pl.RelatedPostId AND pa.posttypeid <> 1)  
			 ON pq.Id = pl.PostId  
WHERE pq.posttypeid = 1;  
```  
>                                        QUERY PLAN  
> ----------------------------------------------------------------------------------------  
>  Hash Left Join  (cost=393.36..685.52 rows=11858 width=1254)  
>    Hash Cond: (pq.id = pl.postid)  
>    ->  Seq Scan on questions pq  (cost=0.00..114.15 rows=1132 width=512)  
>          Filter: (posttypeid = 1)  
>    ->  Hash  (cost=367.17..367.17 rows=2095 width=750)  
>          ->  Hash Join  (cost=5.55..367.17 rows=2095 width=750)  
>                Hash Cond: (pa.id = pl.relatedpostid)  
>                ->  Seq Scan on answers pa  (cost=0.00..314.15 rows=2652 width=750)  
>                      Filter: (posttypeid <> 1)  
>                ->  Hash  (cost=3.58..3.58 rows=158 width=8)  
>                      ->  Seq Scan on t_postlinks pl  (cost=0.00..3.58 rows=158 width=8)  

Видим в плане сканы правильных партиций  

# Для 3 кейса


Поделим уже имеющуюся партицию с вопросами на две - с ответами и без.
На партицию с ответами повесим констрейнт, подсказывающий оптимизатору, что у ответов не может быть подтвержденного ответа.
``` sql
ALTER TABLE t_posts RENAME to t_posts_old;  

CREATE TABLE t_posts (  
	id int4 NULL,  
	posttypeid int4 NULL,  
	acceptedanswerid int4 NULL,  
	creationdate timestamptz NULL,  
	score int4 NULL,  
	viewcount int4 NULL,  
	"Body" text NULL,  
	owneruserid int4 NULL,  
	lasteditoruserid int4 NULL,  
	lasteditdate timestamptz NULL,  
	lastactivitydate timestamptz NULL,  
	"Title" text NULL,  
	"Tags" text NULL,  
	answercount int4 NULL,  
	commentcount int4 NULL,  
	contentlicense text NULL  
)  
PARTITION BY LIST(posttypeid);  

CREATE TABLE questions  
	PARTITION OF t_posts  
	FOR VALUES IN (1)  
	PARTITION BY LIST(acceptedanswerid);  

CREATE TABLE questions_wo_answers  
	PARTITION OF questions  
	FOR VALUES IN (NULL);  

CREATE TABLE questions_w_answers  
	PARTITION OF questions  
	DEFAULT;  
  
CREATE TABLE answers  
	PARTITION OF t_posts  
	DEFAULT;  

ALTER TABLE answers ADD CONSTRAINT answers_acceptedanswerid_is_null_chk  
CHECK (acceptedanswerid IS NULL);  
  
INSERT INTO t_posts  
SELECT * FROM t_posts_old;  
```  

Проверим как работает  
``` sql
EXPLAIN  
SELECT *  
FROM  t_posts  
WHERE posttypeid = 1  
AND   acceptedanswerid IS NULL;  
```  
> Seq Scan on questions_wo_answers t_posts  (cost=0.00..57.04 rows=1 width=188)  
>   Filter: ((acceptedanswerid IS NULL) AND (posttypeid = 1))  

Также проверим, что работает констрейнт  
``` sql
EXPLAIN  
SELECT *  
FROM  t_posts  
WHERE acceptedanswerid IS NOT NULL;  
```  
> Seq Scan on questions_w_answers t_posts  (cost=0.00..68.86 rows=686 width=675)  
>   Filter: (acceptedanswerid IS NOT NULL)  
Лишнего скана партиции с ответами нет, хоть мы и не добавляли фильтр только по ответам  