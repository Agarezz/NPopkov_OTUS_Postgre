# Домашнее задание 1:

Создан инстанс постгре в Yandex Cloud
![YandexCloudPicture](https://github.com/Agarezz/NPopkov_OTUS_Postgre/blob/NikitaPopkov_Homework1/Создан%20хост%20в%20Yandex%20Cloud.png)
Настроено соединение 1 к инстансу из dBeaver. Cоединение 2 - из psql.
![DBeaverPicture](https://github.com/Agarezz/NPopkov_OTUS_Postgre/blob/NikitaPopkov_Homework1/Тест%20подключения%20через%20DBeaver.png)

## Подготовка
> выключить auto commit

:white_check_mark: \set AUTOCOMMIT OFF

> сделать в первой сессии новую таблицу и наполнить ее данными
> create table persons(id serial, first_name text, second_name text);
> insert into persons(first_name, second_name) values('ivan', 'ivanov');
> insert into persons(first_name, second_name) values('petr', 'petrov'); commit;

:white_check_mark: Готово

> посмотреть текущий уровень изоляции: show transaction isolation level

:white_check_mark: Сессия 1: read committed
:white_check_mark: Сессия 2: "read committed"

## Проверка read committed
> начать новую транзакцию в обоих сессиях с дефолтным (не меняя) уровнем изоляции
> в первой сессии добавить новую запись insert into persons(first_name, second_name) values('sergey', 'sergeev');

:white_check_mark: Готово

> сделать select * from persons во второй сессии

|id|first_name|second_name|
|----:|:----:|:----|
|1|"ivan"|"ivanov"|
|2|"petr"|"petrov"|

> видите ли вы новую запись и если да то почему?
Не вижу, потому, что у сессии 1 уровень read committed, она видит только закоммиченные изменения, а вторая сессия не закоммитила инсерт.

> завершить первую транзакцию - commit;

:white_check_mark: Готово

> сделать select * from persons во второй сессии

|id|first_name|second_name|
|----:|:----:|:----|
|1|"ivan"|"ivanov"|
|2|"petr"|"petrov"|
|3|"sergey"|"sergeev"|

> видите ли вы новую запись и если да то почему?

Вижу, потому, что сессия 1 закоммитила изменения

> завершите транзакцию во второй сессии

:white_check_mark: Готово

## Проверка repeatable read
> начать новые но уже repeatable read транзации - set transaction isolation level repeatable read;

:white_check_mark: Готово

> в первой сессии добавить новую запись insert into persons(first_name, second_name) values('sveta', 'svetova');

:white_check_mark: Готово

> сделать select * from persons во второй сессии

|id|first_name|second_name|
|----:|:----:|:----|
|1|"ivan"|"ivanov"|
|2|"petr"|"petrov"|
|3|"sergey"|"sergeev"|

> видите ли вы новую запись и если да то почему?

Потому, что незакоммиченные изменения видны только при грязном чтении

> завершить первую транзакцию - commit;

:white_check_mark: Готово

> сделать select * from persons во второй сессии

|id|first_name|second_name|
|----:|:----:|:----|
|1|"ivan"|"ivanov"|
|2|"petr"|"petrov"|
|3|"sergey"|"sergeev"|
Не появилась

> видите ли вы новую запись и если да то почему?

Вообще Repetable read допускает фантомное чтение, но, как сказано в предыдущем уроке, конкретно в PG - не допускается.

> завершить вторую транзакцию

:white_check_mark: Готово

> сделать select * from persons во второй сессии

|id|first_name|second_name|
|----:|:----:|:----|
|1|"ivan"|"ivanov"|
|2|"petr"|"petrov"|
|3|"sergey"|"sergeev"|
|4|"sveta"|"svetova"|

> видите ли вы новую запись и если да то почему? ДЗ сдаем в виде миниотчета в markdown в гите

Теперь появилась, по понятным причинам - обе транзакции завершены.