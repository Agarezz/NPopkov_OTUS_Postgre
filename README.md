# Домашнее задание 3 Физический уровень PostgreSQL
>создайте виртуальную машину c Ubuntu 20.04 LTS (bionic) в GCE типа e2-medium в default VPC в любом регионе и зоне, например us-central1-a
>поставьте на нее PostgreSQL 14 через sudo apt

```
sudo apt update && sudo apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-14
```

>проверьте что кластер запущен через sudo -u postgres pg_lsclusters

```sudo -u postgres pg_lsclusters```

|Ver |Cluster |Port |Status |Owner    |Data directory              |Log file|
|----:|:----:|:----:|:----:|:----:|:----:|:----|
|14  |main    |5432 |online |postgres |/var/lib/postgresql/14/main |/var/log/postgresql/postgresql-14-main.log|

:white_check_mark:

>зайдите из под пользователя postgres в psql и сделайте произвольную таблицу с произвольным содержимым postgres=# create table test(c1 text); postgres=# insert into test values('1'); \q

```
sudo -u postgres psql -p 5432
create table test(c1 text);
insert into test values('1');
```

:white_check_mark:

>остановите postgres например через sudo -u postgres pg_ctlcluster 14 main stop

```
-u postgres pg_ctlcluster 14 main stop
```

Warning: stopping the cluster using pg_ctlcluster will mark the systemd unit as failed.

Окей, по другому

```
sudo systemctl stop postgresql@14-main
pg_lsclusters
```

|Ver |Cluster |Port |Status |Owner    |Data directory              |Log file|
|----:|:----:|:----:|:----:|:----:|:----:|:----|
|14  |main    |5432 |down |postgres |/var/lib/postgresql/14/main |/var/log/postgresql/postgresql-14-main.log|

:white_check_mark:

>создайте новый standard persistent диск GKE через Compute Engine - Disks в том же регионе и зоне что GCE инстанс размером например 10GB
>добавьте свеже-созданный диск к виртуальной машине - надо зайти в режим ее редактирования и дальше выбрать пункт attach existing disk

![Второй диск](https://github.com/Agarezz/NPopkov_OTUS_Postgre/blob/NikitaPopkov_Homework3/Подключение%20второго%20диска.png)

>проинициализируйте диск согласно инструкции и подмонтировать файловую систему, только не забывайте менять имя диска на актуальное, в вашем случае это скорее всего будет /dev/sdb - https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux

```sudo apt-get update```

Устанавливаем утилиту для работы с дисками

```sudo apt-get install parted```

Проверяем наличие диска

```lsblk```

|NAME   |MAJ:MIN |RM |SIZE |RO |TYPE |MOUNTPOINT|
|----:|:----:|:----:|:----:|:----:|:----:|:----|
|vda    |252:0   | 0 | 15G | 0 |disk |          |
|├─vda1 |252:1   | 0 |  1M | 0 |part |          |
|└─vda2 |252:2   | 0 | 15G | 0 |part |/         |
|vdb    |252:16  | 0 | 20G | 0 |disk |          |

Вот он, "vdb" :white_check_mark:


Размечаем диск

```sudo parted /dev/vdb mklabel gpt```

```sudo parted -a opt /dev/vdb mkpart primary ext4 0% 100%```

Проверяем наличие партиции

```lsblk```

|NAME   |MAJ:MIN |RM |SIZE |RO |TYPE |MOUNTPOINT|
|----:|:----:|:----:|:----:|:----:|:----:|:----|
|vda    |252:0    |0  |15G  |0 |disk | |
|├─vda1 |252:1    |0  | 1M  |0 |part | |
|└─vda2 |252:2    |0  |15G  |0 |part |/|
|vdb    |252:16   |0  |20G  |0 |disk | |
|└─vdb1 |252:17   |0  |20G  |0 |part | |

Партиция vdb1 появилась:white_check_mark:

Форматируем партицию

```sudo mkfs.ext4 -L datapartition /dev/vdb1```

>>Creating filesystem with 5242368 4k blocks and 1310720 inodes
>>Filesystem UUID: bc6528e9-1e64-45a5-ac75-489b5416c15e
>>Superblock backups stored on blocks:
>>      32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
>>      4096000
>>Allocating group tables: done
>>Writing inode tables: done
>>Creating journal (32768 blocks): done
>>Writing superblocks and filesystem accounting information: done
:white_check_mark:

Создаем папку для новой партиции

```sudo mkdir -p /mnt/data```

Монтируем партицию в папку

```sudo mount -o defaults /dev/vdb1 /mnt/data```

Проверяем

```df -h -x tmpfs -x devtmpfs```

|Filesystem      |Size  |Used |Avail |Use% |Mounted on|
|----:|:----:|:----:|:----:|:----:|:----|
|/dev/vda2       | 15G  |3.3G |  11G | 23% |/         |
|/dev/vdb1       | 20G  | 45M |  19G |  1% |/mnt/data |

Примонтировалась успешно :white_check_mark:

>сделайте пользователя postgres владельцем /mnt/data - chown -R postgres:postgres /mnt/data/

```chown -R postgres:postgres /mnt/data```
:white_check_mark:

>перенесите содержимое /var/lib/postgres/14 в /mnt/data - mv /var/lib/postgresql/14 /mnt/data

```sudo mv /var/lib/postgresql/14 /mnt/data```
:white_check_mark:

>попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 14 main start напишите получилось или нет и почему

Error: /var/lib/postgresql/14/main is not accessible or does not exist

Потому, что мы унесли каталог с данными в /mnt/data

:negative_squared_cross_mark:

>задание: найти конфигурационный параметр в файлах раположенных в /etc/postgresql/10/main который надо поменять и поменяйте его напишите что и почему поменяли

```cd /etc/postgresql/14/main```

Посмотрел все файлы, нужный параметр оказался в этом: postgresql.conf

```sudo nano /etc/postgresql/14/main/postgresql.conf```

Меняем строчку
data_directory = '/var/lib/postgresql/14/main'          # use data in another directory
на
data_directory = '/mnt/data/14/main'          # use data in another directory
:white_check_mark:

>попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 14 main start

```sudo systemctl start postgresql@14-main```

>напишите получилось или нет и почему

Получилось
```pg_lsclusters```
|Ver |Cluster |Port |Status |Owner    |Data directory              |Log file|
|----:|:----:|:----:|:----:|:----:|:----:|:----|
|14  |main    |5432 |online |postgres |/mnt/data/14/main |/var/log/postgresql/postgresql-14-main.log|

Получилось. Потому, что теперь движок знает где находятся файлы БД
:white_check_mark:

>зайдите через через psql и проверьте содержимое ранее созданной таблицы

```
sudo -u postgres psql -p 5432
select * from test;
```

|c1|
|:---:|
| 1|
|(1 row)|
:white_check_mark:

>задание со звездочкой *: не удаляя существующий GCE инстанс сделайте новый, поставьте на его PostgreSQL, удалите файлы с данными из /var/lib/postgres, перемонтируйте внешний диск который сделали ранее от первой виртуальной машины ко второй и запустите PostgreSQL на второй машине так чтобы он работал с данными на внешнем диске, расскажите как вы это сделали и что в итоге получилось.

Создал вторую ВМ
![Вторая ВМ](https://github.com/Agarezz/NPopkov_OTUS_Postgre/blob/NikitaPopkov_Homework3/Создана%20вторая%20ВМ.png)
Переподключил диск ко второй ВМ в YC

Примонтировал диск во второй ВМ:
```
sudo mkdir -p /mnt/data
sudo mount -o defaults /dev/vdb1 /mnt/data
df -h -x tmpfs -x devtmpfs
```

|Filesystem      |Size  |Used |Avail |Use% |Mounted on|
|----:|:----:|:----:|:----:|:----:|:----|
|/dev/vda2       | 15G  |2.4G |  12G | 17% |/         |
|/dev/vdb1       | 20G  | 86M |  19G |  1% |/mnt/data |

Установил постгрес на вторую ВМ
```
sudo apt update && sudo apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-14
```

Остановил кластер

```sudo systemctl stop postgresql@14-main```

Удалил файлы из /var/lib/postgresql

```sudo rm -Rf /var/lib/postgresql```

Поменял настройку папки с данными

```sudo nano /etc/postgresql/14/main/postgresql.conf```

Заменил каталог: data_directory = '/mnt/data/14/main'            # use data in another directory

Запустил кластер

```sudo systemctl start postgresql@14-main```

Проверил наличие данных в psql
```
sudo -u postgres psql -p 5432
select * from test;
```

|c1|
|:---:|
| 1|
|(1 row)|

:white_check_mark: