FROM postgres:10.4

RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates curl ssh sshpass rsync && mkdir ~/.ssh && rm -rf /var/lib/apt/lists/* \
	&& curl -L https://github.com/odise/go-cron/releases/download/v0.0.7/go-cron-linux.gz | zcat > /usr/local/bin/go-cron \
	&& chmod a+x /usr/local/bin/go-cron \
	&& apt-get purge -y --auto-remove ca-certificates && apt-get clean

ENV POSTGRES_HOST **None**
ENV POSTGRES_PORT 5432
ENV POSTGRES_USER **None**
ENV POSTGRES_PASSWORD **None**

ENV RSYNC_HOST **None**
ENV RSYNC_PORT 22
ENV RSYNC_FOLDER **None**
ENV RSYNC_OPTIONS '--dry-run -azvv'
ENV RSYNC_ROTATE no
ENV RSYNC_USER **None**
ENV RSYNC_PASSWORD **None**

ENV SCHEDULE '@daily'
ENV BACKUP_DIR '/backups'
ENV BACKUP_KEEP_DAYS 7
ENV BACKUP_KEEP_WEEKS 4
ENV BACKUP_KEEP_MONTHS 6

COPY backup.sh /backup.sh
ADD restore.sh /restore.sh
RUN ["chmod", "+x", "/restore.sh"]

VOLUME /backups

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["exec /usr/local/bin/go-cron -s \"$SCHEDULE\" -p 80 -- /backup.sh"]

HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost/ || exit 1
