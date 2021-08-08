## 環境參數（.env）介紹


### 共同模塊
**COMPOSE_PROJECT_NAME（選項）**：

docker項目名稱，設定的值會作為前綴附加在啟動容器名稱前，例：
專案名稱為`my_app`並包含`db`與`web`服務，則顯示名分別為`my_app_db`及`my_app_web`。若未設置該值時則以該docker-composer存放資料夾名稱為預設值，詳細可參考 [官方說明](https://docs.docker.com/compose/reference/envvars/#compose_project_name)

**SOURCE_DIR**

本機proj映射位置，提供給nginx與php訪問

**DATA_DIR**

本機資料保存位置，例：mysql、redis

**LOG_DIR**

本機log保存位置

**TZ**

容器時區

### 服務模塊

(待補上)

---


## docker-compose配置介紹


以php-fpm為例：

```yaml
services:
  php-fpm:
    build:
      context: ./php-fpm
      args:
        PHP_VERSION: php:${PHP_VERSION}-fpm-alpine
        CONTAINER_PACKAGE_URL: ${CONTAINER_PACKAGE_URL}
        PHP_EXTENSIONS: ${PHP_EXTENSIONS}
        TZ: "$TZ"
    container_name: php
    environment:
      # 檢測用
      - DB_ROOT_PWD=${MYSQL_ROOT_PASSWORD}
      - DB_NAME=${MYSQL_DATABASE}
      - DB_USERNAME=${MYSQL_USER}
      - DB_PWD=${MYSQL_PASSWORD}
    expose:
      - 9501
    extra_hosts:
      - "www.site1.com:172.17.0.1"
    volumes:
      - ${SOURCE_DIR}:/www/:rw
      - ${PHP_PHP_CONF_FILE}:/usr/local/etc/php/php.ini:ro
      - ${PHP_FPM_CONF_FILE}:/usr/local/etc/php-fpm.d/www.conf:rw
      - ${LOG_DIR}/php-fpm:/var/log/php
      - ${DATA_DIR}/composer:/tmp/composer
    restart: always
    cap_add:
      - SYS_PTRACE
    networks:
      - default
```

**services**

可視為整個docker包配置的根目錄，其中包含各種服務，例：php-fpm

**build**

在執行`docker-compose up`後搭建的任務內容，其中：

- **context** Dockerfile目錄的路徑（或url)
- **args** 增加build參數，該參數只會在build過程中會使用到

**container_name**

指定自定義容器名稱，而不是生成的默認名稱。

**environment**

增加環境變量

**expose**

內部對外端口，但不映射到宿主機，只被連接的服務訪問。

**extra_hosts**

增加主機與域名映射，會在容器中 /etc/hosts 創建一個具有 ip 地址和主機名的映射關係

**volumes**

將主機的檔案或資料夾掛載至容器內

**restart**

重啟策略

- **no**：是默認的重啓策略，在任何情況下都不會重啓容器。
- **always**：容器總是重新啓動。
- **on-failure**：在容器非正常退出時（退出狀態非0），才會重啓容器。
- **unless-stopped**：在容器退出時總是重啓容器，但是不考慮在Docker守護進程啓動時就已經停止了的容器

**cap_add/cap_drop**

添加或刪除容器擁有的宿主機的內核功能。

**networks**

配置容器連接的網絡，引用頂級 networks 下的內容

