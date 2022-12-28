# docker-lnmp

## 簡介
用docker容器服務的方式搭建lnmp環境，易於維護、升級，使用前需瞭解Docker的基本概念及常用基本命令。

本dockerfile是由下列項目修改得來，非常感謝兩位前輩提供的資源

- [jianyan74/lnmp-dockerfiles](https://github.com/jianyan74/lnmp-dockerfiles)
- [yeszao/dnmp](https://github.com/yeszao/dnmp)

### 安裝需求
- git
- [Docker](https://docs.docker.com/engine/installation/linux/docker-ce/centos/)
- [Docker Compose](https://docs.docker.com/compose/install/#install-compose)
- （選項）[docker使用鏡像](https://github.com/yeasy/docker_practice/blob/master/install/mirror.md)


### 目錄結構

```
.
├── app  			# 應用目錄
├── data 			# mongo、mysql數據庫文件存儲
├── docs 			# 相關說明文件
├── logs 			# nginx、mysql、php..等日誌文件，並加入gitignore設定
└── services 		# service配置
    ├── memcached
    ├── mongo
    ├── mysql
    ├── nginx
    ├── redis
    └── www # 默認web服務項目根目錄（php/nginx）
```

## 1. 快速使用

1. clone docker-lnmp：
    
    ```
    $ git clone git@github.com:DTL625/docker-lnmp.
    $ chmod -R 777 ./docker-lnmp/logs
    ```
    
2. 複製 `env環境變量`。
    
    ```
    $ cd docker-lnmp
    $ cp .env.sample .env 
    ```

3. 執行命令以啟動容器，首次啟動時會花較長時間：
    
    ```
    # 執行命令建立＆啟動容器（預設使用 docker-compos.yml配置）
    docker-compose up
    
    # （推薦）增加參數 -d 使服務在背景執行
    docker-compose up -d

    # （optinal）使用 -f參數以指定 yml檔設定，以 elk為例;
    docker-compose -f docker-composer-elk.yml up -d 
    ```

4. 使用瀏覽器訪問`http://localhost`(或https)就能看到效果，相關配置與原始碼存在放：
    - **nginx：** ./services/nginx/conf.d/localhost.conf
    - **php：** ./services/www/localhost/index.php

5. 若於nginx設定中有自訂域名，本地訪問時須同步新增到宿主主機中的域名設定`/etc/hosts`中

	```
	# nginx/conf.d/mysite.conf 中自定義域名mysite.local
	server_name     mysite.local;
	
	# 同步至 /etc/hosts/
	127.0.0.1 mysite.local
	```
   
## 2. 常用命令

控制所有容器

```
$ docker-compose up     # 創建並且啓動所有容器
$ docker-compose up -d  # 創建並且後台運行方式啓動所有容器
$ docker-compose down   # 停止並刪除容器，網絡，圖像和掛載卷 
```

控制指定容器，以nmp三兄弟為例：

```
$ docker-compose up nginx php-fpm mysql         # 創建並且啓動nmp多個容器
$ docker-compose up -d nginx php-fpm  mysql     # 創建並且已後台運行的方式啓動nmp容器
```

控制服務，以php為例：

```
$ docker-compose start php-fpm       # 啓動服務
$ docker-compose stop php-fpm        # 停止服務
$ docker-compose restart php-fpm     # 重啓服務
$ docker-compose build php-fpm       # 構建或者重新構建服務
$ docker-compose rm php              # 删除並停止php容器
```

## 3. 快捷指令

> 當專案需執行composer，但本機php版本不符合需求。

相信每個PHP開發者都遇過這問題，而docker本身支援在容器內/外執行對應的service。

但缺點是命令冗長且難以記憶，下面將介紹如何透過`alias` 功能簡化命令解決問這個問題，並分別提供兩種不同方法做使用：

1. 進入容器後使用對應版本服務
2. 在本機端直接引用對應的服務

### 3-1 配置快捷命令

1. 開啟 `~/.bashrc`或`~/.zshrc`文件，並參考 [bash.alias.example](https://github.com/DTL625/docker-lnmp/blob/v1.0-doc/docs/bash.alias.example) 內容加上自定義的命令。
2. 執行 `source` 使設定生效

```
$ source ~/.bashrc 
# or 
$ source ~/.zshrc 
```

### 3-2 透過快捷命令進入容器

設置生效後即可透過簡短版命令直接進入容器，例：php
 
```
# alias dphp='docker exec -it php /bin/sh'

$ dphp
```

執行後根據對應的Dockerfile配置內容進入容器起始位置`/www`，即可執行操作

```
WORKDIR /www
```

### 3-3 本機執行容器

```
$ php -v
PHP 7.2.13 (cli) (built: Dec 21 2018 02:22:47) ( NTS )
Copyright (c) 1997-2018 The PHP Group
Zend Engine v3.2.0, Copyright (c) 1998-2018 Zend Technologies
    with Zend OPcache v7.2.13, Copyright (c) 1999-2018, by Zend Technologies
    with Xdebug v2.6.1, Copyright (c) 2002-2018, by Derick Rethans
```

## 4. 日誌

Log文件生成的位置取決於各服務下`conf`(容器內)以及`docker-compose`（容器外）配置的值，以nginx配置為例：


**容器中service配置**

配置站點log存放位置，為nginx容器中的 `/var/log/nginx`

```
server {    
    access_log /var/log/nginx/nginx.localhost.access.log  main;
    error_log  /var/log/nginx/nginx.localhost.error.log  warn;
}
```

**本機docker-compose與env配置**

```yaml
version: '3'
services:
  nginx:
    # ...
    volumes:
        # 環境參數(.env)設置為 LOG_DIR=../logs
      - ${LOG_DIR}/nginx:/var/log/nginx/:rw 
```
其中以`：`區分三個段落，依序分別為：
1. 本機映射路徑 - 對應路應為`根目錄/logs/ngix`
2. 容器映射路境 - 容器中該目錄的檔案最後會映射到本地路徑中
3. 存取權限 - 容器中存取權限

---

### 更多說明，請參考 `./docs`