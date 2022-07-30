#!/bin/sh

PORT=8080
FOUNDRY_DIR=/home/ubuntu
FOUNDRY_ROOT="${FOUNDRY_DIR}"/foundryvtt/resources/app/main.js
DATA_PATH="${FOUNDRY_DIR}"/.local/share/FoundryVTT
CMD="node ${FOUNDRY_ROOT} --dataPath=${DATA_PATH} --port=${PORT}"
SERVICE_NAME=FoundryVTT
PID_FILE_DIR=/run/foundryvtt
PID_FILE="${PID_FILE_DIR}"/foundryvtt.pid
LOGFILE=/var/log/foundryvtt.log
LOGFILEDATE=$(date "+%F:%T")
USAGE_TEXT="Usage: ${0} start|stop|restart|status"
USER=ubuntu

[ "$(id -u)" = 0 ] && {
  PreCmd="runuser ${USER} -c"
  echo "${PreCmd}"
} || {
  echo "${0}" must run as root.
  exit 1
}

# if [ -f "${FOUNDRY_ROOT}" ]; then
#   echo 'Can not find FoundryVTT root'
#   exit 255
# fi

# if [ -f "${DATA_PATH}" ]; then
#   echo 'Can not find FoundryVTT root'
#   exit 255
# fi

start_service() {
  if [ ! -f "${PID_FILE}" ]; then
    echo "Starting ${SERVICE_NAME}... "
    if [ ! -f "${LOGFILE}" ]; then
      touch "${LOGFILE}"
      chown "${USER}":"${USER}" "${LOGFILE}"
    fi
    PID=$(${PreCmd} "nohup ${CMD} >> ${LOGFILE} 2>&1 </dev/null & echo \$!")
    echo "${PID}"
    echo "${PID}" > "${PID_FILE}"
    chown "${USER}":"${USER}" "${PID_FILE}"
    echo "Started!"
    echo "${PreCmd} $0 ${SERVICE_NAME} startup ${LOGFILEDATE}" >> "${LOGFILE}"
  else
    echo "${SERVICE_NAME} is already running. PID file exists."
  fi
}

stop_service() {
  status_service do_stop
}

status_service() {
  SERVICE_STATUS=""
  if [ -f "${PID_FILE}" ]; then
    PID=$(cat "${PID_FILE}")
    if [ "${PID}" = "" ]; then
      echo "${SERVICE_NAME} is in an unknown state. Please restart. "
    else
      is_running=$(ps -e | grep "${PID}" | wc -l)
      if [ "${is_running}" = "1" ]; then
        if [ "$1" = "" ]; then
          # this is just status
          echo "${SERVICE_NAME} is running"
        else
          if [ "$1" = "do_stop" ]; then
            echo "${SERVICE_NAME} stopping... "
            kill "${PID}"
            echo "Stopped!"
            rm "${PID_FILE}"
            echo "${PreCmd} ${0}: [${LOGFILEDATE}] ${SERVICE_NAME} shutdown" >>"${LOGFILE}"
          fi
        fi
      else
        rm "${PID_FILE}"
        echo "${SERVICE_NAME} is not running. PID file cleaned up."
      fi
    fi
  else
    echo "${SERVICE_NAME} is not running."
  fi
}

[ "${1}" = "" ] && {
  echo "${USAGE_TEXT}"
  echo ""
  exit 1
}

[ -d "${PID_FILE_DIR}" ] || {
  mkdir -p "${PID_FILE_DIR}"
  chown "${USER}":"${USER}" "${PID_FILE_DIR}"
}

case $1 in
start)
  cd "${SERVICE_DIR}" || exit 255
  start_service && sleep 1
  ;;
stop)
  stop_service
  ;;
restart)
  stop_service
  sleep 2
  start_service && sleep 1
  ;;
status)
  status_service
  ;;
esac
