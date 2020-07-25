# docker-lnmp

非常感謝 [jianyan74/lnmp-dockerfiles](https://github.com/jianyan74/lnmp-dockerfiles)項目， 本dockerfile是由jianyan74/lnmp-dockerfiles項目修改後得來。

在原項目基礎上，增加了以下：
- 增加了環境變量，配置更輕鬆
- 增加了php5.6.32版本，實現多版本
- 修改了apt-get源，可使用阿里源或163源，編譯更快速
- php5.6.32增加了memcache、opencc、opencc4php、xdebug擴展，php7.2如果需要的話，可以拷貝5.6.32dockerfile內的擴展編譯內容到php7.2
- 預先下載好了編譯包，節約時間


搭建lnmp環境

## 簡介
用docker容器服務的方式搭建lnmp環境，易於維護、升級。使用前需瞭解Docker的基本概念，常用基本命令。
可以一條條命令執行docker命令來構建鏡像，容器。這裡推薦使用docker-compose來管理，執行項目，下面是使用流程。


相關軟件版本：
- PHP 7.2
- PHP 5.6.32
- MySQL 5.7
- Nginx 1.12
- Redis 4.0
- Memcached 1.5

用到的PHP擴展
- redis
- swoole latest
- memcached
- memcache
- opencc
- xdebug

#### 目錄

目錄 | 說明
---|---
--- app | 應用安裝目錄
--- data | mongo、mysql數據庫文件存儲
--- docs | 幫助文檔
--- logs | nginx、mongo、mysql、php日誌
--- sercices | 服務軟件配置包
--- --- memcached | memcached配置及安裝文件
--- --- mongo | memcached配置及安裝文件
--- --- mysql | mysql配置及安裝文件
--- --- nginx | nginx配置及安裝文件
--- --- php56 | php5.6.32配置及安裝文件
--- --- php72 | php7.2配置及安裝文件
--- --- redis | redis配置及安裝文件
--- --- docker-composer.yml | docker配置執行文件


## 使用
#### 1.安裝Docker，Docker-compose
- Docker，詳見官方文檔：https://docs.docker.com/engine/installation/linux/docker-ce/centos/
- docker-compose，文檔：https://docs.docker.com/compose/install/
- 鏡像加速，參考[docker使用國內鏡像](https://github.com/yeasy/docker_practice/blob/master/install/mirror.md)
       不然下載鏡像速度會卡的你懷疑人生
- 常見問題，必看。參考[這裡](https://github.com/jianyan74/lnmp-dockerfiles/blob/master/docs/issue.md)
```
sudo pip install -U docker-compose
```

#### 2.下載docker-lnmp
直接clone：
```
git clone git@github.com:gitlexin/docker-lnmp.git
chmod -R 777 ./docker-lnmp/logs
cd docker-lnmp/services
```
拷貝.example.env為.env，根據自己的情況修改其中的配置

#### 3.docker-compose構建項目
進行docker-compose.yml所在文件夾：
執行命令：
```
docker-compose up
```

如果沒問題，下次啓動時可以以守護模式啓用，所有容器將後台運行：
```
docker-compose up -d
```

使用 docker-compose 基本上就這麼簡單，Docker 就跑起來了，用 stop，start 關閉開啓容器服務。
更多的是在於編寫 dockerfile 和 docker-compose.yml 文件。

可以這樣關閉容器並刪除服務：
```
docker-compose down
```

#### 4. Demo站點搭建

進入app目錄將你的項目文件拷貝到其中(項目文件會被映射到容器中的/data/www目錄下)



域名解析

找到 `services/nginx/conf.d` 下的 example.conf 里修改配置
```
server_name example.com;
root /data/www/example;
access_log  /var/log/nginx/example.log;
```
注意重啓一下nginx容器才能生效

## 我自己的常用命令
```
# 開啓所有容器
docker-compose up -d
# 關閉所有容器
docker-compose down
# 重啓某個容器
docker-compose restart nginx|php-fpm56等service名
# 進入容器
docker-compose exec -it 容器id /bin/bash
```

## 問題反饋

在使用中有任何問題，歡迎反饋給我

## 引用

[zPhal-dockerfiles](https://github.com/ZpGuo/zPhal-dockerfiles)

## 學習文檔
[Docker 配置詳解](https://www.jianshu.com/p/2217cfed29d7)

[Docker 入門教程](http://www.ruanyifeng.com/blog/2018/02/docker-tutorial.html)

[Docker 微服務教程](http://www.ruanyifeng.com/blog/2018/02/docker-wordpress-tutorial.html)

