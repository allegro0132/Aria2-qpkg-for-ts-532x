#!/bin/sh
CONF=/etc/config/qpkg.conf
QPKG_NAME="Aria"
QPKG_ROOT=`/sbin/getcfg $QPKG_NAME Install_Path -f ${CONF}`
APACHE_ROOT=/share/`/sbin/getcfg SHARE_DEF defWeb -d Qweb -f /etc/config/def_share.info`
export QNAP_QPKG=$QPKG_NAME
export QPKG_ROOT
export QPKG_NAME
export APACHE_ROOT

export HOME=$QPKG_ROOT
export SHELL=/bin/sh
export LC_ALL=en_US.UTF+8
export USER=admin
export LANG=en_US.UTF+8
export LC_CTYPE=en_US.UTF+8
export DESC=$QPKG_NAME

if [ `/sbin/getcfg "QWEB" "Enable" -d 1` = 0 ]; then
  echo "web server is not enabled"
  /sbin/log_tool  -t1 -uSystem -p127.0.0.1 -mlocalhost -a "[ARIA2] The Web Server is not enabled. Please enable it from the Control Panel first."
fi

case "$1" in
  start)
    ENABLED=$(/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f $CONF)
    if [ "$ENABLED" != "TRUE" ]; then
        echo "$QPKG_NAME is disabled."
        exit 1
    fi

/bin/ln -sf $QPKG_ROOT /opt/$QPKG_NAME
/bin/ln -sf $QPKG_ROOT/www $APACHE_ROOT/Aria2
/bin/ln -sf $QPKG_ROOT/aria2c /usr/bin/aria2c

cd $QPKG_ROOT

wget -t2 -T10 -O tracker https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt
list=`cat $QPKG_ROOT/tracker |awk NF|sed ":a;N;s/\n/,/g;ta"`
if [ -z "`grep "announce" $QPKG_ROOT/tracker`" ]; then
    echo network error......
else
    if [ -z "`grep "bt-tracker" $QPKG_ROOT/aria2.conf`" ]; then
        sed -i '$a bt-tracker='${list} $QPKG_ROOT/aria2.conf
        echo add......
    else
        sed -i "s@bt-tracker=.*@bt-tracker=$list@g" $QPKG_ROOT/aria2.conf
        echo update......
    fi
fi

#./aria2c -D --enable-rpc --rpc-listen-all --rpc-listen-port=6800 --log=$QPKG_ROOT/aria.log
./aria2c --conf-path=$QPKG_ROOT/aria2.conf --log=$QPKG_ROOT/aria.log --input-file=$QPKG_ROOT/aria2.session --save-session=$QPKG_ROOT/aria2.session --rpc-certificate=$QPKG_ROOT/certificate/yourcertificate.pem --rpc-private-key=$QPKG_ROOT/certificate/yourprivitekey.key

    ;;

  stop)

killall -9 aria2c
rm -r $QPKG_ROOT/aria.log
rm -rf /usr/bin/aria2c
rm -rf /opt/$QPKG_NAME
rm -rf $APACHE_ROOT/$QPKG_NAME

    ;;

  restart)
    $0 stop
    $0 start
    ;;

  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit 0
