# Домашнее задание 5 - Настройка autovacuum с учетом оптимальной производительности
### создать GCE инстанс типа e2-medium и standard disk 10GB

:white_check_mark: На Yandex Cloud настроен инстанс 10 ГБ, 4 ядра 100%, 4 ГБ оперативки

### установить на него PostgreSQL 13 с дефолтными настройками

``` console
sudo apt update && sudo apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" ###  /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-13
```
:white_check_mark:

### применить параметры настройки PostgreSQL из прикрепленного к материалам занятия файла

``` console
sudo -u postgres psql
```
``` sql
ALTER SYSTEM SET max_connections = 40;
ALTER SYSTEM SET shared_buffers = '1GB';
ALTER SYSTEM SET effective_cache_size = '3GB';
ALTER SYSTEM SET maintenance_work_mem = '512MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 500;
ALTER SYSTEM SET random_page_cost = 4;
ALTER SYSTEM SET effective_io_concurrency = 2;
ALTER SYSTEM SET work_mem = '6553kB';
ALTER SYSTEM SET min_wal_size = '4GB';
ALTER SYSTEM SET max_wal_size = '16GB';
\q
```
``` console
sudo pg_ctlcluster 13 main restart
```
:white_check_mark:

### выполнить pgbench -i postgres

``` console
sudo -u postgres pgbench -i postgres
```
:white_check_mark:

### запустить pgbench -c8 -P 60 -T 3600 -U postgres postgres

``` console
sudo -u postgres pgbench -c 8 -P 60 -T 3600 postgres
```
:white_check_mark:

### дать отработать до конца

С этим были проблемы - ssh соединение довольно быстро рвется и просто так на час его оставить нельзя.  
Пришлось прописать на ВМ:

``` console
sudo nano /etc/ssh/sshd_config

ClientAliveInterval 55
TCPKeepAlive yes
ClientAliveCountMax 10000
```

В windows добавить в папку $USER\.ssh файл config, а в него настройку

``` console
Host * 
ServerAliveInterval 55
```

После этого отработало:

>starting vacuum...end.  
>progress: 60.0 s, 576.7 tps, lat 13.862 ms stddev 20.111  
>progress: 120.0 s, 690.4 tps, lat 11.584 ms stddev 18.174  
>progress: 180.0 s, 504.0 tps, lat 15.868 ms stddev 28.658  
>progress: 240.0 s, 677.5 tps, lat 11.786 ms stddev 18.669  
>progress: 300.0 s, 652.8 tps, lat 12.270 ms stddev 20.045  
>progress: 360.0 s, 662.5 tps, lat 12.071 ms stddev 18.395  
>progress: 420.0 s, 639.5 tps, lat 12.507 ms stddev 18.374  
>progress: 480.0 s, 662.3 tps, lat 12.075 ms stddev 11.825  
>progress: 540.0 s, 673.1 tps, lat 11.881 ms stddev 18.807  
>progress: 600.0 s, 607.5 tps, lat 13.165 ms stddev 19.896  
>progress: 660.0 s, 655.2 tps, lat 12.206 ms stddev 19.473  
>progress: 720.0 s, 697.5 tps, lat 11.465 ms stddev 18.798  
>progress: 780.0 s, 672.5 tps, lat 11.893 ms stddev 13.883  
>progress: 840.0 s, 632.8 tps, lat 12.639 ms stddev 12.253  
>progress: 900.0 s, 635.6 tps, lat 12.582 ms stddev 15.467  
>progress: 960.0 s, 657.7 tps, lat 12.161 ms stddev 12.865  
>progress: 1020.0 s, 680.0 tps, lat 11.761 ms stddev 11.589  
>progress: 1080.0 s, 660.1 tps, lat 12.115 ms stddev 11.681  
>progress: 1140.0 s, 568.9 tps, lat 14.061 ms stddev 16.962  
>progress: 1200.0 s, 644.3 tps, lat 12.414 ms stddev 12.945  
>progress: 1260.0 s, 655.6 tps, lat 12.197 ms stddev 11.809  
>progress: 1320.0 s, 687.6 tps, lat 11.633 ms stddev 10.618  
>progress: 1380.0 s, 638.6 tps, lat 12.524 ms stddev 14.317  
>progress: 1440.0 s, 605.0 tps, lat 13.221 ms stddev 13.724  
>progress: 1500.0 s, 644.2 tps, lat 12.415 ms stddev 13.237  
>progress: 1560.0 s, 656.3 tps, lat 12.184 ms stddev 12.509  
>progress: 1620.0 s, 665.7 tps, lat 12.013 ms stddev 11.368  
>progress: 1680.0 s, 686.5 tps, lat 11.650 ms stddev 11.610  
>progress: 1740.0 s, 658.0 tps, lat 12.152 ms stddev 15.905  
>progress: 1800.0 s, 491.1 tps, lat 16.289 ms stddev 16.400  
>progress: 1860.0 s, 510.1 tps, lat 15.675 ms stddev 18.702  
>progress: 1920.0 s, 554.1 tps, lat 14.440 ms stddev 14.303  
>progress: 1980.0 s, 657.1 tps, lat 12.173 ms stddev 12.828  
>progress: 2040.0 s, 695.4 tps, lat 11.500 ms stddev 10.774  
>progress: 2100.0 s, 593.8 tps, lat 13.470 ms stddev 14.059  
>progress: 2160.0 s, 637.7 tps, lat 12.540 ms stddev 12.223  
>progress: 2220.0 s, 627.5 tps, lat 12.745 ms stddev 13.324  
>progress: 2280.0 s, 672.5 tps, lat 11.892 ms stddev 11.440  
>progress: 2340.0 s, 667.2 tps, lat 11.988 ms stddev 12.147  
>progress: 2400.0 s, 577.4 tps, lat 13.849 ms stddev 15.267  
>progress: 2460.0 s, 628.3 tps, lat 12.731 ms stddev 13.203  
>progress: 2520.0 s, 655.0 tps, lat 12.207 ms stddev 13.205  
>progress: 2580.0 s, 627.6 tps, lat 12.745 ms stddev 13.428  
>progress: 2640.0 s, 629.5 tps, lat 12.705 ms stddev 13.203  
>progress: 2700.0 s, 636.8 tps, lat 12.558 ms stddev 14.287  
>progress: 2760.0 s, 684.1 tps, lat 11.692 ms stddev 11.338  
>progress: 2820.0 s, 667.8 tps, lat 11.975 ms stddev 10.810  
>progress: 2880.0 s, 662.3 tps, lat 12.075 ms stddev 11.043  
>progress: 2940.0 s, 692.4 tps, lat 11.550 ms stddev 11.551  
>progress: 3000.0 s, 630.9 tps, lat 12.676 ms stddev 12.242  
>**progress: 3060.0 s, 536.1 tps, lat 14.919 ms stddev 16.430**  
>**progress: 3120.0 s, 668.6 tps, lat 11.962 ms stddev 12.571**  
>**progress: 3180.0 s, 611.3 tps, lat 13.084 ms stddev 12.860**  
>**progress: 3240.0 s, 672.2 tps, lat 11.897 ms stddev 10.584**  
>**progress: 3300.0 s, 643.9 tps, lat 12.419 ms stddev 13.455**  
>**progress: 3360.0 s, 650.1 tps, lat 12.299 ms stddev 12.006**  
>**progress: 3420.0 s, 647.2 tps, lat 12.357 ms stddev 11.573**  
>**progress: 3480.0 s, 553.4 tps, lat 14.458 ms stddev 15.900**  
>**progress: 3540.0 s, 686.6 tps, lat 11.647 ms stddev 10.719**  
>**progress: 3600.0 s, 648.2 tps, lat 12.339 ms stddev 13.172**  
>transaction type: <builtin: TPC-B (sort of)>  
>scaling factor: 1  
>query mode: simple  
>number of clients: 8  
>number of threads: 1  
>duration: 3600 s  
>number of transactions actually processed: 2295874  
>latency average = 12.540 ms  
>latency stddev = 14.598 ms  
>tps = 637.740063 (including connections establishing)  
>tps = 637.740414 (excluding connections establishing)  

:white_check_mark:

Штатные настройки были такие:

 |Параметр|Значение|
 |----:|:----|
 |autovacuum_analyze_scale_factor       | 0.1      |
 |autovacuum_analyze_threshold          | 50       |
 |autovacuum_freeze_max_age             | 200000000|
 |autovacuum_max_workers                | 3 	   |
 |autovacuum_multixact_freeze_max_age   | 400000000|
 |autovacuum_naptime                    | 60       |
 |autovacuum_vacuum_cost_delay          | 2        |
 |autovacuum_vacuum_cost_limit          | -1       |
 |autovacuum_vacuum_insert_scale_factor | 0.2      |
 |autovacuum_vacuum_insert_threshold    | 1000     |
 |autovacuum_vacuum_scale_factor        | 0.2      |
 |autovacuum_vacuum_threshold           | 50       |
 |autovacuum_work_mem                   | -1       |

### зафиксировать среднее значение tps в последней ⅙ части работы

631,76

### а дальше настроить autovacuum максимально эффективно, так чтобы получить максимально ровное значение tps на горизонте часа

Пробуем настройки из лекции

``` console
sudo -u postgres psql
```
``` sql
ALTER SYSTEM SET log_autovacuum_min_duration = 0;
ALTER SYSTEM SET autovacuum_max_workers = 10;
ALTER SYSTEM SET autovacuum_naptime = '15s';
ALTER SYSTEM SET autovacuum_vacuum_threshold = 25;
ALTER SYSTEM SET autovacuum_vacuum_scale_factor = 0.05;
ALTER SYSTEM SET autovacuum_vacuum_cost_delay = 10;
ALTER SYSTEM SET autovacuum_vacuum_cost_limit = 1000;
\q
```
``` console
sudo pg_ctlcluster 13 main restart
sudo -u postgres pgbench -c 8 -P 60 -T 3600 postgres
```

>starting vacuum...end.  
>progress: 60.0 s, 640.5 tps, lat 12.456 ms stddev 15.248  
>progress: 120.0 s, 597.9 tps, lat 13.404 ms stddev 14.301  
>progress: 180.0 s, 656.1 tps, lat 12.156 ms stddev 12.100  
>progress: 240.0 s, 651.4 tps, lat 12.306 ms stddev 13.265  
>progress: 300.0 s, 656.9 tps, lat 12.138 ms stddev 12.410  
>progress: 360.0 s, 621.6 tps, lat 12.877 ms stddev 12.258  
>progress: 420.0 s, 625.6 tps, lat 12.788 ms stddev 15.665  
>progress: 480.0 s, 666.1 tps, lat 12.033 ms stddev 13.329  
>progress: 540.0 s, 685.9 tps, lat 11.659 ms stddev 11.865  
>progress: 600.0 s, 666.9 tps, lat 11.991 ms stddev 11.851  
>progress: 660.0 s, 653.6 tps, lat 12.237 ms stddev 11.998  
>progress: 720.0 s, 597.0 tps, lat 13.399 ms stddev 15.882  
>progress: 780.0 s, 627.9 tps, lat 12.687 ms stddev 14.242  
>progress: 840.0 s, 654.0 tps, lat 12.266 ms stddev 13.949  
>progress: 900.0 s, 620.8 tps, lat 12.885 ms stddev 15.156  
>progress: 960.0 s, 635.7 tps, lat 12.586 ms stddev 12.981  
>progress: 1020.0 s, 614.9 tps, lat 13.008 ms stddev 15.059  
>progress: 1080.0 s, 676.9 tps, lat 11.819 ms stddev 12.728  
>progress: 1140.0 s, 639.3 tps, lat 12.509 ms stddev 14.025  
>progress: 1200.0 s, 666.0 tps, lat 12.000 ms stddev 13.853  
>progress: 1260.0 s, 484.5 tps, lat 16.511 ms stddev 18.130  
>progress: 1320.0 s, 580.7 tps, lat 13.779 ms stddev 19.288  
>progress: 1380.0 s, 591.1 tps, lat 13.513 ms stddev 16.533  
>progress: 1440.0 s, 683.8 tps, lat 11.712 ms stddev 10.756  
>progress: 1500.0 s, 633.0 tps, lat 12.633 ms stddev 13.046  
>progress: 1560.0 s, 637.6 tps, lat 12.544 ms stddev 13.272  
>progress: 1620.0 s, 645.2 tps, lat 12.398 ms stddev 11.371  
>progress: 1680.0 s, 550.6 tps, lat 14.526 ms stddev 14.156  
>progress: 1740.0 s, 643.5 tps, lat 12.428 ms stddev 12.669  
>progress: 1800.0 s, 690.3 tps, lat 11.563 ms stddev 11.207  
>progress: 1860.0 s, 647.9 tps, lat 12.366 ms stddev 13.313  
>progress: 1920.0 s, 591.7 tps, lat 13.516 ms stddev 13.538  
>progress: 1980.0 s, 647.6 tps, lat 12.351 ms stddev 13.430  
>progress: 2040.0 s, 658.1 tps, lat 12.151 ms stddev 14.620  
>progress: 2100.0 s, 642.8 tps, lat 12.445 ms stddev 12.504  
>progress: 2160.0 s, 561.1 tps, lat 14.219 ms stddev 14.005  
>progress: 2220.0 s, 651.1 tps, lat 12.312 ms stddev 14.150  
>progress: 2280.0 s, 635.8 tps, lat 12.578 ms stddev 12.754  
>progress: 2340.0 s, 622.1 tps, lat 12.852 ms stddev 14.696  
>progress: 2400.0 s, 602.9 tps, lat 13.269 ms stddev 12.239  
>progress: 2460.0 s, 528.7 tps, lat 15.079 ms stddev 16.649  
>progress: 2520.0 s, 632.1 tps, lat 12.673 ms stddev 13.946  
>progress: 2580.0 s, 663.5 tps, lat 12.076 ms stddev 14.599  
>progress: 2640.0 s, 578.4 tps, lat 13.827 ms stddev 14.392  
>progress: 2700.0 s, 576.6 tps, lat 13.866 ms stddev 14.821  
>progress: 2760.0 s, 646.3 tps, lat 12.376 ms stddev 13.643  
>progress: 2820.0 s, 667.1 tps, lat 11.988 ms stddev 11.947  
>progress: 2880.0 s, 650.7 tps, lat 12.292 ms stddev 13.222  
>progress: 2940.0 s, 640.6 tps, lat 12.465 ms stddev 14.727  
>progress: 3000.0 s, 668.1 tps, lat 11.992 ms stddev 13.676  
>progress: 3060.0 s, 565.1 tps, lat 14.149 ms stddev 15.538  
>progress: 3120.0 s, 646.9 tps, lat 12.289 ms stddev 12.622  
>progress: 3180.0 s, 631.5 tps, lat 12.737 ms stddev 13.672  
>progress: 3240.0 s, 636.8 tps, lat 12.564 ms stddev 13.635  
>progress: 3300.0 s, 611.8 tps, lat 13.075 ms stddev 13.412  
>progress: 3360.0 s, 650.0 tps, lat 12.303 ms stddev 13.000  
>progress: 3420.0 s, 659.1 tps, lat 12.133 ms stddev 11.961  
>progress: 3480.0 s, 592.5 tps, lat 13.500 ms stddev 15.677  
>progress: 3540.0 s, 628.7 tps, lat 12.711 ms stddev 13.576  
>progress: 3600.0 s, 648.1 tps, lat 12.351 ms stddev 13.717  
>transaction type: <builtin: TPC-B (sort of)>  
>scaling factor: 1  
>query mode: simple  
>number of clients: 8  
>number of threads: 1  
>duration: 3600 s  
>number of transactions actually processed: 2266749  
>latency average = 12.702 ms  
>latency stddev = 13.814 ms  
>tps = 629.650273 (including connections establishing)  
>tps = 629.650622 (excluding connections establishing)  

Стало хуже.  
Возможно, проблема в том, что я выбрал тип диска SSD и он от вакуума толком не выигрывает.  
Попробуем сделать настройки ещё экстремальнее.

``` console
sudo -u postgres psql
```
``` sql
ALTER SYSTEM SET autovacuum_vacuum_threshold = 15;
ALTER SYSTEM SET autovacuum_vacuum_scale_factor = 0.01;
ALTER SYSTEM SET autovacuum_vacuum_cost_delay = 5;
ALTER SYSTEM SET autovacuum_vacuum_cost_limit = 2000;
\q
```
``` console
sudo pg_ctlcluster 13 main restart
sudo -u postgres pgbench -c 8 -P 60 -T 600 postgres
```

>starting vacuum...end.  
>progress: 60.0 s, 651.2 tps, lat 12.252 ms stddev 13.053  
>progress: 120.0 s, 642.7 tps, lat 12.463 ms stddev 13.207  
>progress: 180.0 s, 691.5 tps, lat 11.566 ms stddev 11.442  
>progress: 240.0 s, 590.3 tps, lat 13.550 ms stddev 12.951  
>progress: 300.0 s, 675.6 tps, lat 11.839 ms stddev 16.334  
>progress: 360.0 s, 624.8 tps, lat 12.803 ms stddev 17.737  
>progress: 420.0 s, 654.9 tps, lat 12.205 ms stddev 12.336  
>progress: 480.0 s, 553.2 tps, lat 14.402 ms stddev 16.977  
>progress: 540.0 s, 531.0 tps, lat 15.129 ms stddev 19.291  
>progress: 600.0 s, 640.8 tps, lat 12.480 ms stddev 13.205  
>transaction type: <builtin: TPC-B (sort of)>  
>scaling factor: 1  
>query mode: simple  
>number of clients: 8  
>number of threads: 1  
>duration: 600 s  
>number of transactions actually processed: 375368  
>latency average = 12.784 ms  
>latency stddev = 14.770 ms  
>tps = 625.576828 (including connections establishing)  
>tps = 625.579005 (excluding connections establishing)  

Стало ещё хуже. Видимо, нагрузка от автовакуума перекрывает выигрыш от его использования.  
Могу предположить, что для теста TPC-B, который гоняет pgbench, на SSD, агрессивные настройки автовакуума не очень подходят.  
Попробуем отключить автовакуум совсем и посмотреть что будет.  

``` console
sudo -u postgres psql
```
``` sql
ALTER SYSTEM SET autovacuum = off;
\q
```
``` console
sudo pg_ctlcluster 13 main restart
sudo -u postgres pgbench -c 8 -P 60 -T 600 postgres
```

>starting vacuum...end.  
>progress: 60.0 s, 631.2 tps, lat 12.661 ms stddev 13.674  
>progress: 120.0 s, 617.2 tps, lat 12.965 ms stddev 13.596  
>progress: 180.0 s, 597.1 tps, lat 13.390 ms stddev 13.203  
>progress: 240.0 s, 648.4 tps, lat 12.336 ms stddev 11.980  
>progress: 300.0 s, 668.8 tps, lat 11.952 ms stddev 12.064  
>progress: 360.0 s, 660.4 tps, lat 12.116 ms stddev 12.986  
>progress: 420.0 s, 518.2 tps, lat 15.436 ms stddev 14.823  
>progress: 480.0 s, 628.3 tps, lat 12.729 ms stddev 13.888  
>progress: 540.0 s, 624.3 tps, lat 12.810 ms stddev 13.983  
>progress: 600.0 s, 626.2 tps, lat 12.771 ms stddev 13.359  
>transaction type: <builtin: TPC-B (sort of)>  
>scaling factor: 1  
>query mode: simple  
>number of clients: 8  
>number of threads: 1  
>duration: 600 s  
>number of transactions actually processed: 373208  
>latency average = 12.858 ms  
>latency stddev = 13.369 ms  
>tps = 621.974185 (including connections establishing)  
>tps = 621.976159 (excluding connections establishing)  

Стало ещё хуже. То есть некий выигрыш от автовакуума всё же есть.  
В общем, похоже, что, для данного конфига инстанса и типа теста, самые оптимальные настройки автовакуума - умеренные. Возможно дефолтные, возможно чуть умереннее, чем дефолтные.  
Вяснить можно, но это потребует значительного времени.  