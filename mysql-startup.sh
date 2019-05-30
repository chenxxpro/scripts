#!/bin/sh

[ "$DEBUG" == 'true' ] && set -x

if [ -d /db/mysql ]; then
  echo "[INFO] MySQL directory already present, skipping creation"
else
  echo "[INFO] MySQL data directory not found, creating initial DBs"

  if [ "$MYSQL_ROOT_PASSWORD" = "" ]; then
    echo '[e] $MYSQL_ROOT_PASSWORD missing.'
    exit 1
  else
    echo "[INFO] MySQL root Password: $MYSQL_ROOT_PASSWORD"
  fi

  mysql_install_db --user=root > /dev/null

  MYSQL_DATABASE=${MYSQL_DATABASE:-""}
  MYSQL_USER=${MYSQL_USER:-""}
  MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}

  tfile=`mktemp`
  if [ ! -f "$tfile" ]; then
      return 1
  fi

  cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY "$MYSQL_ROOT_PASSWORD" WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
UPDATE user SET password=PASSWORD("") WHERE user='root' AND host='localhost';
EOF

  if [ "$MYSQL_DATABASE" != "" ]; then
    echo "[INFO] Creating database: $MYSQL_DATABASE"
    echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile

    if [ "$MYSQL_USER" != "" ]; then
      echo "[INFO] Creating user: $MYSQL_USER with password $MYSQL_PASSWORD"
      echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
    fi
  fi

  /usr/bin/mysqld --user=root --bootstrap --verbose=0 < $tfile
  rm -f $tfile

  echo "[INFO] DB Init-Scriptsfinding files"
  if [ "$(ls -A /db/scripts)" ]; then
    echo "[db/scripts] found init files"
    SOCKET="/tmp/mysql.sock"
    mysqld --user=root --skip-networking --socket="${SOCKET}" &

    for i in {30..0}; do
      if mysqladmin --socket="${SOCKET}" ping &>/dev/null; then
        break
      fi
      echo '[INFO] DB Init-ScriptsWaiting for server...'
      sleep 1
    done
    if [ "$i" = 0 ]; then
      echo >&2 '[INFO] DB Init-ScriptsTimeout during MySQL init.'
      exit 1
    fi

    for f in /db/scripts/*; do
      case "$f" in
        *.sh)  echo "[INFO] DB Init-Scriptsrunning $f"; . "$f" ;;
        *.sql) echo "[INFO] DB Init-Scriptsrunning $f"; mysql --socket="${SOCKET}" -hlocalhost "${MYSQL_DATABASE}" < "$f";;
        *)     echo "[INFO] DB Init-Scriptsignoring $f" ;;
      esac
    done
    echo '[INFO] DB Init-ScriptsFinished.'
    mysqladmin shutdown --user=root --socket="${SOCKET}"
  fi
fi

exec /usr/bin/mysqld --user=root --console
