# Docker LNMP Production Configuration

## 概述
此配置針對 MUSI 專案的生產環境優化，精簡為只包含必要的服務（Nginx 和 PHP-FPM）。

## 特點

### 移除的功能
- ❌ **XDebug**: 開發用調試器，不用於生產環境
- ❌ **多數據庫支持**: 只保留 MySQL
- ❌ **開發工具**: 移除了不必要的輔助服務

### 保留的功能
- ✅ **PHP-FPM**: 使用 Alpine Linux 版本，實現最小化足跡
- ✅ **Nginx**: 高性能 Web 服務器，使用 Alpine 版本
- ✅ **Redis**: 緩存支持
- ✅ **基本擴展**: 
  - PDO MySQL: 數據庫連接
  - MySQLi: MySQL 改進版本驅動
  - MBString: 多字節字符串
  - GD: 圖像處理
  - cURL: HTTP 請求
  - OPCache: PHP 性能優化
  - Redis: 緩存客戶端

## 快速開始

### 1. 準備環境

```bash
# 複製生產配置
cp .env.production .env

# 確保目錄存在
mkdir -p www logs/php-fpm logs/nginx data/composer
```

### 2. 構建和啟動

```bash
# 使用生產配置啟動服務
docker-compose -f docker-compose.production.yml up -d

# 檢查狀態
docker-compose -f docker-compose.production.yml ps
```

### 3. 驗證服務

```bash
# 檢查 PHP-FPM 狀態
docker-compose -f docker-compose.production.yml exec php-fpm php -v

# 檢查 Nginx 狀態
docker-compose -f docker-compose.production.yml exec nginx nginx -v
```

## 配置文件

### 核心文件
- `docker-compose.production.yml`: 精簡的生產環境編排配置
- `.env.production`: 生產環境環境變數配置

### PHP 配置
- `services/php-fpm/php.ini`: PHP 配置文件
- `services/php-fpm/php-fpm.conf`: PHP-FPM 進程管理配置

### Nginx 配置
- `services/nginx/nginx.conf`: Nginx 主配置
- `services/nginx/conf.d/`: 虛擬主機配置目錄
- `services/nginx/fastcgi-php.conf`: PHP 快速網關接口配置

## PHP 擴展

### 已安裝的擴展
- `pdo_mysql`: PDO MySQL 驅動
- `mysqli`: MySQL 改進版本
- `mbstring`: 多字節字符串處理
- `gd`: 圖像處理庫
- `curl`: HTTP 客戶端
- `opcache`: PHP 性能優化
- `redis`: Redis 客戶端

### 如何添加其他擴展

如果需要添加更多擴展，修改 `.env` 文件中的 `PHP_EXTENSIONS`：

```bash
# 編輯 .env
PHP_EXTENSIONS=pdo_mysql,mysqli,mbstring,gd,curl,opcache,redis,memcached

# 重新構建
docker-compose -f docker-compose.production.yml up -d --build
```

可用的擴展列表見 `.env.example`

## 性能優化建議

### 1. PHP-FPM 優化
在 `php-fpm.conf` 中調整：
- `pm.max_children`: 最大子進程數
- `pm.start_servers`: 啟動時子進程數
- `pm.min_spare_servers`: 最小空閒進程數
- `pm.max_spare_servers`: 最大空閒進程數

### 2. OPCache 優化
在 `php.ini` 中配置：
```ini
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.revalidate_freq=60
```

### 3. Nginx 優化
在 `nginx.conf` 中調整：
- `worker_processes`: 工作進程數
- `worker_connections`: 單進程連接數
- `keepalive_timeout`: 保活超時時間

## 日誌管理

日誌位置：
- PHP-FPM: `./logs/php-fpm/`
- Nginx: `./logs/nginx/`

## 安全建議

1. **禁用調試功能**:
   - `display_errors = Off` (php.ini)
   - `log_errors = On` (php.ini)
   - 將錯誤日誌寫入文件，不暴露給客戶端

2. **限制文件上傳**:
   - 在 `php.ini` 中設置 `upload_max_filesize`
   - 在 `php.ini` 中設置 `post_max_size`

3. **禁用不必要的函數**:
   - 在 `php.ini` 中設置 `disable_functions`

4. **更新鏡像**:
   - 定期更新 Alpine 基礎鏡像
   - 定期更新 PHP 和 Nginx 版本

## 故障排查

### 服務無法啟動
```bash
# 查看詳細日誌
docker-compose -f docker-compose.production.yml logs php-fpm
docker-compose -f docker-compose.production.yml logs nginx
```

### PHP 擴展未加載
```bash
# 檢查已加載的擴展
docker-compose -f docker-compose.production.yml exec php-fpm php -m
```

### Nginx 配置錯誤
```bash
# 測試配置語法
docker-compose -f docker-compose.production.yml exec nginx nginx -t
```

## 清理和停止

```bash
# 停止服務
docker-compose -f docker-compose.production.yml down

# 停止並清除數據
docker-compose -f docker-compose.production.yml down -v
```

## 更新依賴

使用 Alpine Linux 的優勢是鏡像大小較小，但需要定期更新以獲得最新的安全補丁。

```bash
# 重新構建所有鏡像
docker-compose -f docker-compose.production.yml build --no-cache
docker-compose -f docker-compose.production.yml up -d
```

## 常見問題

### Q: 為什麼不包含 MySQL?
A: 為了實現容器化最佳實踐，建議在生產環境使用雲端託管數據庫（如 AWS RDS、Azure Database）或獨立的數據庫服務器。

### Q: 如何使用外部 Redis?
A: 修改 PHP 應用配置，指向外部 Redis 服務器地址。

### Q: 生產環境使用哪個 PHP 版本?
A: 默認使用 PHP 8.1，可在 `.env` 中修改為其他版本。

## 支持的 PHP 版本

- PHP 8.1 (推薦，默認)
- PHP 8.0
- PHP 7.4

## 許可證

按照原項目許可證
