# MUSI 生產環境部署指南

## 目錄

1. [預部署檢查](#預部署檢查)
2. [系統需求](#系統需求)
3. [部署步驟](#部署步驟)
4. [健康檢查](#健康檢查)
5. [常見問題](#常見問題)

---

## 預部署檢查

### 依賴檢查清單 ✓

- [ ] Docker 已安裝並運行
- [ ] Docker Compose 版本 >= 1.29
- [ ] 服務器磁盤空間 >= 10GB
- [ ] 服務器內存 >= 4GB (建議 8GB+)
- [ ] 網絡連接正常
- [ ] 防火牆規則已配置 (80, 443 端口)
- [ ] SSL 證書已準備 (如果使用 HTTPS)

### 代碼檢查清單 ✓

- [ ] MUSI 代碼已準備好
- [ ] 環境變數已配置
- [ ] 數據庫遷移已準備
- [ ] 靜態資源已構建 (如果需要)
- [ ] 日誌目錄已創建

---

## 系統需求

### 硬件要求

| 組件 | 最低 | 推薦 | 備註 |
|-----|------|------|------|
| CPU | 2 核 | 4 核+ | 使用現代處理器 |
| 內存 | 4GB | 8GB+ | 根據並發用戶調整 |
| 磁盤 | 20GB | 100GB+ | SSD 推薦 |
| 網絡 | 100Mbps | 1Gbps+ | 根據數據量調整 |

### 軟件要求

- Docker >= 20.10
- Docker Compose >= 1.29
- Linux 內核 >= 4.4
- 支持的操作系統：
  - CentOS 7/8
  - Ubuntu 18.04/20.04/22.04
  - Debian 10/11
  - Alpine Linux

### PHP 擴展檢查

部署前驗證所有必要的擴展都已安裝：

```bash
# 檢查已安裝的 PHP 擴展
php -m

# 必要的擴展
# - Core
# - date
# - gd
# - PDO
# - pdo_mysql
# - mbstring
# - curl
# - redis
# - opcache
```

---

## 部署步驟

### 1. 環境準備

```bash
# 1.1 克隆或更新代碼
git clone <musi-repo-url> /path/to/musi
cd /path/to/docker-lnmp

# 1.2 設置配置文件
cp .env.production .env

# 1.3 編輯 .env 文件
nano .env

# 必須修改的參數：
# COMPOSE_PROJECT_NAME=musi_prod
# SOURCE_DIR=<你的 MUSI 代碼路徑>
# PHP_VERSION=8.1
# NGINX_VERSION=1.25-alpine
```

### 2. 生成必要的目錄和文件

```bash
# 2.1 創建日誌目錄
mkdir -p logs/php-fpm logs/nginx

# 2.2 創建數據目錄
mkdir -p data/composer

# 2.3 設置權限
chmod -R 775 logs data
chown -R 1000:1000 logs data

# 2.4 配置 Nginx 虛擬主機
cp services/nginx/conf.d/production/musi.conf.example \
   services/nginx/conf.d/musi.conf

# 編輯並配置您的域名
nano services/nginx/conf.d/musi.conf
```

### 3. 構建 Docker 鏡像

```bash
# 3.1 構建所有鏡像
docker-compose -f docker-compose.production.yml build

# 3.2 驗證構建
docker images | grep musi

# 3.3 標記鏡像 (可選，用於版本控制)
docker tag musi_prod_php:latest musi_prod_php:v1.0.0
docker tag musi_prod_nginx:latest musi_prod_nginx:v1.0.0
```

### 4. 啟動服務

```bash
# 4.1 啟動所有服務
docker-compose -f docker-compose.production.yml up -d

# 4.2 驗證服務狀態
docker-compose -f docker-compose.production.yml ps

# 4.3 查看啟動日誌
docker-compose -f docker-compose.production.yml logs -f
```

### 5. 初始化應用

```bash
# 5.1 訪問 PHP 容器
docker-compose -f docker-compose.production.yml exec php-fpm bash

# 5.2 執行數據庫遷移 (如果需要)
# cd /www && php artisan migrate --force

# 5.3 清理緩存
# php artisan cache:clear
# php artisan config:cache
# php artisan route:cache

# 5.4 設置文件權限
chown -R www-data:www-data /www/storage
chmod -R 775 /www/storage
```

### 6. SSL/TLS 配置 (可選但推薦)

```bash
# 6.1 生成自簽名證書 (開發環境)
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
#   -keyout services/nginx/ssl/musi.key \
#   -out services/nginx/ssl/musi.crt

# 6.2 使用 Let's Encrypt (生產環境)
# 安裝 Certbot
# apt-get install certbot python3-certbot-nginx

# 6.3 獲取證書
# certbot certonly --standalone -d musi.example.com -d www.musi.example.com

# 6.4 複製證書到 SSL 目錄
# cp /etc/letsencrypt/live/musi.example.com/fullchain.pem services/nginx/ssl/
# cp /etc/letsencrypt/live/musi.example.com/privkey.pem services/nginx/ssl/

# 6.5 更新 Nginx 配置以啟用 HTTPS
nano services/nginx/conf.d/musi.conf
# 取消註釋 HTTPS 塊

# 6.6 重啟 Nginx
docker-compose -f docker-compose.production.yml restart nginx
```

---

## 健康檢查

### 容器檢查

```bash
# 檢查所有容器的狀態
docker-compose -f docker-compose.production.yml ps

# 查看詳細日誌
docker-compose -f docker-compose.production.yml logs php-fpm
docker-compose -f docker-compose.production.yml logs nginx
```

### PHP-FPM 檢查

```bash
# 檢查 PHP 版本
docker-compose -f docker-compose.production.yml exec php-fpm php -v

# 檢查已加載的擴展
docker-compose -f docker-compose.production.yml exec php-fpm php -m

# 檢查 PHP-FPM 狀態頁面
curl http://localhost:9000/status

# 檢查 PHP-FPM ping
curl http://localhost:9000/ping
```

### Nginx 檢查

```bash
# 檢查 Nginx 版本
docker-compose -f docker-compose.production.yml exec nginx nginx -v

# 測試配置語法
docker-compose -f docker-compose.production.yml exec nginx nginx -t

# 查看 Nginx 進程
docker-compose -f docker-compose.production.yml exec nginx ps aux | grep nginx

# 檢查監聽端口
docker-compose -f docker-compose.production.yml exec nginx netstat -tlnp
```

### 應用檢查

```bash
# 訪問健康檢查端點
curl http://localhost/health

# 檢查日誌文件
tail -f logs/php-fpm/error.log
tail -f logs/nginx/error.log
tail -f logs/nginx/access.log

# 檢查文件權限
ls -la /www
```

### 性能檢查

```bash
# 監控 Docker 資源使用
docker stats

# 查看 PHP-FPM 進程
docker-compose -f docker-compose.production.yml exec php-fpm ps aux

# 檢查磁盤使用
df -h

# 檢查內存使用
free -h
```

---

## 常見問題

### Q1: 容器無法啟動

**症狀**: Docker Compose 容器狀態為 `Exit` 或 `Restarting`

**解決方案**:
```bash
# 查看詳細錯誤日誌
docker-compose -f docker-compose.production.yml logs php-fpm

# 常見原因和解決方案：
# 1. 權限問題
chown -R www-data:www-data /www

# 2. 配置文件錯誤
docker-compose -f docker-compose.production.yml exec php-fpm php -l

# 3. 端口被佔用
netstat -tlnp | grep 9000

# 4. 內存不足
free -h
```

### Q2: PHP 擴展未加載

**症狀**: `Call to undefined function` 錯誤

**解決方案**:
```bash
# 檢查已安裝的擴展
docker-compose -f docker-compose.production.yml exec php-fpm php -m

# 重新構建 PHP 鏡像
docker-compose -f docker-compose.production.yml build --no-cache php-fpm

# 驗證 Dockerfile 中的擴展列表
cat services/php-fpm/Dockerfile
```

### Q3: Nginx 返回 502 Bad Gateway

**症狀**: 瀏覽器顯示 `502 Bad Gateway`

**解決方案**:
```bash
# 1. 檢查 PHP-FPM 狀態
docker-compose -f docker-compose.production.yml ps

# 2. 驗證 PHP-FPM 監聽地址
docker-compose -f docker-compose.production.yml exec php-fpm cat /usr/local/etc/php-fpm.d/www.conf | grep listen

# 3. 檢查 Nginx 配置
docker-compose -f docker-compose.production.yml exec nginx nginx -t

# 4. 查看 Nginx 錯誤日誌
tail -f logs/nginx/error.log

# 5. 重啟 PHP-FPM
docker-compose -f docker-compose.production.yml restart php-fpm
```

### Q4: 數據庫連接失敗

**症狀**: `SQLSTATE[HY000] [2002] Connection refused`

**解決方案**:
1. 確保數據庫服務器可訪問
2. 驗證 .env 中的數據庫配置
3. 使用外部數據庫時，確保網絡連接正常

```bash
# 測試數據庫連接
docker-compose -f docker-compose.production.yml exec php-fpm bash
php -r "
\$pdo = new PDO('mysql:host=db_host;dbname=db_name', 'user', 'pass');
echo 'Database connection successful';
"
```

### Q5: 高內存使用率

**症狀**: 服務器內存使用接近 100%

**解決方案**:
1. 減少 PHP-FPM `pm.max_children` 值
2. 增加伺服器內存
3. 優化應用代碼

```bash
# 監控内存使用
docker stats
free -h

# 檢查 PHP 進程數
docker-compose -f docker-compose.production.yml exec php-fpm ps aux | grep php-fpm | wc -l
```

### Q6: 日誌文件過大

**症狀**: 磁盤空間不足

**解決方案**:
```bash
# 設置日誌輪轉
cat > /etc/logrotate.d/musi-docker << 'EOF'
/home/user/docker-lnmp/logs/*/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 www-data www-data
    sharedscripts
}
EOF

# 手動清理舊日誌
find logs -name "*.log" -type f -mtime +30 -delete
```

---

## 監控和維護

### 定期任務

- [ ] 每周檢查一次日誌
- [ ] 每月更新 Docker 鏡像
- [ ] 每季度審核性能指標
- [ ] 定期備份應用數據

### 備份和恢復

```bash
# 備份應用數據
tar -czf backup_$(date +%Y%m%d).tar.gz www data

# 恢復應用數據
tar -xzf backup_20231201.tar.gz
```

### 自動化監控腳本

```bash
#!/bin/bash
# 定期檢查服務狀態

if ! docker-compose -f docker-compose.production.yml ps | grep -q "Up"; then
    echo "Warning: Service is down!" | mail -s "MUSI Service Alert" admin@example.com
    docker-compose -f docker-compose.production.yml restart
fi
```

---

## 資源

- [Docker 官方文檔](https://docs.docker.com/)
- [Docker Compose 文檔](https://docs.docker.com/compose/)
- [Nginx 文檔](https://nginx.org/en/docs/)
- [PHP 官方文檔](https://www.php.net/docs.php)
- [PHP-FPM 文檔](https://www.php.net/manual/en/install.fpm.php)

---

## 支持

如遇到問題，請聯繫技術支持或查看 PRODUCTION.md 文件。
