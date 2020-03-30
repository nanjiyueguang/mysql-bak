FROM mongo:3.4
# MAINTAINER Ilya Stepanov <dev@ilyastepanov.com>

RUN apt-get update && \
    apt-get install -y cron && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ADD mongodump.sh /usr/bin/mongodump.sh
RUN chmod +x /usr/bin/mongodump.sh 

VOLUME /dump

ENTRYPOINT ["mongodump.sh"]
CMD [""]
