# Imagem do motor Simples Nacional (RFB) para rodar no Easypanel.
# O banco SQLite vem do Flyway do repositorio Regime Regular (mesma release dos dois motores).
# API na porta 8082, context-path /api. Java 25 / Spring Boot 4. Usa o Maven da imagem, sem o mvnw.

# Estagio 1: gera o banco com o Flyway do Regime Regular
FROM maven:3.9-eclipse-temurin-25 AS db
ARG REGIME_REPO=https://github.com/ReceitaFederal/calculadora-rtc-regime-regular.git
ARG REGIME_REF=1.7.2
RUN git clone --depth 1 --branch ${REGIME_REF} ${REGIME_REPO} /regime
WORKDIR /regime
RUN mkdir -p calculadora/db \
 && mvn -B -q flyway:migrate -Dflyway.configFiles=flyway/flyway-pro.conf

# Estagio 2: compila o Simples Nacional
FROM maven:3.9-eclipse-temurin-25 AS build
WORKDIR /app
COPY . .
RUN mvn -B -q clean package -DskipTests

# Estagio 3: imagem final
FROM eclipse-temurin:25-jre
WORKDIR /app
COPY --from=build /app/target/api-simples-nacional.jar ./api-simples-nacional.jar
COPY --from=db /regime/calculadora ./calculadora
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75"
EXPOSE 8082
ENTRYPOINT ["java","-Dspring.profiles.active=offline","-jar","api-simples-nacional.jar"]
