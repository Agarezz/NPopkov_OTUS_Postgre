# Домашнее задание 12 - Триггеры, поддержка заполнения витрин  

## Скрипт и развернутое описание задачи – в ЛК (файл hw_triggers.sql) или по ссылке: https://disk.yandex.ru/d/l70AvknAepIJXQ  
## В БД создана структура, описывающая товары (таблица goods) и продажи (таблица sales).  
## Есть запрос для генерации отчета – сумма продаж по каждому товару.  
## БД была денормализована, создана таблица (витрина), структура которой повторяет структуру отчета.  
## Создать триггер на таблице продаж, для поддержки данных в витрине в актуальном состоянии (вычисляющий при каждой продаже сумму и записывающий её в витрину)  
## Подсказка: не забыть, что кроме INSERT есть еще UPDATE и DELETE  

Развернул базу из скрипта по ссылке на яндекс диске
Делаем триггерную функцию и триггеры:
``` sql
CREATE OR REPLACE FUNCTION tr_update_good_sum_mart()
   RETURNS trigger
   LANGUAGE plpgsql
AS
$$
BEGIN
	UPDATE good_sum_mart Tgt
	SET	   sum_sale = tgt.sum_sale - src.sum_sale_storno + src.sum_sale_new
	FROM  (SELECT G.good_name
				 ,sum(G.good_price * So.sales_qty) AS sum_sale_storno
				 ,sum(G.good_price * Sn.sales_qty) AS sum_sale_new
		   FROM   goods G
		   LEFT   JOIN tb_old So ON So.good_id = G.goods_id
		   LEFT   JOIN tb_new Sn ON Sn.good_id = G.goods_id
		   WHERE  So.good_id IS NOT NULL
		   		  OR Sn.good_id IS NOT NULL
		   GROUP  BY G.good_name) Src
	WHERE  tgt.good_name = src.good_name;

	INSERT INTO good_sum_mart (good_name, sum_sale)
	SELECT G.good_name
		  ,sum(G.good_price * Sn.sales_qty) AS sum_sale
	FROM   goods G
	INNER  JOIN tb_new Sn ON Sn.good_id = G.goods_id
	GROUP  BY G.good_name
	HAVING G.good_name NOT IN (SELECT good_name FROM good_sum_mart);

    RETURN NULL;
END;
$$;

CREATE TRIGGER tr_good_sum_mart_insert
   AFTER INSERT ON sales
   REFERENCING NEW TABLE AS tb_new
   FOR EACH STATEMENT
   EXECUTE PROCEDURE tr_update_good_sum_mart();

CREATE TRIGGER tr_good_sum_mart_update
   AFTER UPDATE ON sales
   REFERENCING NEW TABLE AS tb_new OLD TABLE AS tb_old
   FOR EACH STATEMENT
   EXECUTE PROCEDURE tr_update_good_sum_mart();

CREATE TRIGGER tr_good_sum_mart_delete
   AFTER DELETE ON sales
   REFERENCING OLD TABLE AS tb_old
   FOR EACH STATEMENT
   EXECUTE PROCEDURE tr_update_good_sum_mart();
```  

Проверяем  
Исходные данные  
> Автомобиль Ferrari FXX K	185000000.01  
> Спички хозайственные	65.50  
``` sql
INSERT INTO sales (good_id, sales_qty) VALUES (1, 10);  
```  
Изменения по insert отразились корректно  
> Автомобиль Ferrari FXX K	185000000.01  
> Спички хозайственные	70.50  
``` sql
UPDATE sales  
SET    sales_qty = 2  
WHERE  good_id = 2;  
```  
Изменения по update отразились корректно  
> Спички хозайственные	70.50  
> Автомобиль Ferrari FXX K	370000000.02  
``` sql
DELETE FROM sales
WHERE  good_id = 2;
```  
Изменения по delete отразились корректно  
> Спички хозайственные	70.50  

## Чем такая схема (витрина+триггер) предпочтительнее отчета, создаваемого "по требованию" (кроме производительности)?  
## Подсказка: В реальной жизни возможны изменения цен.  
Триггер откладывает данные в отдельную витрину и, таким образом, фиксирует состояние отчета на момент проведения операции - сумма не будет гулять в зависимости от состояния данных на дату формировнания отчета.  
Но это решение также имеет ряд недостатков:  
1. Витрина агрегированная, детальных данных с историей изменения к ней нет. Если суммы в какой-то момент вызовут вопросы, обьяснить почему они стали такими и из каких компонент сложились будет невозможно.  
2. Данные фиксируются на самом деле не на дату проведения операции по учету, а на дату транзакции в БД, которая может отличаться от бизнес-даты. Например, мы можем сегодня ввести продажи за вчера, при этм цены могли со вчера измениться - будет полная чехарда.  
3. Если отчет строго оперативный, у него должна быть ограниченная глубина обработки операций. Если отчет исторический, прошедшие периоды должны фиксироваться, замораживаться, защищаться от изменений задним числом. Без введения историчности в витрину это невозможно. Сейчас отчет ни то ни другое.С одной стороны в нём вообще все операции с начала времен, с другой, можно удалить операцию из прошедшего периода и всё пересчитается.  
По-хорошему, такое нужно реализовывать как миним-хранилище - сохранять историю изменения исходных данных, например с помощью CDC, с valid_from/valid_to для каждой записи, и строить витрину уже на них, с полной историчностью.  