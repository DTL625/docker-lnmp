# 常用命令介紹

## Docker 相關
創建並啓動一個容器，在run後面加上-d參數，則會創建一個守護式容器在後台運行

```
docker run 
```
查看已經創建的容器

```
docker ps -a 
```
查看已經啓動的容器

```
docker ps -s 
```
啓動容器名為con_name的容器
```
docker start con_name 
```
停止容器名為con_name的容器
```
docker stop con_name 
```
刪除容器名為con_name的容器
```
docker rm con_name 
```
重命名一個容器 
```
docker rename old_name new_name 
```
將終端附著到正在運行的容器名為con_name的容器的終端上面去，前提是創建該容器時指定了相應的sh
```
docker attach con_name 
```

## docker-compose相關

進入容器
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

## 自定義命令

 本項目提供配置好的自訂義命令，使用時請先按 [3-1 配置快捷命令](https://github.com/DTL625/docker-lnmp#3-1-%E9%85%8D%E7%BD%AE%E5%BF%AB%E6%8D%B7%E5%91%BD%E4%BB%A4)步驟安裝自定義命令。

快速進入已啟動容器，並支持下列容器：
```
$dphp
$dmysql
$dnginx
$dredis
```
 
命名格式為`d{容器名}`，語句等同於：
 ```
 docker exec -it {容器名} /bin/sh
 ```
用戶可依照需求自行增加/調整內容
