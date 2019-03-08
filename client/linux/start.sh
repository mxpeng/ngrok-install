#!/bin/bash

# 日期
NOW_DATE=$(date +%Y%m%d)

# 当前路径
SELF_PATH=$(cd `dirname $0`;pwd)

# 日志路径
LOG_PATH="$SELF_PATH/log/"

# pid文件名
PID_FILE_PATH="$SELF_PATH/.ngrok-cli.pid"



command="$SELF_PATH/ngrok -log=$SELF_PATH/log/ngrok-cli-$NOW_DATE.log -config=$SELF_PATH/ngrok-cli.yml start-all"

start() {
    # 没有日志文件夹就先创建
    if [[ ! -d ${LOG_PATH} ]]; then
        mkdir -p ${LOG_PATH}
    fi

    nohup ${command} &
    echo $! > ${PID_FILE_PATH}

    echo "start ngrok-cli success"
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
