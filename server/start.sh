#!/bin/bash

# 日期
NOW_DATE=$(date +%Y%m%d)

# 当前路径
SELF_PATH=$(cd `dirname $0`;pwd)

# pid文件名
PID_FILE_PATH="$SELF_PATH/.ngrok.pid"

# 配置文件路径
CONFIG_FILE_PATH="/etc/ngrok/ngrok-server"

# 验证文件路径
SECRET_FILE_PATH="/etc/ngrok/ngrok-secrets"

# 日志文件地址
LOG_PATH="/var/log/ngrok"


DOMAIN=`cat ${CONFIG_FILE_PATH} | grep "ngrok_domain" | awk -F\= '{print $2}'`
SERVER_PORT=`cat ${CONFIG_FILE_PATH} | grep "ngrok_server_port" | awk -F\= '{print $2}'`
PORT_HTTP=`cat ${CONFIG_FILE_PATH} | grep "ngrok_http_port" | awk -F\= '{print $2}'`
PORT_HTTPS=`cat ${CONFIG_FILE_PATH} | grep "ngrok_https_port" | awk -F\= '{print $2}'`

command="/usr/local/ngrok/bin/ngrokd -domain=$DOMAIN -httpAddr=$PORT_HTTP -httpsAddr=$PORT_HTTPS -tunnelAddr=$SERVER_PORT -secretPath=$SECRET_FILE_PATH"

start() {
    if [[ ! -d ${LOG_PATH} ]]; then
        mkdir ${LOG_PATH}
        chmod -R 754 ${LOG_PATH}
    fi

    log_file_url="$LOG_PATH/ngrok_$NOW_DATE.log"

    if [[ ${log_file_url} != "" ]]; then
        nohup ${command} > ${log_file_url} 2>&1 &
        echo $! > ${PID_FILE_PATH}
    else
        nohup ${command} 2>&1 &
        echo $! > ${PID_FILE_PATH}
    fi

    echo "start ngrok success"
}

stop() {
    if [[ -f ${PID_FILE_PATH} ]]; then
        echo "ready to kill service"
        kill -9 `cat ${PID_FILE_PATH}`
        rm -rf ${PID_FILE_PATH}
        echo "service has bean killed"
    fi

    sleep 1s

    ps -ef | grep "$command" | awk '{print $2}' | while read pid
    do
        c_pid=`ps --no-heading ${pid} | wc -l`

        echo "current PID=$pid,C_PID=${c_pid}"

        if [[ "${c_pid}" == "1" ]]; then
            echo "PID=$pid ready to kill service"
            kill -9 ${pid}
            echo "PID=$pid service has bean killed"
        else
            echo "process not exists or stop success."
        fi
    done
}


case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart)
        stop
        sleep 1s
        start
    ;;
    *)
        stop
        sleep 1s
        start
    ;;
esac
