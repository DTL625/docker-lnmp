#!/bin/bash

# ==============================================
# MUSI Production Health Check
# 生產環境健康檢查腳本
# ==============================================

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 計數器
passed=0
failed=0
warnings=0

# 輸出函數
pass() {
    echo -e "${GREEN}✓ PASS${NC} $1"
    ((passed++))
}

fail() {
    echo -e "${RED}✗ FAIL${NC} $1"
    ((failed++))
}

warn() {
    echo -e "${YELLOW}⚠ WARN${NC} $1"
    ((warnings++))
}

info() {
    echo -e "${BLUE}ℹ INFO${NC} $1"
}

# ==============================================
# 容器健康檢查
# ==============================================

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}容器健康檢查${NC}"
echo -e "${BLUE}========================================${NC}"

# 檢查 PHP-FPM 容器
if docker-compose -f docker-compose.production.yml ps | grep -q "php-fpm.*Up"; then
    pass "PHP-FPM 容器運行中"
else
    fail "PHP-FPM 容器未運行"
fi

# 檢查 Nginx 容器
if docker-compose -f docker-compose.production.yml ps | grep -q "nginx.*Up"; then
    pass "Nginx 容器運行中"
else
    fail "Nginx 容器未運行"
fi

# ==============================================
# PHP-FPM 檢查
# ==============================================

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}PHP-FPM 檢查${NC}"
echo -e "${BLUE}========================================${NC}"

# PHP 版本
php_version=$(docker-compose -f docker-compose.production.yml exec -T php-fpm php -v 2>/dev/null | head -1)
if [ $? -eq 0 ]; then
    pass "PHP-FPM 響應正常"
    info "版本: $php_version"
else
    fail "PHP-FPM 無法訪問"
fi

# 檢查必要的擴展
required_extensions=("pdo_mysql" "mysqli" "mbstring" "gd" "curl" "opcache")
echo ""
for ext in "${required_extensions[@]}"; do
    if docker-compose -f docker-compose.production.yml exec -T php-fpm php -m | grep -q "$ext"; then
        pass "擴展已安裝: $ext"
    else
        fail "擴展缺失: $ext"
    fi
done

# 檢查不應該在生產環境的擴展
debug_extensions=("xdebug")
echo ""
for ext in "${debug_extensions[@]}"; do
    if docker-compose -f docker-compose.production.yml exec -T php-fpm php -m | grep -q "$ext"; then
        warn "調試擴展已加載: $ext (不應在生產環境中)"
    else
        pass "調試擴展未加載: $ext (正確)"
    fi
done

# 檢查 OPCache
echo ""
opcache=$(docker-compose -f docker-compose.production.yml exec -T php-fpm php -i | grep "opcache.enable")
if [ -n "$opcache" ]; then
    pass "OPCache 已啟用"
    info "配置: $opcache"
else
    warn "OPCache 可能未啟用"
fi

# ==============================================
# Nginx 檢查
# ==============================================

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Nginx 檢查${NC}"
echo -e "${BLUE}========================================${NC}"

# Nginx 版本
nginx_version=$(docker-compose -f docker-compose.production.yml exec -T nginx nginx -v 2>&1)
if [ $? -eq 0 ]; then
    pass "Nginx 響應正常"
    info "版本: $nginx_version"
else
    fail "Nginx 無法訪問"
fi

# 測試配置語法
if docker-compose -f docker-compose.production.yml exec -T nginx nginx -t >/dev/null 2>&1; then
    pass "Nginx 配置語法正確"
else
    fail "Nginx 配置語法錯誤"
fi

# 檢查監聽端口
echo ""
if docker-compose -f docker-compose.production.yml exec -T nginx netstat -tlnp 2>/dev/null | grep -q ":80 "; then
    pass "Nginx 監聽 80 端口"
else
    warn "Nginx 未監聽 80 端口"
fi

if docker-compose -f docker-compose.production.yml exec -T nginx netstat -tlnp 2>/dev/null | grep -q ":443 "; then
    pass "Nginx 監聽 443 端口"
else
    warn "Nginx 未監聽 443 端口 (HTTPS)"
fi

# ==============================================
# 進程和資源檢查
# ==============================================

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}進程和資源檢查${NC}"
echo -e "${BLUE}========================================${NC}"

# 檢查 PHP-FPM 進程數
php_process_count=$(docker-compose -f docker-compose.production.yml exec -T php-fpm ps aux | grep -c "php-fpm")
if [ "$php_process_count" -gt 1 ]; then
    pass "PHP-FPM 工作進程正在運行"
    info "進程數: $php_process_count"
else
    warn "PHP-FPM 進程數異常"
fi

# 監控 Docker 資源使用
echo ""
info "Docker 資源使用情況:"
docker stats --no-stream --format "{{.Container}}: CPU={{.CPUPerc}} Memory={{.MemUsage}}/{{.MemLimit}}" 2>/dev/null || warn "無法獲取資源信息"

# ==============================================
# 日誌檢查
# ==============================================

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}日誌檢查${NC}"
echo -e "${BLUE}========================================${NC}"

# 檢查日誌文件
log_files=(
    "logs/php-fpm/error.log"
    "logs/nginx/error.log"
)

for log_file in "${log_files[@]}"; do
    if [ -f "$log_file" ]; then
        pass "日誌文件存在: $log_file"

        # 檢查最近的錯誤
        errors=$(tail -20 "$log_file" | grep -c "error" || true)
        if [ "$errors" -gt 0 ]; then
            warn "在 $log_file 中檢測到 $errors 個錯誤"
        fi
    else
        warn "日誌文件缺失: $log_file"
    fi
done

# ==============================================
# 連接性檢查
# ==============================================

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}連接性檢查${NC}"
echo -e "${BLUE}========================================${NC}"

# PHP-FPM 到 Nginx
if docker-compose -f docker-compose.production.yml exec -T php-fpm ping -c 1 nginx >/dev/null 2>&1; then
    pass "PHP-FPM 可以訪問 Nginx"
else
    warn "PHP-FPM 無法訪問 Nginx"
fi

# Nginx 到 PHP-FPM
if docker-compose -f docker-compose.production.yml exec -T nginx bash -c "echo '' | nc -w 1 php-fpm 9000 2>/dev/null"; then
    pass "Nginx 可以連接 PHP-FPM"
else
    warn "Nginx 無法連接 PHP-FPM"
fi

# ==============================================
# 應用檢查
# ==============================================

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}應用檢查${NC}"
echo -e "${BLUE}========================================${NC}"

# 健康檢查端點
health_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null || echo "000")
if [ "$health_response" = "200" ]; then
    pass "健康檢查端點響應正常 (HTTP $health_response)"
elif [ "$health_response" != "000" ]; then
    warn "健康檢查端點返回 HTTP $health_response"
else
    warn "無法訪問健康檢查端點"
fi

# 主應用檢查
app_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
if [ "$app_response" = "200" ] || [ "$app_response" = "301" ] || [ "$app_response" = "302" ]; then
    pass "應用可訪問 (HTTP $app_response)"
elif [ "$app_response" = "404" ]; then
    warn "應用返回 404 (檢查應用是否正確配置)"
elif [ "$app_response" != "000" ]; then
    warn "應用返回 HTTP $app_response"
else
    warn "無法訪問應用"
fi

# ==============================================
# 生成報告
# ==============================================

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}健康檢查報告${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "通過: $passed"
echo "失敗: $failed"
echo "警告: $warnings"
echo ""

if [ "$failed" -eq 0 ]; then
    if [ "$warnings" -eq 0 ]; then
        echo -e "${GREEN}✓ 所有檢查通過！系統正常。${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠ 系統運行正常，但有 $warnings 個警告。${NC}"
        exit 0
    fi
else
    echo -e "${RED}✗ 有 $failed 個檢查失敗。請檢查上述輸出。${NC}"
    exit 1
fi
