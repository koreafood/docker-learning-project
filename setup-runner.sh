#!/bin/bash

# GitHub Actions Self-hosted Runner 설정 스크립트
# 사용법: ./setup-runner.sh <GITHUB_TOKEN> <REPO_URL>

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

# 파라미터 확인
if [ $# -ne 2 ]; then
    log_error "사용법: $0 <GITHUB_TOKEN> <REPO_URL>"
    log_info "예시: $0 ghp_xxxxxxxxxxxx https://github.com/username/repo"
    exit 1
fi

GITHUB_TOKEN="$1"
REPO_URL="$2"
RUNNER_NAME="docker-learning-runner-$(hostname)"
RUNNER_WORK_DIR="$HOME/actions-runner"

log_info "GitHub Actions Self-hosted Runner 설정을 시작합니다..."

# 시스템 업데이트 및 필수 패키지 설치
log_info "시스템 패키지 업데이트 중..."
sudo apt-get update
sudo apt-get install -y curl jq git

# Docker 설치 확인
if ! command -v docker &> /dev/null; then
    log_warning "Docker가 설치되어 있지 않습니다. Docker를 설치합니다..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    log_success "Docker 설치 완료"
else
    log_success "Docker가 이미 설치되어 있습니다."
fi

# Node.js 설치 확인
if ! command -v node &> /dev/null; then
    log_warning "Node.js가 설치되어 있지 않습니다. Node.js를 설치합니다..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    log_success "Node.js 설치 완료"
else
    log_success "Node.js가 이미 설치되어 있습니다. 버전: $(node --version)"
fi

# Runner 디렉토리 생성
log_info "Runner 디렉토리 생성 중..."
mkdir -p "$RUNNER_WORK_DIR"
cd "$RUNNER_WORK_DIR"

# 최신 Runner 다운로드
log_info "GitHub Actions Runner 다운로드 중..."
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/v//')
RUNNER_FILE="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"

if [ ! -f "$RUNNER_FILE" ]; then
    curl -o "$RUNNER_FILE" -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_FILE}"
    tar xzf "$RUNNER_FILE"
    log_success "Runner 다운로드 및 압축 해제 완료"
else
    log_info "Runner 파일이 이미 존재합니다."
fi

# Repository에서 Runner 토큰 가져오기
log_info "Runner 등록 토큰 가져오는 중..."
REPO_OWNER=$(echo "$REPO_URL" | sed 's|https://github.com/||' | cut -d'/' -f1)
REPO_NAME=$(echo "$REPO_URL" | sed 's|https://github.com/||' | cut -d'/' -f2)

REGISTRATION_TOKEN=$(curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runners/registration-token" | jq -r '.token')

if [ "$REGISTRATION_TOKEN" = "null" ] || [ -z "$REGISTRATION_TOKEN" ]; then
    log_error "등록 토큰을 가져올 수 없습니다. GitHub 토큰과 저장소 권한을 확인하세요."
    exit 1
fi

# Runner 구성
log_info "Runner 구성 중..."
./config.sh --url "$REPO_URL" --token "$REGISTRATION_TOKEN" --name "$RUNNER_NAME" --work "_work" --unattended

# Systemd 서비스 생성
log_info "Systemd 서비스 생성 중..."
sudo ./svc.sh install
sudo ./svc.sh start

log_success "GitHub Actions Self-hosted Runner 설정이 완료되었습니다!"
log_info "Runner 이름: $RUNNER_NAME"
log_info "작업 디렉토리: $RUNNER_WORK_DIR"
log_info "서비스 상태 확인: sudo ./svc.sh status"
log_info "서비스 중지: sudo ./svc.sh stop"
log_info "서비스 제거: sudo ./svc.sh uninstall"

echo
log_info "GitHub 저장소의 Settings > Actions > Runners에서 Runner가 등록되었는지 확인하세요."
log_warning "주의: 이 스크립트 실행 후 터미널을 재시작하거나 'newgrp docker' 명령을 실행하여 Docker 그룹 권한을 활성화하세요."