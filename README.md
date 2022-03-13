# Домашнее задание 2
>сделать в GCE инстанс с Ubuntu 20.04

:white_check_mark: Сделан ВМ в Yandex Cloud с Ubuntu 20.04
![YandexCloudPicture](https://github.com/Agarezz/NPopkov_OTUS_Postgre/blob/NikitaPopkov_Homework2/ВМ%20ДЗ2.png)

:white_check_mark: Подключился к ВМ по SSH с домашнего ПК
![ConnectionPicture](https://github.com/Agarezz/NPopkov_OTUS_Postgre/blob/NikitaPopkov_Homework2/Подключился%20к%20ВМ%20по%20ssh.png)

>поставить на нем Docker Engine

curl -fsSL https://get.docker.com -o get-docker.sh

sudo sh get-docker.sh

rm get-docker.sh

sudo usermod -aG docker $USER

:white_check_mark:

>сделать каталог /var/lib/postgres

sudo mkdir /var/lib/postgres

:white_check_mark:

>развернуть контейнер с PostgreSQL 14 смонтировав в него /var/lib/postgres

sudo docker network create pg-net

sudo docker run --name pg-docker --network pg-net -e POSTGRES_PASSWORD=postgres -d -p 5432:5432 -v /var/lib/postgres:/var/lib/postgresql/data postgres:14

:white_check_mark:Контейнер создался:

sudo docker ps -a

|CONTAINER ID|IMAGE|COMMAND|CREATED|STATUS|PORTS|NAMES|
|-------------:|:------------:|:------------:|:------------:|:------------:|:------------:|:------------|
|56fee04ee960|postgres:14|"docker-entrypoint.s…"|26 seconds ago|Up 22 seconds|0.0.0.0:5432->5432/tcp, :::5432->5432/tcp|pg-docker|

>развернуть контейнер с клиентом postgres
>подключится из контейнера с клиентом к контейнеру с сервером и сделать таблицу с парой строк

sudo docker run -it --rm --network pg-net --name pg-client postgres:14 psql -h pg-docker -U postgres

create table test_table (id int, val text)

insert into test_table values(1,'value1');

insert into test_table values(2,'value2');

select * from test_table;

|id|val|
|----:|:--------|
|1| value1|
|2| value2|
(2 rows)

:white_check_mark:

>подключится к контейнеру с сервером с ноутбука/компьютера извне инстансов GCP

Изначально подключился извне

sudo docker exec -it pg-docker bash

:white_check_mark:

>удалить контейнер с сервером

sudo docker stop 56fee04ee960

sudo docker rm 56fee04ee960

:white_check_mark:

>создать его заново

sudo docker run --name pg-docker --network pg-net -e POSTGRES_PASSWORD=postgres -d -p 5432:5432 -v /var/lib/postgres:/var/lib/postgresql/data postgres:14

:white_check_mark:

>подключится снова из контейнера с клиентом к контейнеру с сервером

sudo docker run -it --rm --network pg-net --name pg-client postgres:14 psql -h pg-docker -U postgres

>проверить, что данные остались на месте

postgres=# select * from test_table;

|id|val|
|----:|:--------|
|1| value1|
|2| value2|
(2 rows)

:white_check_mark:

Всё останавливаем и удаляем:

sudo docker stop a9c0382f711f

sudo docker rm a9c0382f711f

sudo docker images -q

sudo docker rmi d7337c283715

:white_check_mark: