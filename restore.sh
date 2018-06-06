#! /bin/bash
export PGPASSWORD=$POSTGRES_PASSWORD

echo "=> Restore database from ${!#}"
if pg_restore -h${POSTGRES_HOST} -p${POSTGRES_PORT} -U${POSTGRES_USER} $@  ;then
    echo "   Restore succeeded"
else
    echo "   Restore failed"
fi
echo "=> Done"
