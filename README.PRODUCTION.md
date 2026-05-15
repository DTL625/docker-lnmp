# Docker LNMP - MUSI 生產環境配置

## 概述

本項目為 MUSI 提供專業的生產級 Docker 容器化環境，採用最小化足跡設計。生產環境配置已針對性能、安全性和可靠性進行優化。

## 特色

✅ **精簡配置**: 只包含 Nginx + PHP-FPM，移除開發工具  
✅ **Alpine 鏡像**: 最小化容器尺寸，降低資源消耗  
✅ **無 XDebug**: 生產環境不含調試工具  
✅ **性能優化**: OPCache、Gzip 壓縮、連接池等  
✅ **安全加固**: 隱藏版本號、CSP、HSTS 等安全頭  
✅ **自動化腳本**: 初始化和健康檢查腳本  

## 快速開始

### 第一步：準備環境

```bash
# 克隆項目
git clone https://github.com/DTL625/docker-lnmp.git
cd docker-lnmp

# 切換到 production 分支
git checkout production

# 複製生產配置
cp .env.production .env
```

### 第二步：配置文件

編輯 `.env` 文件，設置以下參數：

```bash
nano .env

# 關鍵參數
COMPOSE_PROJECT_NAME=musi_prod
SOURCE_DIR=./www  # MUSI 代碼路徑
PHP_VERSION=8.1
NGINX_VERSION=1.25-alpine
TZ=Asia/Taipei
```

### 第三步：運行初始化腳本

```bash
# 使腳本可執行
chmod +x scripts/production-init.sh

# 執行初始化
./scripts/production-init.sh
```

這個腳本會：
- ✓ 檢查 Docker 和 Docker Compose
- ✓ 創建必要的目錄結構
- ✓ 構建 Docker 鏡像
- ✓ 啟動所有服務
- ✓ 驗證服務狀態

### 第四步：配置應用

```bash
# 進入 PHP 容器
docker-compose -f docker-compose.production.yml exec php-fpm bash

# 根據需要執行初始化命令
# cd /www
# php artisan migrate --force
# php artisan config:cache
```

## 文件結構

```
docker-lnmp/
├── docker-compose.production.yml  # 生產環境編排
├── .env.production               # 生產環境配置模板
├── PRODUCTION.md                 # 詳細配置文檔
├── DEPLOYMENT_GUIDE.md           # 部署指南
├── README.PRODUCTION.md          # 本文件
│
├── services/
│   ├── php-fpm/
│   │   ├── Dockerfile
│   │   ├── php.ini
│   │   ├── php-fpm.conf
│   │   ├── php.production.ini.example        # 生產配置模板
│   │   ├── php-fpm.production.conf.example   # 生產 FPM 配置模板
│   │   └── extensions/                       # PHP 擴展
│   │
│   └── nginx/
│       ├── Dockerfile
│       ├── nginx.conf
│       ├── fastcgi-php.conf
│       ├── nginx.production.conf.example     # 生產 Nginx 配置模板
│       ├── conf.d/
│       │   ├── production/
│       │   │   └── musi.conf.example        # MUSI 虛擬主機配置
│       │   └── musi.conf                    # 實際虛擬主機配置
│       └── ssl/                              # SSL 證書目錄
│
├── scripts/
│   ├── production-init.sh          # 生產環境初始化腳本
│   └── production-health-check.sh  # 健康檢查腳本
│
├── logs/                           # 日誌目錄
├── data/                           # 數據目錄
└── www/                            # 應用代碼
```

## 配置說明

### 環境變數 (.env)

| 變數 | 說明 | 示例 |
|-----|------|------|
| `COMPOSE_PROJECT_NAME` | Docker 項目名稱 | `musi_prod` |
| `SOURCE_DIR` | 應用代碼路徑 | `./www` |
| `PHP_VERSION` | PHP 版本 | `8.1` |
| `PHP_EXTENSIONS` | PHP 擴展列表 | `pdo_mysql,mysqli,mbstring,gd,curl,opcache,redis` |
| `NGINX_VERSION` | Nginx 版本 | `1.25-alpine` |
| `TZ` | 時區 | `Asia/Taipei` |
| `CONTAINER_PACKAGE_URL` | 包管理源 (可選) | 留空或設為鏡像源 |

### PHP 擴展

**已安裝**:
- `pdo_mysql`: MySQL 數據庫連接
- `mysqli`: MySQL 改進驅動
- `mbstring`: 多字節字符串
- `gd`: 圖像處理
- `curl`: HTTP 請求
- `opcache`: 性能優化
- `redis`: 緩存支持

**不包含** (出於安全考慮):
- `xdebug`: 開發調試工具
- `mongo`: MongoDB (如無需要)

## 常用命令

### 服務管理

```bash
# 啟動服務
docker-compose -f docker-compose.production.yml up -d

# 查看服務狀態
docker-compose -f docker-compose.production.yml ps

# 查看日誌
docker-compose -f docker-compose.production.yml logs -f

# 重啟服務
docker-compose -f docker-compose.production.yml restart

# 停止服務
docker-compose -f docker-compose.production.yml down
```

### 容器操作

```bash
# 進入 PHP 容器
docker-compose -f docker-compose.production.yml exec php-fpm bash

# 進入 Nginx 容器
docker-compose -f docker-compose.production.yml exec nginx bash

# 執行 PHP 命令
docker-compose -f docker-compose.production.yml exec php-fpm php -v

# 查看 PHP 擴展
docker-compose -f docker-compose.production.yml exec php-fpm php -m
```

### 日誌查看

```bash
# 查看 PHP-FPM 日誌
tail -f logs/php-fpm/error.log

# 查看 Nginx 訪問日誌
tail -f logs/nginx/access.log

# 查看 Nginx 錯誤日誌
tail -f logs/nginx/error.log

# 查看詳細日誌
docker-compose -f docker-compose.production.yml logs --tail=100 php-fpm
```

## 運行健康檢查

執行內置的健康檢查腳本以驗證系統狀態：

```bash
# 使腳本可執行
chmod +x scripts/production-health-check.sh

# 運行檢查
./scripts/production-health-check.sh
```

檢查項包括：
- ✓ 容器狀態
- ✓ PHP-FPM 和必要擴展
- ✓ Nginx 配置和進程
- ✓ 進程和資源使用
- ✓ 日誌檢查
- ✓ 網絡連接性
- ✓ 應用可訪問性

## 性能調整

### PHP-FPM 優化

編輯 `services/php-fpm/php-fpm.conf` 調整進程池配置：

```ini
pm = dynamic
pm.max_children = 50        # 根據伺服器內存調整
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 25
```

**建議值**:
- 4GB RAM: `max_children = 30`
- 8GB RAM: `max_children = 60`
- 16GB+ RAM: `max_children = 100`

### OPCache 優化

編輯 `services/php-fpm/php.ini`:

```ini
opcache.memory_consumption = 256       # 內存大小 (MB)
opcache.max_accelerated_files = 10000  # 最大文件數
opcache.revalidate_freq = 60           # 重驗證間隔
```

### Nginx 優化

編輯 `services/nginx/nginx.conf`:

```nginx
worker_processes auto;         # 自動檢測 CPU 核心數
worker_connections 2048;       # 每個進程的連接數
```

## SSL/TLS 配置

### 自簽名證書 (開發環境)

```bash
# 生成自簽名證書
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout services/nginx/ssl/musi.key \
  -out services/nginx/ssl/musi.crt
```

### Let's Encrypt (生產環境推薦)

```bash
# 安裝 Certbot
apt-get install certbot

# 獲取證書
certbot certonly --standalone -d musi.example.com

# 複製到容器目錄
cp /etc/letsencrypt/live/musi.example.com/fullchain.pem services/nginx/ssl/
cp /etc/letsencrypt/live/musi.example.com/privkey.pem services/nginx/ssl/

# 重啟 Nginx
docker-compose -f docker-compose.production.yml restart nginx
```

在 `services/nginx/conf.d/musi.conf` 中啟用 HTTPS 塊。

## 故障排查

### 常見問題

**Q: 502 Bad Gateway**
```bash
# 檢查 PHP-FPM
docker-compose -f docker-compose.production.yml ps
docker-compose -f docker-compose.production.yml logs php-fpm

# 重啟 PHP-FPM
docker-compose -f docker-compose.production.yml restart php-fpm
```

**Q: 連接被拒絕**
```bash
# 檢查防火牆
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 檢查端口占用
netstat -tlnp | grep -E ':(80|443|9000)'
```

**Q: 內存不足**
```bash
# 檢查內存使用
docker stats
free -h

# 減少 PHP-FPM 進程數
# 編輯 services/php-fpm/php-fpm.conf 中的 pm.max_children
```

詳見 DEPLOYMENT_GUIDE.md 中的常見問題部分。

## 監控和維護

### 定期任務

- 每周檢查一次日誌
- 每月更新 Docker 鏡像
- 每季度審核性能指標
- 定期備份應用數據

### 自動備份

```bash
# 備份應用和數據
tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz www data logs

# 恢復備份
tar -xzf backup_20240515_102030.tar.gz
```

### 日誌輪轉

```bash
# 配置日誌輪轉
cat > /etc/logrotate.d/musi-docker << 'EOF'
/home/user/docker-lnmp/logs/*/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
}
EOF
```

## 安全建議

1. **保持鏡像最新**
   ```bash
   docker-compose -f docker-compose.production.yml build --no-cache
   ```

2. **設置適當的文件權限**
   ```bash
   chown -R 1000:1000 www logs data
   chmod -R 755 www
   chmod -R 775 logs data
   ```

3. **定期審計日誌**
   ```bash
   grep -i "error\|failed" logs/php-fpm/error.log
   grep "error" logs/nginx/error.log
   ```

4. **配置防火牆**
   ```bash
   sudo ufw allow 22/tcp   # SSH
   sudo ufw allow 80/tcp   # HTTP
   sudo ufw allow 443/tcp  # HTTPS
   sudo ufw enable
   ```

## 相關文檔

- [PRODUCTION.md](PRODUCTION.md) - 詳細配置文檔
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - 完整部署指南
- [原始 README.md](README.md) - 項目概述

## 版本信息

- PHP: 8.1
- Nginx: 1.25-alpine
- Base Image: Alpine Linux 3.18+

## 支持

如有問題，請參考：
1. DEPLOYMENT_GUIDE.md 中的故障排查
2. 運行 `scripts/production-health-check.sh` 進行診斷
3. 查看相應的日誌文件

## 許可証

按照原項目許可証
