#!/bin/sh
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
checkitem="$0"
procCnt=`ps -A --format='%p%P%C%x%a' --width 2048 -w --sort pid|grep "$checkitem"|grep -v grep|grep -v " -c sh "|grep -v "$$" |grep -c sh|awk '{printf("%d",$1)}'`
if [[ $procCnt > 0 ]]
then
    echo "Another instance is already running!"
    exit 1
fi
#dir=$(cd $(dirname $0); pwd)
dir="$(dirname "$(readlink -f "${0}")")"

#id通过ifconfig查看
eth_id="enp7s0"
wifi_id="wlp0s20f3"

#和手机处于同一局域网的wifi名称
wifi_name="XXX"

#现有的pppoe连接名称
ppp_id="NetKeeper"

#闪讯用户名
ppp_username="13688888888@abcd.XY"

#可选择是否把username加密
#加密用到getPIN.py
#不同地区的加密参数可能不一致,请去脚本中修改
encrypt_username="true"

#wifi局域网下安卓手机的ip地址
#请将安卓手机的设为静态ip地址
phone_IP="192.168.0.5"

#对应安卓闪讯服务端,NetKeeperServer下的端口参数
phone_port="60666"

#失败重试间隔时间
retry_delay="60s"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" >> "$dir/log"
}

is_eth_avl() {
    local state=$(nmcli -g GENERAL.STATE device show "$eth_id")
    if [[ $state =~ "unavailable" ]]
    then
        echo "false"
    else
        echo "true"
    fi
}

is_wifi_avl() {
    if [[ $(nmcli -g GENERAL.CONNECTION device show "$wifi_id") == "$wifi_name" ]]
    then
        echo "true"
    else
        echo "false"
    fi
}

is_connected() {
    if [[ "$(nmcli -g GENERAL.STATE connection show "$ppp_id")" == "activated" ]]
    then
        echo "true"
    else
        echo "false"
    fi
}

get_password_local() {
    if [ ! -f "$dir/lastMsg" ]
    then
        log "local" "local lastMsg not existed"
        echo "fail"
        return
    fi
    local msg=$(cat "$dir/lastMsg" 2>/dev/null)
    local password=${msg:18:6}
    local expiration=${msg:28:19}

    if [ -z "$password" ]
    then
        log "local" "local password not found"
        echo "fail"
        return
    fi

    local timestamp_expiration=$(date -d "$expiration" +%s)
    local timestamp_now=$(date +%s)

    # echo $password
    # echo $expiration
    # echo $timestamp_expiration
    # echo $timestamp_now
    if [[ $timestamp_expiration > $timestamp_now ]]
    then
        log "local" "password: $password"
        echo "$password"
    else
        #rm -f "$dir/lastMsg"
        log "local" "local password expired"
        echo "fail"
    fi
}

get_password_phone() {
    log "phone" "sending password command"
    local msg=$(echo "password" | nc "$phone_IP" "$phone_port")
    if [[ -z "$msg" || "$msg" == "fail" ]]
    then
        log "phone" "password command failed"
        echo "fail"
    elif [[ "$msg" == "conflict" ]]
    then
        log "phone" "password command conflicted"
        echo "fail"
    else
        echo "$msg" > "$dir/lastMsg"
        log "phone" "$msg"
        local password=${msg:18:6}
        log "phone" "password: $password"
        echo "$password"
    fi
}

get_password() {
    local password=$(get_password_local)
    if [[ "$password" != "fail" ]]
    then
        echo "$password"
        return
    fi

    local password=$(get_password_phone)
    if [[ "$password" != "fail" ]]
    then
        echo "$password"
        return
    fi

    echo "fail"
}

connect() {
    log "connect" "connecting"

    local password=$(get_password)
    if [[ "$password" == "fail" ]]
    then
        log "connect" "failed to get password"
        retry
        return
    fi
    nmcli connection modify "$ppp_id" pppoe.password "$password"
    if [[ "$encrypt_username" == "true" ]]
    then
        local username=$(python3 "$dir/getPIN.py" "$ppp_username")
    else
        local username="$ppp_username"
    fi
    nmcli connection modify "$ppp_id" pppoe.username "$username"
    if nmcli connection up "$ppp_id" >/dev/null 2>&1 # will reconnect if connected
    then
        log "connect" "connected"
    else
        #rm -f "$dir/lastMsg"
        log "connect" "failed to connect"
        retry
    fi
}

retry() {
    log "retry" "retry in $retry_delay"
    sleep "$retry_delay"
    judge
}

judge() {
    if [[ "$eth_avl" == "true" &&
        "$wifi_avl" == "true" &&
        "$(is_connected)" == "false" ]]
    then
        local job=$(jobs)
        if [[ ! $job || "$job" =~ "Done" ]]
        then
            connect &
        fi
    else
        local job=$(jobs)
        if [[ $job && "$job" =~ "Running" ]]
        then
            log "judge" "kill job"
            # $! indicates the PID of the recently created background process
            kill -15 $!
        fi
    fi
}

main() {
    nmcli device monitor | while read line
    do
        if [[ ! "$line" =~ "connected" ]] # matches "connected" & "disconnected"
        then
            continue
        fi
        case "$line" in
            $eth_id:*)
                eth_avl=$(is_eth_avl)
                #echo "eth_avl:$eth_avl"
                judge
            ;;
            $wifi_id:*)
                wifi_avl=$(is_wifi_avl)
                #echo "wifi_avl:$wifi_avl"
                judge
            ;;
        esac
    done
    #log "main" "nmcli stopped unexpectedly!"
}

trap "pkill -P $$; log 'main' 'exit'; exit 0" Exit
eth_avl=$(is_eth_avl)
wifi_avl=$(is_wifi_avl)

if [[ $# > 0 ]]
then
  log "main" "force connecting once"
  connect
  exit 0
fi

log "main" "start running"
judge
# The background process here is not the same as that in main.
# In the tunnel, the background process is isolated.
# So wait for it to finish.
wait

main
