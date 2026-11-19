# ---- build stage ----
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q package -DskipTests

# ---- runtime stage ----
FROM tomcat:10.1-jre17-temurin

# Remove default apps and run as an unprivileged user
RUN rm -rf /usr/local/tomcat/webapps/* /usr/local/tomcat/webapps.dist \
 && groupadd -r -g 10001 tomcat \
 && useradd -r -u 10001 -g tomcat -d /usr/local/tomcat -s /usr/sbin/nologin tomcat \
 && chown -R tomcat:tomcat /usr/local/tomcat

COPY --from=build --chown=tomcat:tomcat /src/target/warcration.war /usr/local/tomcat/webapps/ROOT.war

USER 10001
EXPOSE 8080
CMD ["catalina.sh", "run"]
