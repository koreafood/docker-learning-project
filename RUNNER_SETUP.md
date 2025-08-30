# GitHub Actions Self-hosted Runner 설정 가이드

이 가이드는 현재 프로젝트에 GitHub Actions Self-hosted Runner를 설정하는 방법을 설명합니다.

## 📋 사전 요구사항

- Ubuntu/Debian 기반 Linux 시스템
- sudo 권한
- GitHub Personal Access Token (repo 권한 필요)
- 인터넷 연결

## 🚀 빠른 설정

### 1. GitHub Personal Access Token 생성

1. GitHub에 로그인
2. Settings > Developer settings > Personal access tokens > Tokens (classic)
3. "Generate new token" 클릭
4. 다음 권한 선택:
   - `repo` (전체 저장소 접근)
   - `workflow` (워크플로우 관리)
5. 토큰 복사 및 안전한 곳에 보관

### 2. 자동 설정 스크립트 실행

```bash
# 스크립트 실행
./setup-runner.sh <YOUR_GITHUB_TOKEN> <YOUR_REPO_URL>

# 예시
./setup-runner.sh ghp_xxxxxxxxxxxx https://github.com/username/docker-learning-project
```

### 3. 설정 확인

```bash
# Runner 서비스 상태 확인
cd ~/actions-runner
sudo ./svc.sh status

# GitHub 저장소에서 확인
# Settings > Actions > Runners에서 새로운 Runner 확인
```

## 🔧 수동 설정 (고급 사용자)

### 1. 시스템 준비

```bash
# 시스템 업데이트
sudo apt-get update
sudo apt-get install -y curl jq git

# Docker 설치 (필요한 경우)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Node.js 설치 (필요한 경우)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 2. Runner 다운로드 및 설정

```bash
# Runner 디렉토리 생성
mkdir -p ~/actions-runner && cd ~/actions-runner

# 최신 Runner 다운로드
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/v//')
curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# 압축 해제
tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
```

### 3. Runner 등록

```bash
# GitHub에서 등록 토큰 가져오기
# (GitHub Settings > Actions > Runners > New self-hosted runner에서 토큰 확인)

# Runner 구성
./config.sh --url https://github.com/username/repo --token <REGISTRATION_TOKEN>

# 서비스로 설치
sudo ./svc.sh install
sudo ./svc.sh start
```

## 🛠️ Runner 관리 명령어

```bash
# Runner 디렉토리로 이동
cd ~/actions-runner

# 서비스 상태 확인
sudo ./svc.sh status

# 서비스 시작
sudo ./svc.sh start

# 서비스 중지
sudo ./svc.sh stop

# 서비스 재시작
sudo ./svc.sh stop && sudo ./svc.sh start

# 서비스 제거
sudo ./svc.sh uninstall

# Runner 등록 해제
./config.sh remove --token <REMOVAL_TOKEN>
```

## 🔍 문제 해결

### Runner가 오프라인 상태인 경우

```bash
# 서비스 상태 확인
sudo ./svc.sh status

# 로그 확인
sudo journalctl -u actions.runner.* -f

# 서비스 재시작
sudo ./svc.sh stop
sudo ./svc.sh start
```

### Docker 권한 문제

```bash
# 현재 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER

# 그룹 권한 활성화
newgrp docker

# 또는 시스템 재부팅
sudo reboot
```

### 네트워크 연결 문제

```bash
# GitHub 연결 테스트
curl -I https://github.com

# DNS 설정 확인
nslookup github.com

# 방화벽 설정 확인
sudo ufw status
```

## 📊 모니터링

### Runner 상태 모니터링

```bash
# 실시간 로그 확인
sudo journalctl -u actions.runner.* -f

# 시스템 리소스 확인
htop
df -h
free -h
```

### GitHub에서 확인

1. 저장소 > Settings > Actions > Runners
2. Runner 상태 및 마지막 활동 시간 확인
3. 실행 중인 작업 확인

## 🔒 보안 고려사항

- GitHub Token은 안전한 곳에 보관
- Runner는 신뢰할 수 있는 네트워크에서만 실행
- 정기적인 시스템 업데이트 수행
- Runner 로그 정기적으로 확인
- 불필요한 Runner는 즉시 제거

## 📝 추가 정보

- [GitHub Actions Self-hosted Runners 공식 문서](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Runner 보안 가이드](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners#self-hosted-runner-security)
- [Docker 공식 문서](https://docs.docker.com/)

---

**주의**: Self-hosted Runner는 보안에 민감한 환경에서 사용할 때 주의가 필요합니다. 공개 저장소에서는 사용을 권장하지 않습니다.