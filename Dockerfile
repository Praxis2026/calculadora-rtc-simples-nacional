# Imagem do motor Simples Nacional (RFB) para rodar no Easypanel.
# O banco SQLite vem do Flyway do repositorio Regime Regular (mesma release dos dois motores).
# API na porta 8082, context-path /api.

# Estagio 1: gera o banco com o Flyway do Regime Regular (Java 21)
FROM eclipse-temurin:21-jdk AS db
ARG REGIME_REPO=https://github.com/ReceitaFederal/calculadora-rtc-regime-regular.git
ARG REGIME_REF=1.7.2
RUN apt-get update && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /regime
RUN git clone --depth 1 --branch ${REGIME_REF} ${REGIME_REPO} .
RUN chmod +x mvnw && mkdir -p calculadora/db \
 && ./mvnw -B -q flyway:migrate -Dflyway.configFiles=flyway/flyway-pro.conf

# Estagio 2: compila o Simples Nacional (Java 25)
FROM eclipse-temurin:25-jdk AS build
WORKDIR /app
COPY . .
RUN chmod +x mvnw && ./mvnw -B -q clean package -DskipTests

# Estagio 3: imagem final
FROM eclipse-temurin:25-jre
WORKDIR /app
COPY --from=build /app/target/api-simples-nacional.jar ./api-simples-nacional.jar
COPY --from=db /regime/calculadora ./calculadora
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75"
EXPOSE 8082
ENTRYPOINT ["java","-Dspring.profiles.active=offline","-jar","api-simples-nacional.jar"]
