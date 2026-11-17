# RabbitMQ for Outpost on Railway: the official image, pinned by version and
# digest. Outpost uses it for its internal delivery and log queues.
FROM rabbitmq:4.4.0-alpine@sha256:7b77c3d3a996c7fcca1ca8bf53ce1557ff43c13b8ca2c132df6031781b209ef2

# Railway gives every deploy a new container hostname. RabbitMQ keeps its data
# under a directory named after the node, so a fixed node name keeps the data
# on the volume across redeploys.
ENV RABBITMQ_NODENAME=rabbit@localhost \
    RABBITMQ_USE_LONGNAME=false

COPY railway-start.sh /usr/local/bin/railway-start.sh

EXPOSE 5672

ENTRYPOINT ["/bin/sh", "/usr/local/bin/railway-start.sh"]
CMD ["rabbitmq-server"]
