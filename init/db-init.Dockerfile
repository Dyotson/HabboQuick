FROM mysql:8

RUN microdnf update -y && microdnf install -y \
    python3 \
    python3-pip \
    && microdnf clean all

RUN pip3 install openpyxl

COPY init-database.sh /usr/local/bin/init-database.sh
RUN chmod +x /usr/local/bin/init-database.sh

ENTRYPOINT ["/usr/local/bin/init-database.sh"]
