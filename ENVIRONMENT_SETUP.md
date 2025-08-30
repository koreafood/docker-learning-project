# 환경 변수 및 시크릿 설정 가이드

이 가이드는 GitHub Actions Self-hosted Runner와 함께 사용할 환경 변수 및 시크릿 설정 방법을 설명합니다.

## 📋 목차

1. [GitHub Secrets 설정](#github-secrets-설정)
2. [환경별 변수 설정](#환경별-변수-설정)
3. [Runner 환경 변수](#runner-환경-변수)
4. [보안 고려사항](#보안-고려사항)
5. [문제 해결](#문제-해결)

## 🔐 GitHub Secrets 설정

### Repository Secrets

1. GitHub 저장소로 이동
2. **Settings** > **Secrets and variables** > **Actions** 클릭
3. **New repository secret** 클릭
4. 다음 시크릿들을 추가:

#### 필수 Secrets

```bash
# Docker Registry 관련 (선택사항)
DOCKER_REGISTRY_URL=localhost:5000
DOCKER_REGISTRY_USERNAME=admin
DOCKER_REGISTRY_PASSWORD=your_password

# 알림 관련 (선택사항)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...

# 데이터베이스 관련 (필요한 경우)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp
DB_USERNAME=dbuser
DB_PASSWORD=secure_password

# API 키 (필요한 경우)
API_SECRET_KEY=your_api_secret_key
JWT_SECRET=your_jwt_secret
```

### Environment Secrets

각 환경별로 다른 시크릿을 설정할 수 있습니다:

#### Development Environment
```bash
DEV_DB_HOST=dev-db.example.com
DEV_API_URL=https://dev-api.example.com
DEV_DEBUG_MODE=true
```

#### Production Environment
```bash
PROD_DB_HOST=prod-db.example.com
PROD_API_URL=https://api.example.com
PROD_DEBUG_MODE=false
```

## 🌍 환경별 변수 설정

### 1. Development 환경

**파일**: `.env.development`
```bash
# Development Environment Variables
NODE_ENV=development
PORT=3000
DEBUG=true
LOG_LEVEL=debug

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp_dev

# External APIs
API_BASE_URL=https://dev-api.example.com
API_TIMEOUT=30000

# Features
ENABLE_FEATURE_X=true
ENABLE_ANALYTICS=false
```

### 2. Production 환경

**파일**: `.env.production`
```bash
# Production Environment Variables
NODE_ENV=production
PORT=3000
DEBUG=false
LOG_LEVEL=info

# Database
DB_HOST=${PROD_DB_HOST}
DB_PORT=5432
DB_NAME=myapp_prod

# External APIs
API_BASE_URL=https://api.example.com
API_TIMEOUT=10000

# Features
ENABLE_FEATURE_X=true
ENABLE_ANALYTICS=true

# Security
SESSION_SECRET=${JWT_SECRET}
API_KEY=${API_SECRET_KEY}
```

### 3. 환경 파일 생성 스크립트

**파일**: `scripts/setup-env.sh`
```bash
#!/bin/bash

# 환경 설정 스크립트
ENVIRONMENT=${1:-development}

echo "Setting up environment: $ENVIRONMENT"

case $ENVIRONMENT in
  "development")
    cp .env.development .env
    echo "Development environment configured"
    ;;
  "production")
    cp .env.production .env
    echo "Production environment configured"
    ;;
  *)
    echo "Unknown environment: $ENVIRONMENT"
    echo "Available environments: development, production"
    exit 1
    ;;
esac

echo "Environment setup complete!"
```

## 🏃‍♂️ Runner 환경 변수

### Runner 시스템 환경 변수

Self-hosted Runner에서 사용할 시스템 환경 변수를 설정합니다:

```bash
# ~/.bashrc 또는 ~/.profile에 추가
export DOCKER_HOST=unix:///var/run/docker.sock
export COMPOSE_PROJECT_NAME=docker-learning-project
export NODE_ENV=production
export CI=true

# 경로 설정
export PATH=$PATH:/usr/local/bin:/opt/node/bin

# 메모리 및 성능 설정
export NODE_OPTIONS="--max-old-space-size=4096"
export UV_THREADPOOL_SIZE=128
```

### Runner 서비스 환경 변수

**파일**: `/etc/systemd/system/actions.runner.*.service`에 추가

```ini
[Service]
Environment="NODE_ENV=production"
Environment="DOCKER_HOST=unix:///var/run/docker.sock"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
```

## 🔒 보안 고려사항

### 1. 시크릿 관리 원칙

- ✅ **DO**: GitHub Secrets 사용
- ✅ **DO**: 환경별로 다른 시크릿 사용
- ✅ **DO**: 정기적인 시크릿 로테이션
- ❌ **DON'T**: 코드에 하드코딩
- ❌ **DON'T**: 로그에 시크릿 출력
- ❌ **DON'T**: 공개 저장소에 시크릿 커밋

### 2. 환경 파일 보안

```bash
# .gitignore에 추가
.env
.env.local
.env.*.local
*.key
*.pem
secrets/
```

### 3. 런타임 시크릿 검증

**파일**: `scripts/validate-secrets.js`
```javascript
// 필수 환경 변수 검증
const requiredEnvVars = {
  development: ['NODE_ENV', 'PORT'],
  production: ['NODE_ENV', 'PORT', 'DB_HOST', 'API_SECRET_KEY']
};

const environment = process.env.NODE_ENV || 'development';
const required = requiredEnvVars[environment] || [];

const missing = required.filter(envVar => !process.env[envVar]);

if (missing.length > 0) {
  console.error('❌ Missing required environment variables:');
  missing.forEach(envVar => console.error(`   - ${envVar}`));
  process.exit(1);
}

console.log('✅ All required environment variables are set');
```

## 🔧 워크플로우에서 환경 변수 사용

### GitHub Actions 워크플로우 예시

```yaml
# .github/workflows/ci-cd.yml에서 사용
env:
  NODE_ENV: ${{ github.ref == 'refs/heads/main' && 'production' || 'development' }}
  API_URL: ${{ secrets.API_URL }}
  
jobs:
  deploy:
    runs-on: self-hosted
    environment: ${{ github.ref == 'refs/heads/main' && 'production' || 'development' }}
    steps:
      - name: Set environment variables
        run: |
          echo "NODE_ENV=${{ env.NODE_ENV }}" >> $GITHUB_ENV
          echo "PORT=${{ env.NODE_ENV == 'production' && '8080' || '3000' }}" >> $GITHUB_ENV
          
      - name: Deploy with environment
        run: |
          docker run -d \
            --name myapp-${{ env.NODE_ENV }} \
            -e NODE_ENV=${{ env.NODE_ENV }} \
            -e PORT=${{ env.PORT }} \
            -e API_SECRET_KEY=${{ secrets.API_SECRET_KEY }} \
            -p ${{ env.PORT }}:${{ env.PORT }} \
            myapp:latest
```

## 🛠️ 문제 해결

### 1. 환경 변수가 로드되지 않는 경우

```bash
# 환경 변수 확인
echo $NODE_ENV
env | grep NODE_ENV

# 프로세스 환경 변수 확인
ps aux | grep node
cat /proc/$(pgrep node)/environ | tr '\0' '\n' | grep NODE_ENV
```

### 2. Docker 컨테이너 환경 변수 확인

```bash
# 실행 중인 컨테이너 환경 변수 확인
docker exec container_name env

# 컨테이너 실행 시 환경 변수 확인
docker inspect container_name | jq '.[0].Config.Env'
```

### 3. GitHub Actions 환경 변수 디버깅

```yaml
# 워크플로우에서 환경 변수 출력 (보안 주의)
- name: Debug environment
  run: |
    echo "NODE_ENV: $NODE_ENV"
    echo "GITHUB_REF: $GITHUB_REF"
    echo "GITHUB_EVENT_NAME: $GITHUB_EVENT_NAME"
    # 시크릿은 출력하지 마세요!
```

### 4. 시크릿 접근 권한 문제

1. Repository 권한 확인
2. Environment 보호 규칙 확인
3. Branch 보호 규칙 확인
4. Runner 그룹 권한 확인

## 📚 추가 리소스

- [GitHub Actions Secrets 문서](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Environment Variables 모범 사례](https://12factor.net/config)
- [Docker Environment Variables](https://docs.docker.com/engine/reference/run/#env-environment-variables)
- [Node.js Environment Variables](https://nodejs.org/api/process.html#process_process_env)

---

**보안 알림**: 이 가이드의 예시 값들은 실제 프로덕션 환경에서 사용하지 마세요. 항상 강력하고 고유한 값을 생성하여 사용하세요.