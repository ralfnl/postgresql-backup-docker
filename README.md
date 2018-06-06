# Docker based backup for PostgreSQL
**Backup your PostgreSQL databases using this Docker container**

Backup all PostgreSQL databases on a specific server to the local filesystem. The container does this periodically and with backup rotation built in.

## Build/publish image

```shell
docker build -t {repository}/{image} . --force-rm --no-cache
docker login --username username --password password
docker push {repository}/{image}
```
---
## Usage

### Docker CLI
```sh
docker run -e POSTGRES_HOST=postgres -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password ralfnl/postgresql-backup-docker
```

### Docker Compose
```yaml
version: '2'
services:
    postgres:
        image: postgres
        restart: always
        environment:
            - POSTGRES_DB=database
            - POSTGRES_USER=username
            - POSTGRES_PASSWORD=password
    pgbackups:
        image: ralfnl/postgresql-backup-docker
        restart: always
        volumes:
            - /var/opt/pgbackups:/backups
        links:
            - postgres
        depends_on:
            - postgres
        environment:
            - POSTGRES_HOST=postgres
            - POSTGRES_USER=username
            - POSTGRES_PASSWORD=password
            - POSTGRES_EXTRA_OPTS=-Z9 --schema=public --blobs
            - SCHEDULE=@daily
            - BACKUP_KEEP_DAYS=7
            - BACKUP_KEEP_WEEKS=4
            - BACKUP_KEEP_MONTHS=6
```
---
## Making backups

### Manual backup
By default the script makes backups based on the schedule. You can trigger a manual backup by running the `/backup.sh` command.

Example running only manual backup on Docker:
```shell
docker run -e POSTGRES_HOST=postgres -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password  ralfnl/postgresql-backup-docker /backup.sh
```

### Automatic periodic backups

You can change the `SCHEDULE` environment variable like `-e SCHEDULE="@daily"` to change its default frequency, by default is daily.

More information about the scheduling can be found [here](http://godoc.org/github.com/robfig/cron#hdr-Predefined_schedules).

Folders daily, weekly and monthly are created and populated using hard links to save disk space.

---

## Restoring a backup

### List backups

```shell
docker exec ralfnl/postgresql-backup-docker ls /backups/daily
```

### Restore a database from a certain backup

#### Restore _entire_ database
```shell
docker exec ralfnl/postgresql-backup-docker /restore.sh --clean --dbname={database} /backups/daily/{backup-file}.sqlc
```

#### Restore _specific table_ from database
```shell
docker exec ralfnl/postgresql-backup-docker /restore.sh --clean --dbname={database} --table={table} /backups/daily/{backup-file}.sqlc
```

**Note:** `restore.sh` uses `PG_RESTORE` to restore the backup. The bash scripts helps you by filling out hostnames and passwords. You can use any official `PG_RESTORE` parameters, see [PG_RESTORE docs](https://www.postgresql.org/docs/10/static/app-pgrestore.html) for more information.
