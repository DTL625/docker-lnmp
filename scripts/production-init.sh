#!/bin/bash

# ==============================================
# MUSI Production Environment Initialization
# 生產環境初始化腳本
# ==============================================

set -e

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 輸出函數
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ==============================================
# 預檢檢查
# ==============================================

info "開始生產環境初始化檢查..."

# 檢查 Docker
if ! command -v docker &> /dev/null; then
    error "Docker 未安裝"
    exit 1
fi
info "Docker 已安裝: $(docker --version)"

# 檢查 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose 未安裝"
    exit 1
fi
info "Docker Compose 已安裝: $(docker-compose --version)"

# 檢查 .env 文件
if [ ! -f ".env" ]; then
    error ".env 文件不存在"
    error "請先執行: cp .env.production .env"
    exit 1
fi
info ".env 文件已找到"

# ==============================================
# 創建必要的目錄
# ==============================================

info "創建必要的目錄..."

directories=(
    "logs/php-fpm"
    "logs/nginx"
    "data/composer"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        info "已創建目錄: $dir"
    else
        info "目錄已存在: $dir"
    fi
done

# ==============================================
# 設置目錄權限
# ==============================================

info "設置目錄權限..."

chmod -R 775 logs data
chown -R 1000:1000 logs data 2>/dev/null || warn "無法更改目錄所有者 (可能需要 sudo)"

# ==============================================
# 檢查配置文件
# ==============================================

info "檢查配置文件..."

config_files=(
    "services/php-fpm/php.ini"
    "services/php-fpm/php-fpm.conf"
    "services/nginx/nginx.conf"
    "services/nginx/fastcgi-php.conf"
)

for config in "${config_files[@]}"; do
    if [ ! -f "$config" ]; then
        error "配置文件缺失: $config"
        exit 1
    fi
    info "配置文件已找到: $config"
done

# ==============================================
# 構建 Docker 鏡像
# ==============================================

info "構建 Docker 鏡像..."
info "這可能需要幾分鐘..."

if docker-compose -f docker-compose.production.yml build; then
    info "Docker 鏡像構建成功"
else
    error "Docker 鏡像構建失敗"
    exit 1
fi

# ==============================================
# 啟動服務
# ==============================================

info "啟動 Docker 服務..."

if docker-compose -f docker-compose.production.yml up -d; then
    info "服務啟動成功"
else
    error "服務啟動失敗"
    exit 1
fi

# ==============================================
# 等待服務啟動
# ==============================================

info "等待服務啟動..."
sleep 5

# ==============================================
# 驗證服務狀態
# ==============================================

info "驗證服務狀態..."

# 檢查容器狀態
if docker-compose -f docker-compose.production.yml ps | grep -q "Up"; then
    info "所有容器已啟動"
else
    error "某些容器未啟動"
    docker-compose -f docker-compose.production.yml ps
    exit 1
fi

# ==============================================
# 檢查 PHP-FPM
# ==============================================

info "檢查 PHP-FPM..."

php_version=$(docker-compose -f docker-compose.production.yml exec -T php-fpm php -v | head -1)
info "PHP 版本: $php_version"

php_extensions=$(docker-compose -f docker-compose.production.yml exec -T php-fpm php -m)
if echo "$php_extensions" | grep -q "redis"; then
    info "Redis 擴展已加載"
else
    warn "Redis 擴展未加載"
fi

if echo "$php_extensions" | grep -q "xdebug"; then
    warn "XDebug 已加載 (不應在生產環境中加載)"
else
    info "XDebug 未加載 (正確)"
fi

# ==============================================
# 檢查 Nginx
# ==============================================

info "檢查 Nginx..."

nginx_version=$(docker-compose -f docker-compose.production.yml exec -T nginx nginx -v 2>&1)
info "Nginx 版本: $nginx_version"

# 測試 Nginx 配置
if docker-compose -f docker-compose.production.yml exec -T nginx nginx -t; then
    info "Nginx 配置測試通過"
else
    error "Nginx 配置測試失敗"
    exit 1
fi

# ==============================================
# 檢查網絡連接
# ==============================================

info "檢查網絡連接..."

if docker-compose -f docker-compose.production.yml exec -T php-fpm ping -c 1 nginx > /dev/null 2>&1; then
    info "PHP-FPM 可以訪問 Nginx"
else
    warn "PHP-FPM 無法訪問 Nginx"
fi

# ==============================================
# 創建虛擬主機配置
# ==============================================

if [ ! -f "services/nginx/conf.d/musi.conf" ]; then
    info "創建 Nginx 虛擬主機配置..."
    cp services/nginx/conf.d/production/musi.conf.example \
       services/nginx/conf.d/musi.conf
    info "已創建: services/nginx/conf.d/musi.conf"
    info "請編輯此文件並配置您的域名"
    warn "編輯後需要重啟 Nginx: docker-compose -f docker-compose.production.yml restart nginx"
fi

# ==============================================
# 總結
# ==============================================

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}生產環境初始化完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "下一步:"
echo "1. 編輯 services/nginx/conf.d/musi.conf - 配置您的域名"
echo "2. 編輯 .env - 根據需要調整環境變數"
echo "3. 編輯 services/php-fpm/php.ini - 根據需要優化 PHP 配置"
echo "4. 編輯 services/php-fpm/php-fpm.conf - 根據需要優化 PHP-FPM 配置"
echo ""
echo "常用命令:"
echo "  查看服務狀態:    docker-compose -f docker-compose.production.yml ps"
echo "  查看日誌:        docker-compose -f docker-compose.production.yml logs -f"
echo "  進入 PHP 容器:   docker-compose -f docker-compose.production.yml exec php-fpm bash"
echo "  重啟服務:        docker-compose -f docker-compose.production.yml restart"
echo "  停止服務:        docker-compose -f docker-compose.production.yml down"
echo ""
echo "詳細信息請查看 PRODUCTION.md 和 DEPLOYMENT_GUIDE.md"
echo ""
