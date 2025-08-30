# 🐳 Docker 학습 프로젝트 with GitHub Actions CI/CD

Docker와 GitHub Actions를 활용한 완전한 CI/CD 파이프라인을 학습하기 위한 단계별 프로젝트입니다. 기본적인 컨테이너 실행부터 시작하여 점진적으로 복잡도를 높여가는 방식으로 구성되어 있습니다.

## 📚 학습 단계

### 1단계: 기본 Docker 컨테이너 실행 ✅
- Hello World 예제
- 기본 Docker 명령어 학습

### 2단계: 간단한 웹 애플리케이션 Dockerfile 작성 및 빌드 ✅
- Node.js Express 애플리케이션
- Dockerfile 작성 및 이미지 빌드
- 컨테이너 실행

### 3단계: 포트 매핑과 환경 변수 설정 ✅
- 다양한 포트 매핑 방법
- 환경 변수 설정
- 백그라운드 실행 및 컨테이너 관리

### 4단계: 볼륨 마운트를 통한 데이터 영속성 ✅
- 로컬 디렉토리 마운트
- 명명된 볼륨 사용
- 데이터 영속성 관리

### 5단계: 네트워크 설정 및 컨테이너 간 통신 ✅
- 사용자 정의 네트워크 생성
- 컨테이너 간 통신
- 네트워크 격리

### 6단계: Docker Compose를 활용한 멀티 컨테이너 애플리케이션 ✅
- docker-compose.yml 작성
- 멀티 컨테이너 오케스트레이션
- Redis와 웹 애플리케이션 연동

### 7단계: GitHub Actions CI/CD 파이프라인 구축 🆕
- GitHub Actions 워크플로우 작성
- Self-hosted Runner 설정
- 자동 빌드, 테스트, 배포
- 다중 환경 배포 (개발/프로덕션)

### 8단계: 모니터링 및 로깅 시스템 구축 🆕
- Prometheus 메트릭 수집
- Grafana 대시보드 구성
- AlertManager 알림 설정
- 자동 헬스체크 시스템

## 🚀 빠른 시작

### 필수 조건
- Docker 설치
- Node.js (로컬 개발용, 선택사항)

### 1. 저장소 클론
```bash
git clone https://github.com/koreafood/docker-learning-project.git
cd docker-learning-project
```

### 2. Docker 이미지 빌드
```bash
docker build -t my-hello-app .
```

### 3. 컨테이너 실행
```bash
docker run -p 3000:3000 my-hello-app
```

### 4. 브라우저에서 확인
`http://localhost:3000`에 접속하여 애플리케이션 확인

## 🐳 Docker Compose 사용

```bash
# 모든 서비스 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f

# 서비스 중지
docker-compose down
```

## 📖 주요 명령어

### Docker 기본 명령어
```bash
# 이미지 빌드
docker build -t <이미지명> .

# 컨테이너 실행
docker run -p <호스트포트>:<컨테이너포트> <이미지명>

# 백그라운드 실행
docker run -d -p <포트> --name <컨테이너명> <이미지명>

# 실행 중인 컨테이너 확인
docker ps

# 컨테이너 중지
docker stop <컨테이너명>

# 컨테이너 제거
docker rm <컨테이너명>
```

### 환경 변수 설정
```bash
# 단일 환경 변수
docker run -p 3000:3000 -e NODE_ENV=production my-hello-app

# 여러 환경 변수
docker run -p 3000:3000 -e NODE_ENV=production -e PORT=3000 my-hello-app

# 환경 변수 파일 사용
docker run -p 3000:3000 --env-file .env my-hello-app
```

## 🔧 프로젝트 구조

```
docker-learning-project/
├── app.js                           # Express 웹 애플리케이션
├── test.js                          # 테스트 파일
├── package.json                     # Node.js 의존성 및 스크립트
├── Dockerfile                       # Docker 이미지 빌드 설정
├── docker-compose.yml               # 기본 Docker Compose 설정
├── docker-compose.monitoring.yml    # 모니터링 스택 포함 설정
├── setup-runner.sh                  # Self-hosted Runner 설정 스크립트
├── .github/workflows/
│   └── ci-cd.yml                   # GitHub Actions 워크플로우
├── monitoring/                      # 모니터링 설정 파일들
│   ├── prometheus.yml
│   ├── alertmanager.yml
│   └── grafana/
├── scripts/
│   └── health-check.sh             # 헬스체크 스크립트
├── RUNNER_SETUP.md                 # Runner 설정 가이드
├── ENVIRONMENT_SETUP.md            # 환경 변수 설정 가이드
├── MONITORING_GUIDE.md             # 모니터링 가이드
└── README.md                       # 프로젝트 문서
```

## 🌐 접속 URL

| 서비스 | URL | 설명 |
|--------|-----|------|
| **메인 앱** | http://localhost:3000 | 웹 애플리케이션 |
| **Grafana** | http://localhost:3001 | 모니터링 대시보드 (admin/admin123) |
| **Prometheus** | http://localhost:9090 | 메트릭 수집기 |
| **AlertManager** | http://localhost:9093 | 알림 관리 |
| **cAdvisor** | http://localhost:8080 | 컨테이너 메트릭 |

## 🎯 학습 목표

이 프로젝트를 통해 다음을 학습할 수 있습니다:

### Docker 기초
1. **Docker 기초**: 컨테이너와 이미지의 개념
2. **Dockerfile 작성**: 효율적인 이미지 빌드 방법
3. **포트 매핑**: 네트워크 설정 및 외부 접근
4. **환경 변수**: 설정 관리 및 환경별 배포
5. **볼륨 마운트**: 데이터 영속성 및 개발 워크플로우
6. **네트워킹**: 컨테이너 간 통신
7. **Docker Compose**: 멀티 컨테이너 애플리케이션 관리

### CI/CD 파이프라인
8. **GitHub Actions**: 워크플로우 작성 및 자동화
9. **Self-hosted Runner**: 자체 호스팅 러너 구성
10. **자동 배포**: 다중 환경 자동 배포
11. **보안 스캔**: Trivy를 활용한 취약점 검사
12. **헬스체크**: 배포 후 자동 상태 확인

### 모니터링 및 운영
13. **Prometheus**: 메트릭 수집 및 관리
14. **Grafana**: 시각화 대시보드 구성
15. **AlertManager**: 알림 시스템 설정
16. **로그 분석**: 컨테이너 로그 모니터링
17. **성능 최적화**: 리소스 사용량 분석

## 📖 추가 문서

- [Self-hosted Runner 설정 가이드](RUNNER_SETUP.md)
- [환경 변수 설정 가이드](ENVIRONMENT_SETUP.md)
- [모니터링 시스템 가이드](MONITORING_GUIDE.md)

## 🤝 기여하기

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

이 프로젝트는 Docker 학습을 위한 교육 목적으로 만들어졌습니다. 개선 사항이나 추가 예제가 있다면 언제든 기여해주세요!

## 📝 라이선스

MIT License

---

**참고**: 이 프로젝트는 학습 목적으로 제작되었습니다. 프로덕션 환경에서 사용할 때는 보안 설정을 강화하고 추가적인 최적화를 고려하세요.