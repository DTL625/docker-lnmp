### 目錄

- 安裝composer時候出現錯誤
- 啓動後出現類似的錯誤
- 修改默認數據庫賬號密碼
- 容器內數據庫連接127.0.0.1連不上怎麼辦

### 1、安裝composer時候出現錯誤
```
curl: (56) SSL read: error:00000000:lib(0):func(0):reason(0), errno 104
```
解決方法

> 網絡請求問題，重新執行一下 `docker-compose up`

### 2、啓動後出現類似的錯誤
```
Removing intermediate container d91a90bb00b5
 ---> 40e52ab712e3
Successfully built 40e52ab712e3
Successfully tagged services_nginx:latest
Creating services_mysql-db_1 ... error
Creating services_mysql-db_1 ... 
Creating services_redis-db_1 ... error

ERROR: for services_mysql-db_1  Cannot start service mysql-db: driver failed programming external connectivity on endpoint services_mysql-db_1 (2cce096d8d21d8324c101d2bd50f8f90b55f37a253be57a4fbfc9098bcf20d61): Error starting userland proxy: listen tcp 0.0.0.0:3306: bind: address already in use

ERROR: for services_redis-db_1  Cannot start service redis-db: driver failed programming external connectivity on endpoint services_redis-db_1 (617a4e9988ef5c3d0f74bbe4988a916d9f654d3f168bbead9451c3b97842e0bc): Error starting userland proxy: listen tcp 0.0.0.0:6379: bind: address already in use

ERROR: for redis-db  Cannot start service redis-db: driver failed programming external connectivity on endpoint services_redis-db_1 (617a4e9988ef5c3d0f74bbe4988a916d9f654d3f168bbead9451c3b97842e0bc): Error starting userland proxy: listen tcp 0.0.0.0:6379: bind: address already in use

ERROR: for mysql-db  Cannot start service mysql-db: driver failed programming external connectivity on endpoint services_mysql-db_1 (2cce096d8d21d8324c101d2bd50f8f90b55f37a253be57a4fbfc9098bcf20d61): Error starting userland proxy: listen tcp 0.0.0.0:3306: bind: address already in use
ERROR: Encountered errors while bringing up the project.
```

解決方法

> 由於映射端口衝突導致的，修改 docker-composer.yml 文件裡面對應的容器映射端口，比如 3306:3306 => 3307:3306


### 3、修改默認數據庫賬號密碼

解決方法

編輯 `services\docker-compose.yml`文件在46行左右修改初始密碼
```
        MYSQL_ROOT_PASSWORD: 5eNyjNf # root密碼 自行修改
        MYSQL_DATABASE: rageframe # 數據庫名
        MYSQL_USER: rageframe
        MYSQL_PASSWORD: 2589632147
```

### 4、容器內數據庫連接127.0.0.1連不上怎麼辦

解決方法

> 使用顯示所有容器IP地址

```
docker inspect --format='{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)
```
會輸出如下類似的，可以看出mysql地址為172.21.0.2，redis地址為172.21.0.3
```
/services_nginx_1 - 172.21.0.5
/services_php-fpm_1 - 172.21.0.4
/services_mysql-db_1 - 172.21.0.2
/services_redis-db_1 - 172.21.0.3
/priceless_ptolemy - 
```

---

首先透過 `docker-compose ps ` 列出所有服務，查找對應的 container_name

```
  Name                Command               State  
--------------------------------------------------
mysql-db   docker-entrypoint.sh mysqld      Up      
nginx      /docker-entrypoint.sh ngin ...   Up      ... (略)
php        docker-php-entrypoint php-fpm    Up     
redis-db   docker-entrypoint.sh redis ...   Up     
```
亦可在 docker-comopose.yml 中自訂容器名稱

``` 
  mysql:
    build:
      context: ./mysql
      args:
        MYSQL_VERSION: mysql:${MYSQL5_VERSION}
        TZ: "$TZ"
    container_name: mysql-db # 自訂container_name
```


執行 `docker-compose exec -it [container_name] `，例：

```
$ docker-compose exec -it php /bin/bash
$ docker-compose exec -it mysql-db /bin/bash
```
