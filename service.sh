#!/bin/bash

####
# A program start/stop/status control script
# Author: yoojiachen@gmail.com
####

## 修改以下配置

# 运行程序文件名或者路径
PROGRAM_BIN="./next-flow_linux_amd64_v0.2-preview.bin"
# 运行程序的名称
PROGRAM_NAME="NextFlowService"
# 运行程序参数
PROGRAM_ARGS="-c config.toml -l"
# 日志输出文件
LOG_OUTPUT="next-flow-logging.log"

################################

# Colors
readonly C_RED=31
readonly C_YELLOW=33
readonly C_BLUE=34

# printc ${C_BLUE} "service is" "RUNNING"
function printc()
{
	color=$1
	msg_prefix=$2
	msg_colored=$3
	msg_postfix=$4
	echo -e "= $msg_prefix \033[${color}m$msg_colored\033[0m $msg_postfix"
}

# 检查运行程序文件
function check_program()
{
	if [[ -e $PROGRAM_BIN ]];
	then
		printc $C_YELLOW "Executing program:" $PROGRAM_BIN
	else
		printc $C_RED "Program file not exits, file:" $PROGRAM_BIN
		exit 1
	fi
}

# 查找服务的进程ID
psid=0
function getpsid()
{
	psid=$(pgrep -f $PROGRAM_BIN)
}

# 启动服务进程
function daemon_start()
{
	getpsid

	if [[ $psid -ne 0 ]]; then
		printc $C_RED "$PROGRAM_NAME is" "[RUUUUUUUUNNING]" "..."
	else
		check_program
		printc $C_YELLOW "$PROGRAM_NAME is" "starting" "..."
		sh -c "nohup $PROGRAM_BIN $PROGRAM_ARGS >$LOG_OUTPUT 2>&1 &"
		# check if success
		getpsid

		if [[ $psid -ne 0 ]]; then
			printc $C_BLUE "Start: " "[SUCCESS] (program-pid=$psid)"
		else
			printc $C_RED "Start:" "[FAAAAAAAAILED]"
		fi
	fi
}

# 停止
function daemon_stop()
{
	getpsid

	if [[ $psid -ne 0 ]]; then
		printc $C_YELLOW "$PROGRAM_NAME is" "stopping" "..."
		kill -2 $psid
		if [[ $? -eq 0 ]]; then
			printc $C_BLUE "Stop:" "[SUCCESS]" "(found-psid=$psid)"
		else
			printc $C_RED "Stop:" "[FAAAAAAAAILED]" "(found-psid=$psid)"
		fi
	else
		printc $C_RED "$PROGRAM_NAME is" "[NOOOOOOOOT-RUNNING]"
	fi
}

# 查询状态
function daemon_status()
{
	getpsid

	if [[ $psid -ne 0 ]]; then
		printc $C_BLUE "$PROGRAM_NAME is" "[RUNNING]" "(found-psid=$psid)"
	else
		printc $C_RED "$PROGRAM_NAME is" "[NOOOOOOOOT-RUNNING]"
	fi
}

# Main

case "$1" in
'start')
    daemon_start
    ;;
'stop')
	daemon_stop
	;;
'status')
	daemon_status
	;;
'restart')
    daemon_stop
    daemon_start
    ;;
*)

echo "   "
echo "$PROGRAM_NAME Service control script"
printc $C_YELLOW "Github:" "http://github.com/yoojia/scripts"
printc $C_YELLOW "Author:" "yoojiachen@gmail.com"
echo "= Usage:"
printc $C_YELLOW "    $0: [" "start|stop|restart|status" "]"
echo "    "
exit 1

esac

