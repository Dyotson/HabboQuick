FROM mysql:8

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-openpyxl \
    && rm -rf /var/lib/apt/lists/*

COPY init-database.sh /usr/local/bin/init-database.sh
RUN chmod +x /usr/local/bin/init-database.sh

ENTRYPOINT ["/usr/local/bin/init-database.sh"]
