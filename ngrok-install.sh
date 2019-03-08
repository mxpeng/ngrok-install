#!/bin/bash

# 获取当前脚本执行路径
SELF_PATH=$(cd `dirname $0`;pwd)

# 服务器配置文件路径
CONFIG_FILE_PATH="/etc/ngrok/ngrok-server"

# 验证文件路径
SECRET_FILE_PATH="/etc/ngrok/ngrok-secrets"

# 配置文件夹路径
CONFIF_DIR_PATH="/etc/ngrok"

# 安装文件夹路径
INSTALL_DIR_PATH="/usr/local/ngrok"

# 安装父文件夹路径
INSTALL_PARENT_DIR_PATH="/usr/local"

# 安装依赖
install_dependency() {
    yum -y install git gcc golang zip unzip wget mercurial
}

# 安装ngrok
install_ngrok() {

    # 已经安装就先卸载
    if [[ -d ${INSTALL_DIR_PATH} ]]; then
        uninstall_ngrok
    fi

    # 没有配置文件夹就先创建
    if [[ ! -d ${CONFIF_DIR_PATH} ]]; then
        mkdir -p ${CONFIF_DIR_PATH}
    fi

    echo "请输入用于穿透的域名 例如（xxx.mxpeng.com）"
    ngrok_domain=""
    while true; do
        read ngrok_domain
        if [[ -n ${ngrok_domain} ]]; then
            break
        else
            echo "输入错误，请重新输入用于穿透的域名 例如（xxx.mxpeng.com）"
        fi
    done
    echo "ngrok_domain=$ngrok_domain" >> ${CONFIG_FILE_PATH}

    echo "请输入服务端口（默认 4443）"
    read ngrok_server_port
    if [[ -z ${ngrok_server_port} ]]; then
        ngrok_server_port=4443;
    fi
    echo "ngrok_server_port=:$ngrok_server_port" >> ${CONFIG_FILE_PATH}

    echo "请输入用于穿透的http端口（默认 80）"
    read ngrok_http_port
    if [[ -z ${ngrok_http_port} ]]; then
        ngrok_http_port=80;
    fi
    echo "ngrok_http_port=:$ngrok_http_port" >> ${CONFIG_FILE_PATH}

    echo "请输入用于穿透的https端口（默认 443）"
    read ngrok_https_port
    if [[ -z ${ngrok_https_port} ]]; then
        ngrok_https_port=443;
    fi
    echo "ngrok_https_port=:$ngrok_https_port" >> ${CONFIG_FILE_PATH}

    echo "请输入用于穿透的用户名（默认 usr）"
    read ngrok_username
    if [[ -z ${ngrok_username} ]]; then
        ngrok_username="usr";
    fi

    echo "请输入用于穿透的密码（默认 pwd）"
    read ngrok_password
    if [[ -z ${ngrok_password} ]]; then
        ngrok_password="pwd";
    fi
    echo "$ngrok_username $ngrok_password" >> ${SECRET_FILE_PATH}

    # 客户端配置文件初始
    cp ${SELF_PATH}/client/ngrok-cli.yml ${CONFIF_DIR_PATH}/
    echo "server_addr: $ngrok_domain:$ngrok_server_port" >> ${CONFIF_DIR_PATH}/ngrok-cli.yml
    echo "trust_host_root_certs: false" >> ${CONFIF_DIR_PATH}/ngrok-cli.yml
    echo "auth_token: $ngrok_username:$ngrok_password" >> ${CONFIF_DIR_PATH}/ngrok-cli.yml

    # 安装依赖
    install_dependency

    # 防火墙端口打开
    if [[ -f /usr/bin/firewall-cmd ]]; then
        firewall_status=`firewall-cmd --state`
        if [[ firewall_status='running' ]]; then
            firewall-cmd --zone=public --add-port=${ngrok_server_port}/tcp --permanent
            firewall-cmd --zone=public --add-port=${ngrok_http_port}/tcp --permanent
            firewall-cmd --zone=public --add-port=${ngrok_https_port}/tcp --permanent
            firewall-cmd --reload
        fi
    fi

    cd ${INSTALL_PARENT_DIR_PATH}

    # 原版
    # git clone https://github.com/inconshreveable/ngrok.git

    # 带加密版本
    git clone https://github.com/prikevs/ngrok.git

    # 库引用的错误解决
    # sed -i 's#code.google.com/p/log4go#github.com/keepeye/log4go#' ${INSTALL_DIR_PATH}/src/ngrok/log/logger.go

    # 证书目录
    if [[ ! -d ${INSTALL_DIR_PATH}/cer ]]; then
        mkdir ${INSTALL_DIR_PATH}/cer
    fi

    cd ${INSTALL_DIR_PATH}/cer

    # 证书生成
    openssl genrsa -out rootCA.key 2048
    openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=${ngrok_domain}" -days 5000 -out rootCA.pem
    openssl genrsa -out server.key 2048
    openssl req -new -key server.key -subj "/CN=${ngrok_domain}" -out server.csr
    openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.crt -days 5000

    cp -f rootCA.pem ${INSTALL_DIR_PATH}/assets/client/tls/ngrokroot.crt
    cp -f server.crt ${INSTALL_DIR_PATH}/assets/server/tls/snakeoil.crt
    cp -f server.key ${INSTALL_DIR_PATH}/assets/server/tls/snakeoil.key

    # 到达编译目录
    cd ${INSTALL_DIR_PATH}

    # 获取当前环境
    goos=`go env | grep GOOS | awk -F\" '{print $2}'`
    goarch=`go env | grep GOARCH | awk -F\" '{print $2}'`

    # 编译服务端
    GOOS=${goos} GOARCH=${goarch} make release-server

    # 将启动加入服务
    chmod 754 ${SELF_PATH}/server/ngrok.service
    chmod 754 ${SELF_PATH}/server/start.sh
    cp -f ${SELF_PATH}/server/start.sh ${INSTALL_DIR_PATH}
    cp -f ${SELF_PATH}/server/ngrok.service /lib/systemd/system

    # 开机启动
    systemctl enable ngrok.service

    compile_client linux 386
    compile_client linux amd64
    compile_client windows 386
    compile_client windows amd64
    compile_client darwin 386
    compile_client darwin amd64
    compile_client linux arm

}

# 卸载ngrok
uninstall_ngrok() {
    rm -rf ${INSTALL_DIR_PATH}
    rm -rf ${CONFIF_DIR_PATH}
    systemctl disable ngrok.service
    rm -rf /lib/systemd/system/ngrok.service
}

# 生成客户端-编译客户端
compile_client() {
    # 删除客户端
    if [[ -f ${INSTALL_DIR_PATH}/ngrok_client_$1_$2.zip ]]; then
        rm -rf ${INSTALL_DIR_PATH}/ngrok_client_$1_$2.zip
    fi

    # 删除客户端
    if [[ -d ${INSTALL_DIR_PATH}/bin/$1_$2 ]]; then
        rm -rf ${INSTALL_DIR_PATH}/bin/$1_$2
    fi

    # 到达编译目录
    cd ${INSTALL_DIR_PATH}

    # 获取当前环境
    goos=`go env | grep GOOS | awk -F\" '{print $2}'`
    goarch=`go env | grep GOARCH | awk -F\" '{print $2}'`

    # 构建客户端
    GOOS=$1 GOARCH=$2 make release-client

    if [[ $1 = ${goos} && $2 = ${goarch} && -f ${INSTALL_DIR_PATH}/bin/ngrok ]]; then
        mkdir -p ${INSTALL_DIR_PATH}/bin/$1_$2 && cp ${INSTALL_DIR_PATH}/bin/ngrok ${INSTALL_DIR_PATH}/bin/$1_$2/
    fi

    # 客户端配置文件复制
    cp -f ${CONFIF_DIR_PATH}/ngrok-cli.yml ${INSTALL_DIR_PATH}/bin/$1_$2/

    # 启动文件复制
    if [[ $1 = "windows" ]]; then
        cp -f ${SELF_PATH}/client/windows/start.bat ${INSTALL_DIR_PATH}/bin/$1_$2
    else
        cp -f ${SELF_PATH}/client/linux/start.sh ${INSTALL_DIR_PATH}/bin/$1_$2
    fi

    # 压缩
    cd ${INSTALL_DIR_PATH}/bin/$1_$2 && zip -r ${INSTALL_DIR_PATH}/ngrok_client_$1_$2.zip *

    echo "请在 $INSTALL_DIR_PATH 目录下载客户端文件 ngrok_client_$1_$2.zip"
}

# 生成客户端-选择版本
choose_client() {
    echo "1、Linux 32位"
    echo "2、Linux 64位"
    echo "3、Windows 32位"
    echo "4、Windows 64位"
    echo "5、Mac OS 32位"
    echo "6、Mac OS 64位"
    echo "7、Linux ARM"

    read num
    case "$num" in
        [1])
            compile_client linux 386
        ;;
        [2])
            compile_client linux amd64
        ;;
        [3])
            compile_client windows 386
        ;;
        [4])
            compile_client windows amd64
        ;;
        [5])
            compile_client darwin 386
        ;;
        [6])
            compile_client darwin amd64
        ;;
        [7])
            compile_client linux arm
        ;;
        *) echo "选择错误，退出" ;;
    esac
}

echo "请输入下面数字进行选择"
echo "------------------------"
echo "1、安装ngrok服务端"
echo "2、生成ngrok客户端"
echo "3、卸载ngrok"
echo "------------------------"
read num
case "$num" in
    [1])
        install_ngrok
    ;;
    [2])
        choose_client
    ;;
    [3])
        uninstall_ngrok
    ;;
    *) echo "选择错误，退出" ;;
esac
