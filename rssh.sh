#!/bin/bash

# ========================================
# 설정 값 (여기를 수정하세요)
# ========================================
SERVER_USER="root"
SERVER_IP="hylink.kr"
REMOTE_PORT="2222"
LOCAL_USER="root"
# ========================================

# 에러 발생 시 스크립트 중단
set -e

# 출력 억제
exec 3>&1 1>/dev/null 2>&1

# root 권한 확인
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Root required" >&3
        exit 1
    fi
}

# autossh 설치
install_autossh() {
    apt update
    apt install -y autossh
}

# autossh 설치 확인
check_autossh() {
    if command -v autossh &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# PermitRootLogin을 yes로 변경
enable_root_login() {
    SSHD_CONFIG="/etc/ssh/sshd_config"
    
    # PermitRootLogin 설정이 있는지 확인하고 변경
    if grep -q "^PermitRootLogin" "$SSHD_CONFIG"; then
        sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' "$SSHD_CONFIG"
    elif grep -q "^#PermitRootLogin" "$SSHD_CONFIG"; then
        sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' "$SSHD_CONFIG"
    else
        echo "PermitRootLogin yes" >> "$SSHD_CONFIG"
    fi
    
    # sshd 재시작
    systemctl restart sshd || systemctl restart ssh
}

# SSH 설정 파일 생성
create_ssh_config() {
    LOCAL_USER_HOME=$(eval echo ~$LOCAL_USER)
    SSH_DIR="$LOCAL_USER_HOME/.ssh"
    SSH_CONFIG="$SSH_DIR/config"
    
    mkdir -p "$SSH_DIR"
    chown $LOCAL_USER:$LOCAL_USER "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    
    cat >> "$SSH_CONFIG" << EOF

# Reverse SSH Tunnel Configuration
Host reverse-tunnel
    HostName $SERVER_IP
    User $SERVER_USER
    ServerAliveInterval 30
    ServerAliveCountMax 3
    ExitOnForwardFailure yes
EOF
    
    chown $LOCAL_USER:$LOCAL_USER "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
}

# systemd 서비스 파일 생성
create_systemd_service() {
    SERVICE_FILE="/etc/systemd/system/reverse-ssh-tunnel.service"
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Reverse SSH Tunnel
After=network.target

[Service]
Type=simple
User=$LOCAL_USER
ExecStart=/usr/bin/autossh -M 0 -N -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -R $REMOTE_PORT:localhost:22 $SERVER_USER@$SERVER_IP
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
}

# 메인 실행
main() {
    check_root
    
    if ! check_autossh; then
        install_autossh
    fi
    
    enable_root_login
    create_ssh_config
    create_systemd_service
    
    systemctl enable reverse-ssh-tunnel
    systemctl start reverse-ssh-tunnel
    
    # 성공 여부 확인
    if systemctl is-active --quiet reverse-ssh-tunnel; then
        echo "SUCCESS" >&3
        exit 0
    else
        echo "FAILED" >&3
        exit 1
    fi
}

# 스크립트 실행
main
