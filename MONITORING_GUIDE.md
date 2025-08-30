# 모니터링 및 헬스체크 가이드

이 가이드는 GitHub Actions Self-hosted Runner와 함께 구성된 모니터링 시스템의 사용법을 설명합니다.

## 📋 목차

1. [모니터링 스택 개요](#모니터링-스택-개요)
2. [빠른 시작](#빠른-시작)
3. [서비스별 가이드](#서비스별-가이드)
4. [헬스체크 시스템](#헬스체크-시스템)
5. [알림 설정](#알림-설정)
6. [대시보드 사용법](#대시보드-사용법)
7. [문제 해결](#문제-해결)

## 🏗️ 모니터링 스택 개요

### 포함된 서비스

| 서비스 | 포트 | 용도 | 접속 URL |
|--------|------|------|----------|
| **애플리케이션** | 3000 | 메인 웹 애플리케이션 | http://localhost:3000 |
| **Prometheus** | 9090 | 메트릭 수집 및 저장 | http://localhost:9090 |
| **Grafana** | 3001 | 대시보드 및 시각화 | http://localhost:3001 |
| **AlertManager** | 9093 | 알림 관리 | http://localhost:9093 |
| **Node Exporter** | 9100 | 시스템 메트릭 | http://localhost:9100 |
| **cAdvisor** | 8080 | 컨테이너 메트릭 | http://localhost:8080 |
| **Nginx** | 80/443 | 리버스 프록시 | http://localhost |

### 아키텍처 다이어그램

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Prometheus    │    │     Grafana     │
│   (Port 3000)   │◄───│   (Port 9090)   │◄───│   (Port 3001)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Node Exporter  │    │    cAdvisor     │    │  AlertManager   │
│   (Port 9100)   │    │   (Port 8080)   │    │   (Port 9093)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 빠른 시작

### 1. 모니터링 스택 시작

```bash
# 모니터링 스택 전체 시작
docker-compose -f docker-compose.monitoring.yml up -d

# 서비스 상태 확인
docker-compose -f docker-compose.monitoring.yml ps

# 로그 확인
docker-compose -f docker-compose.monitoring.yml logs -f
```

### 2. 개별 서비스 시작

```bash
# 애플리케이션만 시작
docker-compose -f docker-compose.monitoring.yml up -d app

# 모니터링 서비스만 시작
docker-compose -f docker-compose.monitoring.yml up -d prometheus grafana

# 특정 서비스 재시작
docker-compose -f docker-compose.monitoring.yml restart app
```

### 3. 헬스체크 실행

```bash
# 기본 헬스체크
./scripts/health-check.sh

# 프로덕션 환경 헬스체크
./scripts/health-check.sh docker-hello-app production

# 특정 서비스 헬스체크
./scripts/health-check.sh my-custom-app development
```

## 🔧 서비스별 가이드

### Prometheus (메트릭 수집)

#### 접속 및 기본 사용법
1. http://localhost:9090 접속
2. **Status** > **Targets**에서 수집 대상 확인
3. **Graph** 탭에서 메트릭 쿼리 실행

#### 유용한 PromQL 쿼리
```promql
# CPU 사용률
rate(cpu_usage_total[5m]) * 100

# 메모리 사용률
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# HTTP 요청 수
rate(http_requests_total[5m])

# 응답 시간
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# 컨테이너 메모리 사용량
container_memory_usage_bytes{name="docker-hello-app"}

# 디스크 사용률
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100
```

### Grafana (대시보드)

#### 초기 설정
1. http://localhost:3001 접속
2. 로그인: `admin` / `admin123`
3. 데이터소스는 자동으로 구성됨

#### 대시보드 가져오기
```bash
# 인기 대시보드 ID들
# Node Exporter Full: 1860
# Docker Container & Host Metrics: 179
# Prometheus Stats: 2
```

1. **+** > **Import** 클릭
2. 대시보드 ID 입력 또는 JSON 파일 업로드
3. 데이터소스로 "Prometheus" 선택

#### 커스텀 대시보드 생성
1. **+** > **Dashboard** 클릭
2. **Add new panel** 클릭
3. 메트릭 쿼리 입력
4. 시각화 타입 선택 (Graph, Stat, Table 등)

### AlertManager (알림 관리)

#### 알림 규칙 설정
**파일**: `monitoring/alert_rules.yml`
```yaml
groups:
  - name: application_alerts
    rules:
      - alert: ApplicationDown
        expr: up{job="docker-hello-app"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Application is down"
          description: "Application has been down for more than 1 minute"

      - alert: HighMemoryUsage
        expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 80% for more than 5 minutes"

      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total[5m]) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is above 80% for more than 5 minutes"
```

#### Slack 알림 설정
1. Slack에서 Incoming Webhook 생성
2. `monitoring/alertmanager.yml`에서 `YOUR_SLACK_WEBHOOK_URL` 교체
3. AlertManager 재시작

```bash
docker-compose -f docker-compose.monitoring.yml restart alertmanager
```

## 🏥 헬스체크 시스템

### 자동 헬스체크

#### GitHub Actions에서 자동 실행
워크플로우에 이미 포함된 헬스체크:
- HTTP 응답 확인
- 컨테이너 상태 확인
- 애플리케이션 시작 대기
- 응답 시간 측정

#### 수동 헬스체크
```bash
# 전체 헬스체크
./scripts/health-check.sh

# 특정 환경 헬스체크
./scripts/health-check.sh docker-hello-app production

# 도움말 보기
./scripts/health-check.sh --help
```

### 헬스체크 항목

1. **컨테이너 상태**: Docker 컨테이너 실행 상태
2. **HTTP 헬스**: 웹 애플리케이션 응답 확인
3. **메모리 사용량**: 컨테이너 메모리 사용률
4. **로그 분석**: 최근 에러 로그 확인
5. **디스크 사용량**: 시스템 디스크 사용률
6. **네트워크 연결**: 외부 및 내부 네트워크 연결
7. **모니터링 서비스**: Prometheus, Grafana 등 상태

### 헬스체크 결과 해석

- **Exit Code 0**: 모든 검사 통과 ✅
- **Exit Code 1**: 일부 검사 실패 ⚠️
- **Exit Code 2**: 다수 검사 실패 🚨

## 🔔 알림 설정

### 이메일 알림

1. `monitoring/alertmanager.yml` 수정:
```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'your-email@gmail.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'
```

2. Gmail App Password 생성 (2FA 필요)
3. AlertManager 재시작

### Discord 알림

```yaml
# alertmanager.yml에 추가
discord_configs:
  - webhook_url: 'YOUR_DISCORD_WEBHOOK_URL'
    title: '🚨 Alert from Monitoring'
    message: |
      {{ range .Alerts }}
      **Alert:** {{ .Annotations.summary }}
      **Description:** {{ .Annotations.description }}
      **Severity:** {{ .Labels.severity }}
      {{ end }}
```

### 커스텀 웹훅

```bash
# 간단한 웹훅 서버 예시
cat > webhook-server.py << 'EOF'
from flask import Flask, request
import json

app = Flask(__name__)

@app.route('/', methods=['POST'])
def webhook():
    data = request.get_json()
    print(f"Alert received: {json.dumps(data, indent=2)}")
    return 'OK'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
EOF

python3 webhook-server.py
```

## 📊 대시보드 사용법

### 기본 대시보드

#### 시스템 개요 대시보드
- CPU, 메모리, 디스크 사용률
- 네트워크 트래픽
- 시스템 로드

#### 애플리케이션 대시보드
- HTTP 요청 수 및 응답 시간
- 에러 비율
- 활성 연결 수

#### 컨테이너 대시보드
- 컨테이너별 리소스 사용량
- 컨테이너 상태 및 재시작 횟수
- 이미지 크기 및 레이어 정보

### 알림 규칙 커스터마이징

```yaml
# 커스텀 알림 규칙 예시
- alert: SlowResponse
  expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: "Slow response time detected"
    description: "95th percentile response time is above 1 second"

- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.1
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "High error rate detected"
    description: "Error rate is above 10%"
```

## 🛠️ 문제 해결

### 일반적인 문제

#### 1. 서비스가 시작되지 않는 경우
```bash
# 로그 확인
docker-compose -f docker-compose.monitoring.yml logs service_name

# 포트 충돌 확인
sudo netstat -tulpn | grep :9090

# 권한 문제 확인
ls -la monitoring/
sudo chown -R $USER:$USER monitoring/
```

#### 2. 메트릭이 수집되지 않는 경우
```bash
# Prometheus 타겟 상태 확인
curl http://localhost:9090/api/v1/targets

# 네트워크 연결 확인
docker network ls
docker network inspect docker-learning-project_monitoring

# 방화벽 확인
sudo ufw status
```

#### 3. Grafana 대시보드가 로드되지 않는 경우
```bash
# 데이터소스 연결 확인
curl http://localhost:3001/api/datasources

# Prometheus 연결 테스트
curl http://prometheus:9090/api/v1/query?query=up
```

#### 4. 알림이 전송되지 않는 경우
```bash
# AlertManager 설정 확인
curl http://localhost:9093/api/v1/status

# 알림 규칙 확인
curl http://localhost:9090/api/v1/rules

# SMTP 연결 테스트
telnet smtp.gmail.com 587
```

### 성능 최적화

#### 1. 메트릭 보존 기간 조정
```yaml
# prometheus.yml
global:
  scrape_interval: 30s  # 기본 15s에서 30s로 증가
  evaluation_interval: 30s

# 보존 기간 설정 (docker-compose.yml)
command:
  - '--storage.tsdb.retention.time=30d'  # 기본 15d에서 30d로 증가
```

#### 2. 리소스 제한 설정
```yaml
# docker-compose.monitoring.yml
services:
  prometheus:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
        reservations:
          memory: 512M
          cpus: '0.25'
```

### 백업 및 복구

#### 1. 설정 백업
```bash
# 모니터링 설정 백업
tar -czf monitoring-backup-$(date +%Y%m%d).tar.gz monitoring/

# Grafana 대시보드 백업
docker exec grafana grafana-cli admin export-dashboard > dashboards-backup.json
```

#### 2. 데이터 백업
```bash
# Prometheus 데이터 백업
docker run --rm -v prometheus_data:/data -v $(pwd):/backup alpine tar czf /backup/prometheus-data-$(date +%Y%m%d).tar.gz /data

# Grafana 데이터 백업
docker run --rm -v grafana_data:/data -v $(pwd):/backup alpine tar czf /backup/grafana-data-$(date +%Y%m%d).tar.gz /data
```

## 📚 추가 리소스

- [Prometheus 공식 문서](https://prometheus.io/docs/)
- [Grafana 공식 문서](https://grafana.com/docs/)
- [AlertManager 공식 문서](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [PromQL 가이드](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Docker 모니터링 모범 사례](https://docs.docker.com/config/daemon/prometheus/)

---

**참고**: 이 모니터링 시스템은 개발 및 소규모 프로덕션 환경에 적합합니다. 대규모 환경에서는 추가적인 최적화와 확장성 고려가 필요할 수 있습니다.