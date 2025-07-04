FROM maven:3-amazoncorretto-8 AS builder-ms3

RUN yum install -y git

WORKDIR /build/arcturus-community
RUN git clone --branch dev --recurse-submodules https://git.krews.org/morningstar/Arcturus-Community.git .
# explicit pin this version
RUN git checkout f051d1d1
RUN mvn package
RUN mvn install

WORKDIR /build/arcturus-ws
RUN git clone --recurse-submodules https://git.krews.org/nitro/ms-websockets.git .
RUN sed -i 's#<version>3.0.0</version>#<version>[1.0.0,)</version>#g' pom.xml
RUN mvn package
RUN cp target/NitroWebsockets-*.jar target/websockets.jar



FROM maven:3-amazoncorretto-19 AS builder-ms4

ARG BRANCH=ms4/dev
ARG COMMIT=3bb8ce16

RUN yum install -y git

WORKDIR /build/arcturus-community
RUN git clone --branch ${BRANCH} --recurse-submodules https://git.krews.org/morningstar/Arcturus-Community.git .
RUN git checkout $COMMIT
RUN sed -i 's#Scanner scanner = new Scanner(System.in);##g' src/main/java/com/eu/habbo/Emulator.java
RUN sed -i 's#scanner.nextLine();##g' src/main/java/com/eu/habbo/Emulator.java
ADD patches/ /build/arcturus-community/patches/
RUN find "$(readlink -f patches/)" -type f -name "*.patch" | xargs -I {} sh -c 'echo "Applying {}"; git apply {}'
RUN mvn package
RUN mvn install
RUN cp target/Morningstar*-with-dependencies.jar target/emulator.jar


# WORKDIR /build/apollyon
# RUN git clone --recurse-submodules https://git.gurkengewuerz.de/nitro/apollyon-ms4.git .
# RUN sed -i 's#<version>4.0-DEVPREVIEW</version>#<version>[1.0.0,)</version>#g' pom.xml
# RUN mvn package
# RUN cp target/Apollyon-*.jar target/apollyon.jar



FROM amazoncorretto:19

WORKDIR /app

RUN yum update -y && yum install -y mariadb bash && yum clean all

COPY --from=builder-ms4 /build/arcturus-community/target/emulator.jar /app/emulator.jar
RUN mkdir -p /app/plugins
COPY --from=builder-ms3 /build/arcturus-ws/target/websockets.jar /app/plugins/websockets.jar
# COPY --from=builder-ms4 /build/apollyon/target/apollyon.jar /app/plugins/apollyon.jar

ENTRYPOINT ["/usr/bin/java", "-jar", "/app/emulator.jar"]