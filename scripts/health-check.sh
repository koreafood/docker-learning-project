#!/bin/bash

# 헬스체크 및 모니터링 스크립트
# 사용법: ./health-check.sh [service_name] [environment]

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 기본 설정
SERVICE_NAME=${1:-"docker-hello-app"}
ENVIRONMENT=${2:-"development"}
HEALTH_CHECK_TIMEOUT=30
RETRY_COUNT=3
RETRY_DELAY=5

# 환경별 포트 설정
case $ENVIRONMENT in
    "development")
        APP_PORT=3000
        APP_URL="http://localhost:3000"
        ;;
    "production")
        APP_PORT=8080
        APP_URL="http://localhost:8080"
        ;;
    *)
        log_error "Unknown environment: $ENVIRONMENT"
        exit 1
        ;;
esac

log_info "Starting health check for $SERVICE_NAME in $ENVIRONMENT environment..."

# Docker 컨테이너 상태 확인
check_container_status() {
    log_info "Checking container status..."
    
    if docker ps --filter "name=$SERVICE_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "$SERVICE_NAME"; then
        log_success "Container $SERVICE_NAME is running"
        docker ps --filter "name=$SERVICE_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        return 0
    else
        log_error "Container $SERVICE_NAME is not running"
        return 1
    fi
}

# HTTP 헬스체크
check_http_health() {
    log_info "Checking HTTP health at $APP_URL..."
    
    for i in $(seq 1 $RETRY_COUNT); do
        if curl -f -s --max-time $HEALTH_CHECK_TIMEOUT "$APP_URL" > /dev/null; then
            log_success "HTTP health check passed (attempt $i/$RETRY_COUNT)"
            
            # 응답 시간 측정
            response_time=$(curl -o /dev/null -s -w "%{time_total}" "$APP_URL")
            log_info "Response time: ${response_time}s"
            
            # HTTP 상태 코드 확인
            status_code=$(curl -o /dev/null -s -w "%{http_code}" "$APP_URL")
            log_info "HTTP status code: $status_code"
            
            return 0
        else
            log_warning "HTTP health check failed (attempt $i/$RETRY_COUNT)"
            if [ $i -lt $RETRY_COUNT ]; then
                log_info "Retrying in ${RETRY_DELAY}s..."
                sleep $RETRY_DELAY
            fi
        fi
    done
    
    log_error "HTTP health check failed after $RETRY_COUNT attempts"
    return 1
}

# 메모리 사용량 확인
check_memory_usage() {
    log_info "Checking memory usage..."
    
    if docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep -q "$SERVICE_NAME"; then
        memory_info=$(docker stats --no-stream --format "{{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep "$SERVICE_NAME")
        log_success "Memory usage: $memory_info"
        
        # 메모리 사용률 추출 및 경고
        memory_percent=$(echo "$memory_info" | awk '{print $4}' | sed 's/%//')
        if (( $(echo "$memory_percent > 80" | bc -l) )); then
            log_warning "High memory usage detected: ${memory_percent}%"
        fi
        
        return 0
    else
        log_error "Could not retrieve memory usage for $SERVICE_NAME"
        return 1
    fi
}

# 로그 확인
check_logs() {
    log_info "Checking recent logs..."
    
    if docker logs --tail 10 "$SERVICE_NAME" 2>/dev/null; then
        log_success "Recent logs retrieved successfully"
        
        # 에러 로그 확인
        error_count=$(docker logs --since 5m "$SERVICE_NAME" 2>&1 | grep -i "error\|exception\|fail" | wc -l)
        if [ "$error_count" -gt 0 ]; then
            log_warning "Found $error_count error(s) in recent logs"
        else
            log_success "No errors found in recent logs"
        fi
        
        return 0
    else
        log_error "Could not retrieve logs for $SERVICE_NAME"
        return 1
    fi
}

# 디스크 사용량 확인
check_disk_usage() {
    log_info "Checking disk usage..."
    
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    log_info "Disk usage: ${disk_usage}%"
    
    if [ "$disk_usage" -gt 90 ]; then
        log_error "Critical disk usage: ${disk_usage}%"
        return 1
    elif [ "$disk_usage" -gt 80 ]; then
        log_warning "High disk usage: ${disk_usage}%"
    else
        log_success "Disk usage is normal: ${disk_usage}%"
    fi
    
    return 0
}

# 네트워크 연결 확인
check_network_connectivity() {
    log_info "Checking network connectivity..."
    
    # 외부 연결 확인
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        log_success "External network connectivity OK"
    else
        log_warning "External network connectivity issue"
    fi
    
    # Docker 네트워크 확인
    if docker network ls | grep -q "monitoring"; then
        log_success "Docker monitoring network exists"
    else
        log_warning "Docker monitoring network not found"
    fi
    
    return 0
}

# 모니터링 서비스 확인
check_monitoring_services() {
    log_info "Checking monitoring services..."
    
    local services=("prometheus" "grafana" "alertmanager")
    local all_healthy=true
    
    for service in "${services[@]}"; do
        if docker ps --filter "name=$service" --format "{{.Names}}" | grep -q "$service"; then
            log_success "$service is running"
        else
            log_warning "$service is not running"
            all_healthy=false
        fi
    done
    
    if $all_healthy; then
        log_success "All monitoring services are healthy"
        return 0
    else
        log_warning "Some monitoring services are not running"
        return 1
    fi
}

# 전체 헬스체크 실행
run_health_check() {
    local checks_passed=0
    local total_checks=7
    
    echo "\n🏥 Health Check Report for $SERVICE_NAME ($ENVIRONMENT)"
    echo "================================================"
    
    # 각 체크 실행
    check_container_status && ((checks_passed++))
    echo
    
    check_http_health && ((checks_passed++))
    echo
    
    check_memory_usage && ((checks_passed++))
    echo
    
    check_logs && ((checks_passed++))
    echo
    
    check_disk_usage && ((checks_passed++))
    echo
    
    check_network_connectivity && ((checks_passed++))
    echo
    
    check_monitoring_services && ((checks_passed++))
    echo
    
    # 결과 요약
    echo "📊 Health Check Summary"
    echo "======================"
    echo "Checks passed: $checks_passed/$total_checks"
    
    if [ $checks_passed -eq $total_checks ]; then
        log_success "All health checks passed! 🎉"
        exit 0
    elif [ $checks_passed -ge $((total_checks * 2 / 3)) ]; then
        log_warning "Most health checks passed, but some issues detected ⚠️"
        exit 1
    else
        log_error "Multiple health check failures detected! 🚨"
        exit 2
    fi
}

# 도움말 표시
show_help() {
    echo "Usage: $0 [service_name] [environment]"
    echo ""
    echo "Arguments:"
    echo "  service_name    Name of the Docker container (default: docker-hello-app)"
    echo "  environment     Environment (development|production) (default: development)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Check default service in development"
    echo "  $0 docker-hello-app production       # Check service in production"
    echo "  $0 my-app development                # Check custom service in development"
    echo ""
    echo "Exit codes:"
    echo "  0 - All checks passed"
    echo "  1 - Some checks failed"
    echo "  2 - Multiple critical failures"
}

# 메인 실행
case "${1:-}" in
    "-h"|"--help")
        show_help
        exit 0
        ;;
    *)
        run_health_check
        ;;
esac