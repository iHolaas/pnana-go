#!/bin/bash
export UUID=${UUID:-'98ea05d0-fae8-40e4-b7eb-aba3ffd0ba17'}
export NEZHA_SERVER=${NEZHA_SERVER:-'nz.abcd.com'}
export NEZHA_PORT=${NEZHA_PORT:-'5555'}   # 哪吒端口为{443,8443,2096,2087,2083,2053}其中之一时开启tls
export NEZHA_KEY=${NEZHA_KEY:-''}        # 哪吒三个变量不全不运行
export ARGO_DOMAIN=${ARGO_DOMAIN:-'pnana.vls.dedyn.io'}
export ARGO_AUTH=${ARGO_AUTH:-'eyJhIjoiNTM3MmNmNGYzODE0ZjM5MDA2NGE2ZjI3YjYyYTg5N2QiLCJ0IjoiOTA2OTQxNmQtYTkwMC00ZTA5LTg3NWEtMTdkOTZmNThmN2FmIiwicyI6IlpUQXhZak16TldRdFpHSmtPUzAwWVdRMkxXRXhZall0WlRRNU5HRXpOREkwWWpsayJ9'}
export NAME=${NAME:-'nana'}
export CFIP=${CFIP:-'ip.sb'}
export FILE_PATH=${FILE_PATH:-'./temp'}
export ARGO_PORT=${ARGO_PORT:-'8001'}  # argo隧道端口，若使用固定隧道token请改回8080或CF后台改为与这里对应

if [ ! -d "${FILE_PATH}" ]; then
    mkdir ${FILE_PATH}
fi

cleanup_oldfiles() {
  rm -rf ${FILE_PATH}/boot.log ${FILE_PATH}/sub.txt ${FILE_PATH}/config.json ${FILE_PATH}/tunnel.json ${FILE_PATH}/tunnel.yml
}
cleanup_oldfiles
sleep 2

generate_config() {
  cat > ${FILE_PATH}/config.json << EOF
{
  "log": { "access": "/dev/null", "error": "/dev/null", "loglevel": "none" },
  "inbounds": [
    {
      "port": $ARGO_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "${UUID}", "flow": "xtls-rprx-vision" }],
        "decryption": "none",
        "fallbacks": [
          { "dest": 3001 }, { "path": "/vless", "dest": 3002 },
          { "path": "/vmess", "dest": 3003 }, { "path": "/trojan", "dest": 3004 }
        ]
      },
      "streamSettings": { "network": "tcp" }
    },
    {
      "port": 3001, "listen": "127.0.0.1", "protocol": "vless",
      "settings": { "clients": [{ "id": "${UUID}" }], "decryption": "none" },
      "streamSettings": { "network": "ws", "security": "none" }
    },
    {
      "port": 3002, "listen": "127.0.0.1", "protocol": "vless",
      "settings": { "clients": [{ "id": "${UUID}", "level": 0 }], "decryption": "none" },
      "streamSettings": { "network": "ws", "security": "none", "wsSettings": { "path": "/vless" } },
      "sniffing": { "enabled": true, "destOverride": ["http", "tls", "quic"], "metadataOnly": false }
    },
    {
      "port": 3003, "listen": "127.0.0.1", "protocol": "vmess",
      "settings": { "clients": [{ "id": "${UUID}", "alterId": 0 }] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } },
      "sniffing": { "enabled": true, "destOverride": ["http", "tls", "quic"], "metadataOnly": false }
    },
    {
      "port": 3004, "listen": "127.0.0.1", "protocol": "trojan",
      "settings": { "clients": [{ "password": "${UUID}" }] },
      "streamSettings": { "network": "ws", "security": "none", "wsSettings": { "path": "/trojan" } },
      "sniffing": { "enabled": true, "destOverride": ["http", "tls", "quic"], "metadataOnly": false }
    }
  ],
  "dns": { "servers": ["https+local://8.8.8.8/dns-query"] },
  "outbounds": [
    { "protocol": "freedom" },
    {
      "tag": "WARP", "protocol": "wireguard",
      "settings": {
        "secretKey": "YFYOAdbw1bKTHlNNi+aEjBM3BO7unuFC5rOkMRAz9XY=",
        "address": ["172.16.0.2/32", "2606:4700:110:8a36:df92:102a:9602:fa18/128"],
        "peers": [{ "publicKey": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=", "allowedIPs": ["0.0.0.0/0", "::/0"], "endpoint": "162.159.193.10:2408" }],
        "reserved": [78, 135, 76], "mtu": 1280
      }
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [{ "type": "field", "domain": ["domain:openai.com", "domain:ai.com"], "outboundTag": "WARP" }]
  }
}
EOF
}
generate_config
sleep 2

ARCH=$(uname -m) && DOWNLOAD_DIR="${FILE_PATH}" && mkdir -p "$DOWNLOAD_DIR" && declare -a FILE_INFO 
if [ "$ARCH" == "arm" ] || [ "$ARCH" == "arm64" ]|| [ "$ARCH" == "aarch64" ]; then
    FILE_INFO=("https://github.com/eooce/test/releases/download/arm64/bot13 bot" "https://github.com/eooce/test/releases/download/ARM/web web" "https://github.com/eooce/test/releases/download/ARM/swith npm")
elif [ "$ARCH" == "amd64" ] || [ "$ARCH" == "x86_64" ] || [ "$ARCH" == "x86" ]; then
    FILE_INFO=("https://github.com/eooce/test/releases/download/amd64/bot13 bot" "https://github.com/eooce/test/releases/download/123/web web" "https://github.com/eooce/test/releases/download/bulid/swith npm")
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi
for entry in "${FILE_INFO[@]}"; do
    URL=$(echo "$entry" | cut -d ' ' -f 1)
    NEW_FILENAME=$(echo "$entry" | cut -d ' ' -f 2)
    FILENAME="$DOWNLOAD_DIR/$NEW_FILENAME"
    curl -L -sS -o "$FILENAME" "$URL"
    # echo -e "\e[1;32mDownloading $FILENAME\e[0m"
done
wait
for entry in "${FILE_INFO[@]}"; do
    NEW_FILENAME=$(echo "$entry" | cut -d ' ' -f 2)
    FILENAME="$DOWNLOAD_DIR/$NEW_FILENAME"
    chmod +x "$FILENAME"
    # echo -e "\e[1;32m$FILENAME permission successfully\e[0m"
done

argo_configure() {
  if [[ -z $ARGO_AUTH || -z $ARGO_DOMAIN ]]; then
    echo -e "\e[1;32m1\e[0m"
    return
  fi

  if [[ $ARGO_AUTH =~ TunnelSecret ]]; then
    echo $ARGO_AUTH > ${FILE_PATH}/tunnel.json
    cat > ${FILE_PATH}/tunnel.yml << EOF
tunnel: $(cut -d\" -f12 <<< "$ARGO_AUTH")
credentials-file: ${FILE_PATH}/tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost:$ARGO_PORT
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
  else
    echo -e "\e[1;32mARGO_AUTH mismatch TunnelSecret,use token connect to tunnel\e[0m"
  fi
}
argo_configure
sleep 2

run() {
  if [ -e ${FILE_PATH}/npm ]; then
    chmod 777 ${FILE_PATH}/npm 
    tlsPorts=("443" "8443" "2096" "2087" "2083" "2053")
    if [[ "${tlsPorts[*]}" =~ "${NEZHA_PORT}" ]]; then
      NEZHA_TLS="--tls"
    else
      NEZHA_TLS=""
    fi
    if [ -n "$NEZHA_SERVER" ] && [ -n "$NEZHA_PORT" ] && [ -n "$NEZHA_KEY" ]; then
        nohup ${FILE_PATH}/npm -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_TLS} >/dev/null 2>&1 &
		    sleep 1
        pgrep -x "npm" > /dev/null && echo -e "\e[1;32m\e[0m"0 || { echo -e "\e[1;35m1\e[0m"; pkill -x "npm" && nohup ${FILE_PATH}/npm -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_TLS} >/dev/null 2>&1 & sleep 2; echo -e "\e[1;32m5\e[0m"; }
    else
        echo -e "\e[1;35m2\e[0m"
    fi
  fi

  if [ -e ${FILE_PATH}/web ]; then
    chmod 777 ${FILE_PATH}/web
    nohup ${FILE_PATH}/web -c ${FILE_PATH}/config.json >/dev/null 2>&1 &
	  sleep 2
    pgrep -x "web" > /dev/null && echo -e "\e[1;32m4\e[0m" || { echo "1"; pkill -x "web" && nohup ${FILE_PATH}/web -c ${FILE_PATH}/config.json >/dev/null 2>&1 & sleep 2; echo -e "\e[1;32m3\e[0m"; }
  fi

  if [ -e ${FILE_PATH}/bot ]; then
    chmod 777 ${FILE_PATH}/bot
    if [[ $ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
    args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token ${ARGO_AUTH}"
    elif [[ $ARGO_AUTH =~ TunnelSecret ]]; then
    args="tunnel --edge-ip-version auto --config ${FILE_PATH}/tunnel.yml run"
    else
    args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile ${FILE_PATH}/boot.log --loglevel info --url http://localhost:$ARGO_PORT"
    fi
    nohup ${FILE_PATH}/bot $args >/dev/null 2>&1 &
    pgrep -x "bot" > /dev/null && echo -e "\e[1;32m7\e[0m" || { echo -e "\e[1;35m9\e[0m"; pkill -x "bot" && nohup ${FILE_PATH}/bot $args >/dev/null 2>&1 & sleep 2; echo -e "\e[1;32m6\e[0m"; }
	  sleep 3
  fi
} 
run
sleep 3

function get_argodomain() {
  if [[ -n $ARGO_AUTH ]]; then
    echo "$ARGO_DOMAIN"
  else
    cat ${FILE_PATH}/boot.log | grep trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}'
  fi
}

generate_links() {
  argodomain=$(get_argodomain)
  # echo -e "\e[1;32mArgodomain:\e[1;35m${argodomain}\e[0m"
  sleep 2

  isp=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')
  sleep 2

  VMESS="{ \"v\": \"2\", \"ps\": \"${NAME}-${isp}\", \"add\": \"${CFIP}\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${argodomain}\", \"path\": \"/vmess?ed=2048\", \"tls\": \"tls\", \"sni\": \"${argodomain}\", \"alpn\": \"\" }"

  cat > ${FILE_PATH}/list.txt <<EOF
vless://${UUID}@${CFIP}:443?encryption=none&security=tls&sni=${argodomain}&type=ws&host=${argodomain}&path=%2Fvless?ed=2048#${NAME}-${isp}

vmess://$(echo "$VMESS" | base64 -w0)

trojan://${UUID}@${CFIP}:443?security=tls&sni=${argodomain}&type=ws&host=${argodomain}&path=%2Ftrojan?ed=2048#${NAME}-${isp}
EOF

  base64 -w0 ${FILE_PATH}/list.txt > ${FILE_PATH}/sub.txt
  # echo -e "\n\e[1;32m${FILE_PATH}/successfully\e[0m"
  sleep 8  
  rm -rf ${FILE_PATH}/list.txt ${FILE_PATH}/boot.log ${FILE_PATH}/config.json ${FILE_PATH}/tunnel.json ${FILE_PATH}/tunnel.yml
}
generate_links
sleep 15
clear

# echo -e "\e[1;32mserver is running\e[0m"
# echo -e "\e[1;32mThank you for using this script,enjoy!\e[0m"
