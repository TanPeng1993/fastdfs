#!/bin/bash
#set -e
if [ "$1" = "monitor" ] ; then
  if [ -n "$TRACKER_SERVER" ] ; then  
    sed -i "s|tracker_server=.*$|tracker_server=${TRACKER_SERVER}|g" /etc/fdfs/client.conf
  fi
  fdfs_monitor /etc/fdfs/client.conf
  exit 0
elif [ "$1" = "storage" -o "$1" = "storage-nginx" -o "$1" = "storage-dht" -o "$1" = "storage-dht-nginx"] ; then
  FASTDFS_MODE="storage"
  echo "正在准备初始化storage，dth或nginx..."
  if [ ! -n "$FASTDFS_BASE_PATH" ] ; then
    FASTDFS_BASE_PATH="/fastdfs/storage"
  fi
  if [ "$1" =~ "nginx" ] ; then
    \cp -f /usr/local/src/fdfs_nginx_conf/nginx_storage.conf /usr/local/nginx/conf/nginx.conf 
  fi
elif [ "$1" = "tracker-nginx" ] ; then
  FASTDFS_MODE="tracker"
  echo "正在准备初始化tracker&nginx..."
  if [ ! -n "$FASTDFS_BASE_PATH" ] ; then
    FASTDFS_BASE_PATH="/fastdfs/tracker"
  fi
  \cp -f /usr/local/src/fdfs_nginx_conf/nginx_tracker.conf /usr/local/nginx/conf/nginx.conf 
else 
  FASTDFS_MODE="tracker"
  echo "正在准备初始化tracker..."
  if [ ! -n "$FASTDFS_BASE_PATH" ] ; then
    FASTDFS_BASE_PATH="/fastdfs/tracker"
  fi
fi

#judge start 'nginx for tracker' or 'nginx for storage' or 'fastdht'.
if [ "$1" != "ngx-tra" -a "$1" != "ngx-sto" -a "$1" != "fastdht"] ; then
  if [ -n "$PORT" ] ; then
    sed -i "s|^port=.*$|port=${PORT}|g" /etc/fdfs/"$FASTDFS_MODE".conf
  fi

  if [ -n "$TRACKER_SERVER" ] ; then
    sed -i "s|tracker_server=.*$|tracker_server=${TRACKER_SERVER}|g" /etc/fdfs/storage.conf
    sed -i "s|tracker_server=.*$|tracker_server=${TRACKER_SERVER}|g" /etc/fdfs/client.conf
    if [ "$1" = "storage-nginx" ] ; then
       sed -i "s|tracker_server=.*$|tracker_server=${TRACKER_SERVER}|g" /etc/fdfs/mod_fastdfs.conf
    fi
  fi

  if [ -n "$GROUP_NAME" ] ; then
    sed -i "s|group_name=.*$|group_name=${GROUP_NAME}|g" /etc/fdfs/storage.conf
  fi  

  FASTDFS_LOG_FILE="${FASTDFS_BASE_PATH}/logs/${FASTDFS_MODE}d.log"
  PID_NUMBER="${FASTDFS_BASE_PATH}/data/fdfs_${FASTDFS_MODE}d.pid"


  # start the fastdfs node.   
  echo "尝试启动$FASTDFS_MODE节点..."
  fdfs_${FASTDFS_MODE}d /etc/fdfs/${FASTDFS_MODE}.conf start
else  #设置nginx和fastdht
  if[ "$1" = "ngx-tra" -o "$1" = "ngx-sto" ] ; then
  
    if [ -n "$TRACKER_SERVER" ] ; then
       sed -i "s|tracker_server=.*$|tracker_server=${TRACKER_SERVER}|g" /etc/fdfs/mod_fastdfs.conf
    fi

    if [ "$1" = "ngx-tra" ] ; then  #nginx
	  rm -f /etc/fdfs/mod_fastdfs.conf
	  \cp -f /usr/local/src/fdfs_nginx_conf/nginx_tracker.conf /usr/local/nginx/conf/nginx.conf 
    else   #nginx-storage
      \cp -f /usr/local/src/fdfs_nginx_conf/nginx_storage.conf /usr/local/nginx/conf/nginx.conf 
	fi
	
    FASTDFS_LOG_FILE="/usr/local/nginx/logs/error.log"
    PID_NUMBER="/usr/local/nginx/logs/nginx.pid"
  
  else  #fastdht
    if [ -n "$STORAGE_SERVER" ] ; then
       sed -i "s|group0 =.*$|group0 = ${STORAGE_SERVER}|g" /etc/fdht/fdht_servers.conf
    fi
	
    FASTDFS_LOG_FILE="/fastdfs/fastdht/logs/fdhtd.log"
    #PID_NUMBER="/fastdfs/fastdht/logs/fdhtd.pid"
  fi
fi

if [ -f "$FASTDFS_LOG_FILE" ]; then
    rm "$FASTDFS_LOG_FILE"
fi

#start the nginx
if [ "$1" =~ "nginx" -o "$1" =~ "ngx" ] ; then
  echo "正在启动nginx..."
  /usr/local/nginx/sbin/nginx
fi

#start the fastdht
if [ "$1" =~ "storage-dht" -o "$1" = "fastdht" ] ; then
  echo "正在启动fastdht..."
  fdhtd /etc/fdht/fdhtd.conf
fi

# wait for pid file(important!),the max start time is 5 seconds,if the pid number does not appear in 5 seconds,start failed.
TIMES=5
while [ ! -f "$PID_NUMBER" -a $TIMES -gt 0 ]
do
    sleep 1s
	TIMES=`expr $TIMES - 1`
done

# if the storage node start successfully, print the started time.
# if [ $TIMES -gt 0 ]; then
#     echo "the ${FASTDFS_MODE} node started successfully at $(date +%Y-%m-%d_%H:%M)"
	
# 	# give the detail log address
#     echo "please have a look at the log detail at $FASTDFS_LOG_FILE"

#     # leave balnk lines to differ from next log.
#     echo
#     echo

    
	
# 	# make the container have foreground process(primary commond!)
#     tail -F --pid=`cat $PID_NUMBER` /dev/null
# # else print the error.
# else
#     echo "the ${FASTDFS_MODE} node started failed at $(date +%Y-%m-%d_%H:%M)"
# 	echo "please have a look at the log detail at $FASTDFS_LOG_FILE"
# 	echo
#     echo
# fi
tail -f "$FASTDFS_LOG_FILE"
