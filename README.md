# Домашнее задание 10 - Работа с индексами, join'ами
## Подготовка  

В качестве демо базы используем дамп со Stackoverflow, раздел Beer. https://archive.org/download/stackexchange/beer.stackexchange.com.7z
База представлена в виде выгрузки XMLек, сначала их нужно разобрать.  
Создаем ВМ, 2ГБ RAM, 50ГБ HDD, ставим Postgres 14, далее скачиваем и распаковываем файл:
``` console
wget "https://archive.org/download/stackexchange/beer.stackexchange.com.7z"  
sudo apt-get install p7zip-full  
7z x beer.stackexchange.com.7z -o /home/agarez/beer  
sudo chown -R postgres  /home/agarez/beer  
```  
Файлы:  
> Badges.xml  Comments.xml  PostHistory.xml  PostLinks.xml  Posts.xml  Tags.xml  Users.xml  Votes.xml  
Каждый из файлов загрузим в отдельную таблицу  
Для удобства перейдем в dBeaver, создав под него отдельного пользователя  

``` sql
CREATE USER beaver WITH SUPERUSER PASSWORD '12345';  
```  
Прописываем /etc/postgresql/14/main/pg_hba.conf и /etc/postgresql/14/main/postgresql.conf  
``` console
sudo pg_ctlcluster 14 main restart  
```  

В процессе попытки написать автоматический парсер XML в цикле выяснилось, что postgres умеет только xpath 1.0, а выдергивание имен атрибутов возможно только в xpath 2.0.  
Поэтому схемы XMLей разбираю вручную.  

``` sql
DROP TABLE IF EXISTS t_Badges;
CREATE TABLE t_Badges
AS
SELECT (xpath('//@Id', x))[1]::text::int4 AS Id
	  ,(xpath('//@UserId', x))[1]::text::int4 AS UserId
	  ,(xpath('//@Name', x))[1]::text AS "Name"
	  ,TO_TIMESTAMP((xpath('//@Date', x))[1]::text,'YYYY-MM-DDTHH:MI:SS.S') AS "Date"
	  ,(xpath('//@Class', x))[1]::text::int4 AS "Class"
	  ,(xpath('//@TagBased', x))[1]::text::bool AS TagBased 
FROM   UNNEST(xpath('//row', XMLPARSE(DOCUMENT ltrim(convert_from(pg_read_binary_file('/home/agarez/beer/Badges.xml'), 'UTF8'), chr(65279))))) x;

DROP TABLE IF EXISTS t_Comments;
CREATE TABLE t_Comments
AS
SELECT (xpath('//@Id', x))[1]::text::int4 AS Id
	  ,(xpath('//@PostId', x))[1]::text::int4 AS PostId
	  ,(xpath('//@Score', x))[1]::text::int4 AS Score
	  ,(xpath('//@Text', x))[1]::text AS "Text"
	  ,TO_TIMESTAMP((xpath('//@CreationDate', x))[1]::text,'YYYY-MM-DDTHH:MI:SS.S') AS CreationDate
	  ,(xpath('//@UserId', x))[1]::text::int4 AS UserId
	  ,(xpath('//@ContentLicense', x))[1]::text AS ContentLicense
FROM   UNNEST(xpath('//row', XMLPARSE(DOCUMENT ltrim(convert_from(pg_read_binary_file('/home/agarez/beer/Comments.xml'), 'UTF8'), chr(65279))))) x;


DROP TABLE IF EXISTS t_PostHistory;
CREATE TABLE t_PostHistory
AS
SELECT (xpath('//@Id', x))[1]::text::int4 AS Id
	  ,(xpath('//@PostHistoryTypeId', x))[1]::text::int4 AS PostHistoryTypeId
	  ,(xpath('//@PostId', x))[1]::text::int4 AS PostId
	  ,(xpath('//@RevisionGUID', x))[1]::text AS RevisionGUID
	  ,TO_TIMESTAMP((xpath('//@CreationDate', x))[1]::text,'YYYY-MM-DDTHH:MI:SS.S') AS CreationDate
	  ,(xpath('//@Text', x))[1]::text AS "Text"
	  ,(xpath('//@ContentLicense', x))[1]::text AS ContentLicense
FROM   UNNEST(xpath('//row', XMLPARSE(DOCUMENT ltrim(convert_from(pg_read_binary_file('/home/agarez/beer/PostHistory.xml'), 'UTF8'), chr(65279))))) x;

DROP TABLE IF EXISTS t_PostLinks;
CREATE TABLE t_PostLinks
AS
SELECT (xpath('//@Id', x))[1]::text::int4 AS Id
	  ,TO_TIMESTAMP((xpath('//@CreationDate', x))[1]::text,'YYYY-MM-DDTHH:MI:SS.S') AS CreationDate
	  ,(xpath('//@PostId', x))[1]::text::int4 AS PostId
	  ,(xpath('//@RelatedPostId', x))[1]::text::int4 AS RelatedPostId
	  ,(xpath('//@LinkTypeId', x))[1]::text::int4 AS LinkTypeId
FROM   UNNEST(xpath('//row', XMLPARSE(DOCUMENT ltrim(convert_from(pg_read_binary_file('/home/agarez/beer/PostLinks.xml'), 'UTF8'), chr(65279))))) x;

DROP TABLE IF EXISTS t_Posts;
CREATE TABLE t_Posts
AS
SELECT (xpath('//@Id', x))[1]::text::int4 AS Id
	  ,(xpath('//@PostTypeId', x))[1]::text::int4 AS PostTypeId
	  ,(xpath('//@AcceptedAnswerId', x))[1]::text::int4 AS AcceptedAnswerId
	  ,TO_TIMESTAMP((xpath('//@CreationDate', x))[1]::text,'YYYY-MM-DDTHH:MI:SS.S') AS CreationDate
	  ,(xpath('//@Score', x))[1]::text::int4 AS Score
	  ,(xpath('//@ViewCount', x))[1]::text::int4 AS ViewCount
	  ,(xpath('//@Body', x))[1]::text AS "Body"
	  ,(xpath('//@OwnerUserId', x))[1]::text::int4 AS OwnerUserId
	  ,(xpath('//@LastEditorUserId', x))[1]::text::int4 AS LastEditorUserId
	  ,TO_TIMESTAMP((xpath('//@LastEditDate', x))[1]::text,'YYYY-MM-DDTHH:MI:SS.S') AS LastEditDate
	  ,TO_TIMESTAMP((xpath('//@LastActivityDate', x))[1]::text,'YYYY-MM-DDTHH:MI:SS.S') AS LastActivityDate
	  ,(xpath('//@Title', x))[1]::text AS "Title"
	  ,(xpath('//@Tags', x))[1]::text AS "Tags"
	  ,(xpath('//@AnswerCount', x))[1]::text::int4 AS AnswerCount
	  ,(xpath('//@CommentCount', x))[1]::text::int4 AS CommentCount
	  ,(xpath('//@ContentLicense', x))[1]::text AS ContentLicense
FROM   UNNEST(xpath('//row', XMLPARSE(DOCUMENT ltrim(convert_from(pg_read_binary_file('/home/agarez/beer/Posts.xml'), 'UTF8'), chr(65279))))) x;

DROP TABLE IF EXISTS t_Tags;
CREATE TABLE t_Tags
AS
SELECT (xpath('//@Id', x))[1]::text::int4 AS Id
	  ,(xpath('//@TagName', x))[1]::text AS TagName
	  ,(xpath('//@Count', x))[1]::text::int4 AS "Count"
	  ,(xpath('//@ExcerptPostId', x))[1]::text::int4 AS "ExcerptPostId"
	  ,(xpath('//@WikiPostId', x))[1]::text::int4 AS "WikiPostId"
FROM   UNNEST(xpath('//row', XMLPARSE(DOCUMENT ltrim(convert_from(pg_read_binary_file('/home/agarez/beer/Tags.xml'), 'UTF8'), chr(65279))))) x;

DROP TABLE IF EXISTS t_Users;
CREATE TABLE t_Users
AS
SELECT (xpath('//@Id', x))[1]::text::int4 AS Id
	  ,(xpath('//@Reputation', x))[1]::text::int4 AS Reputation
	  ,TO_TIMESTAMP((xpath('//@CreationDate', x))[1]::text,'YYYY-MM-DDTHH:MI:SS.S') AS CreationDate
	  ,(xpath('//@DisplayName', x))[1]::text AS DisplayName
	  ,TO_TIMESTAMP((xpath('//@LastAccessDate', x))[1]::text,'YYYY-MM-DDTHH:MI:SS.S') AS LastAccessDate
	  ,(xpath('//@WebsiteUrl', x))[1]::text AS WebsiteUrl
	  ,(xpath('//@Location', x))[1]::text AS "Location"
	  ,(xpath('//@AboutMe', x))[1]::text AS AboutMe
	  ,(xpath('//@Views', x))[1]::text::int4 AS "Views"
	  ,(xpath('//@UpVotes', x))[1]::text::int4 AS UpVotes
	  ,(xpath('//@DownVotes', x))[1]::text::int4 AS DownVotes
	  ,(xpath('//@AccountId', x))[1]::text::int4 AS AccountId
FROM   UNNEST(xpath('//row', XMLPARSE(DOCUMENT ltrim(convert_from(pg_read_binary_file('/home/agarez/beer/Users.xml'), 'UTF8'), chr(65279))))) x;

DROP TABLE IF EXISTS t_Votes;
CREATE TABLE t_Votes
AS
SELECT (xpath('//@Id', x))[1]::text::int4 AS Id
	  ,(xpath('//@PostId', x))[1]::text::int4 AS PostId
	  ,(xpath('//@VoteTypeId', x))[1]::text::int4 AS VoteTypeId
	  ,TO_TIMESTAMP((xpath('//@CreationDate', x))[1]::text,'YYYY-MM-DDTHH:MI:SS.S')::DATE AS CreationDate
FROM   UNNEST(xpath('//row', XMLPARSE(DOCUMENT ltrim(convert_from(pg_read_binary_file('/home/agarez/beer/Votes.xml'), 'UTF8'), chr(65279))))) x;
```  

## 1 вариант  
### Создать индекс к какой-либо из таблиц вашей БД  

Для примера, если мы хотим быстро получать все посты по заданному пользователю, нужно добавить индекс на OwnerUserId по t_Posts
``` sql
CREATE INDEX ON t_Posts (OwnerUserId);  
```  

### Прислать текстом результат команды explain, в которой используется данный индекс  
``` sql
EXPLAIN SELECT * FROM t_Posts WHERE OwnerUserId = 666;  
```  
>> Index Scan using t_posts_owneruserid_idx on t_posts  (cost=0.28..8.30 rows=1 width=831)  
>>   Index Cond: (owneruserid = 666)  

### Реализовать индекс для полнотекстового поиска  

Пробуем создать простой gin индекс  
``` sql
CREATE INDEX idx_gin_t_posts
ON t_Posts
USING gin ("Body");
```  
Не дает, посты слишком длинные :(  
>> SQL Error [54000]: ERROR: index row size 4632 exceeds maximum 2712 for index "idx_gin_t_posts"  

Значит делаем на векторах  
``` sql
CREATE INDEX idx_gin_t_posts 
ON t_Posts 
USING gin (to_tsvector('english', "Body"));  
```  

Пробуем поискать  
``` sql
SELECT id  
	  ,ts_rank(to_tsvector('english',"Body") ,plainto_tsquery('I like stout beer')) AS tsrank  
	  ,"Body"  
FROM   t_Posts  
WHERE  to_tsvector('english',"Body") @@ plainto_tsquery('I like stout beer')  
ORDER  BY 2 DESC  
LIMIT  20;  
```  
Работает!  
>> Limit  (cost=33.28..33.28 rows=1 width=683)
>>   ->  Sort  (cost=33.28..33.28 rows=1 width=683)
>>         Sort Key: (ts_rank(to_tsvector('english'::regconfig, "Body"), plainto_tsquery('I like stout beer'::text))) DESC
>>         ->  Bitmap Heap Scan on t_posts  (cost=28.25..33.27 rows=1 width=683)
>>               Recheck Cond: (to_tsvector('english'::regconfig, "Body") @@ plainto_tsquery('I like stout beer'::text))
>>               ->  Bitmap Index Scan on idx_gin_t_posts  (cost=0.00..28.25 rows=1 width=0)
>>                     Index Cond: (to_tsvector('english'::regconfig, "Body") @@ plainto_tsquery('I like stout beer'::text))

Топовый результат:  
id 4823  
rank 0.5672675  
>> In addition to blending different beers (like, blending an stout with an IPA, getting something like a black IPA), it's important to mention that almost all barrel aged beers are blends, because of the very nature of barrel aging.  

### Реализовать индекс на часть таблицы или индекс на поле с функцией  

Индекс на функцию to_tsvector('english',"Body") - выше.  

### Создать индекс на несколько полей  

Например, сделаем индекс, чтобы искать топовые посты с большим числом ответов за заданные даты создания или последней активности.

``` sql
CREATE INDEX ON t_Posts (CreationDate, LastActivityDate, Score, AnswerCount);  

EXPLAIN  
SELECT id  
	  ,Score  
	  ,AnswerCount  
	  ,"Body"  
FROM   t_Posts  
WHERE  LastActivityDate BETWEEN DATE '2021-12-01' AND DATE '2021-12-31'  
	   AND AnswerCount >= 3  
	   AND Score >= 20  
ORDER  BY Score DESC  
LIMIT  5;  
```  
Индекс работает:  
>> Limit  (cost=157.06..157.06 rows=1 width=687)  
>>   ->  Sort  (cost=157.06..157.06 rows=1 width=687)  
>>         Sort Key: score DESC  
>>         ->  Index Scan using t_posts_creationdate_lastactivitydate_score_answercount_idx on t_posts  (cost=0.28..157.05 rows=1 width=687)  
>>               Index Cond: ((lastactivitydate >= '2021-12-01'::date) AND (lastactivitydate <= '2021-12-31'::date) AND (score >= 20) AND (answercount >= 3))  

### Написать комментарии к каждому из индексов  
``` sql
COMMENT ON INDEX t_posts_owneruserid_idx IS 'Index for quick search, based on post owner Id';  
COMMENT ON INDEX idx_gin_t_posts IS 'Index for full-text search through posts texts';  
COMMENT ON INDEX t_posts_creationdate_lastactivitydate_score_answercount_idx IS 'Index for quick searching posts on creationdate, lastactivitydate, score and answercount';  
```  

### Описать что и как делали и с какими проблемами столкнулись  

Все маниупляции и коменты привел выше  

## 2 вариант  
### Реализовать прямое соединение двух или более таблиц. Реализовать левостороннее (или правостороннее) соединение двух или более таблиц. Реализовать запрос, в котором будут использованы разные типы соединений  
Запрос, вытаскивающий посты пользователя и принятые ответы на них
``` sql
SELECT u.DISPLAYNAME AS "Asking User"  
	  ,p.PostTypeId  
	  ,p."Title" AS "Question Title"  
	  ,p."Body" AS "Question"  
	  ,au.DISPLAYNAME AS "Answering User"  
	  ,a."Body" AS "Accepted Answer"  
FROM   t_Users AS u  
INNER  JOIN t_Posts AS p ON u.Id = p.OwnerUserId AND p.posttypeid = 1  
LEFT   JOIN (t_Posts AS a  
			 INNER JOIN t_Users AS au ON au.Id = a.OwnerUserId)  
				ON a.Id = p.AcceptedAnswerId AND a.posttypeid > 1  
WHERE  u.DISPLAYNAME = 'Tom Medley';  
```  
Вопрос и задающий его пользователь джойнятся по INNER.  
Ответ на вопрос может отсутствовать, поэтому ответы джойним по LEFT.  
Если ответ присутстсвует, отвечающий пользователь тоже должен быть, поэтому можем джойнить их по INNER. Но без скобок это сделать не получится, иначе INNER джойн на отвечающих пользователей будет обрезать вопросы без ответов.  

### Реализовать кросс соединение двух или более таблиц  
Например, формируем историю дат для каждого поста, для этого размножаем строки
``` sql
SELECT p.Id
	  ,CASE Mult.a
			WHEN 1 THEN p.CreationDate
			WHEN 2 THEN p.LastEditDate
			WHEN 3 THEN p.LastActivityDate
	   END AS SomeChangeDate
FROM   t_Posts AS p
CROSS  JOIN (SELECT 1::smallint AS a
			 UNION ALL
			 SELECT 2 AS a
			 UNION ALL
			 SELECT 3 AS a) Mult
```  

### Реализовать полное соединение двух или более таблиц  
Например, сравниваем количества и типы бейджей в 14-м и 16-м годах
``` sql
SELECT COALESCE(t1."Name", t2."Name") AS "Name"
	  ,t1.Cnt AS Cnt_14_12
	  ,t2.Cnt AS Cnt_16_12
FROM(SELECT Count(*) AS Cnt
		   ,"Name"
	 FROM   t_Badges
	 WHERE  "Date"::date = '2014-12-01'
	 GROUP  BY 2) t1
FULL JOIN (SELECT Count(*) AS Cnt
				 ,"Name"
		   FROM   t_Badges
		   WHERE  "Date"::date = '2016-12-01'
		   GROUP  BY 2) t2 ON t1."Name" = t2."Name";
```  

### Сделать комментарии на каждый запрос  
Комменты выше, к запросов.  

### К работе приложить структуру таблиц, для которых выполнялись соединения  
Привожу в начале ДЗ, в разделе подготовка.  
