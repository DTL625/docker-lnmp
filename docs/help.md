常用命令

## Docker 相關
创建并启动一个容器，在run后面加上-d参数，则会创建一个守护式容器在后台运行

```
docker run 
```
查看已经创建的容器

```
docker ps -a 
```
查看已经启动的容器

```
docker ps -s 
```
启动容器名为con_name的容器
```
docker start con_name 
```
停止容器名为con_name的容器
```
docker stop con_name 
```
删除容器名为con_name的容器
```
docker rm con_name 
```
重命名一个容器 
```
docker rename old_name new_name 
```
将终端附着到正在运行的容器名为con_name的容器的终端上面去，前提是创建该容器时指定了相应的sh
```
docker attach con_name 
```

## docker-compose相關

进入容器
```
docker-compose exec [images] bash # 例: docker-compose exec php-fpm bash
```

```
$ docker-compose up                         # 創建並且啓動所有容器
$ docker-compose up -d                      # 創建並且以後台運行方式啓動所有容器
$ docker-compose up nginx php mysql         # 創建並且啓動nginx、php、mysql的多個容器

$ docker-compose start php                  # 啓動服務
$ docker-compose stop php                   # 停止服務
$ docker-compose restart php                # 重啓服務
$ docker-compose build php                  # 構建或者重新構建服務

$ docker-compose rm php                     # 刪除並且停止php容器
$ docker-compose down                       # 停止並刪除容器，網絡，圖像和掛載卷
```