# ---- STAGE 1: Build ----
FROM maven:3.9.6-eclipse-temurin-17 as builder

WORKDIR /app

# Copy only dependency-related files first (for better caching)
COPY pom.xml .
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# ---- STAGE 2: Runtime ----
FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="pankaj.dhapade@example.com"
LABEL app="Ekart"

# Add a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy JAR from the builder stage
COPY --from=builder /app/target/*.jar app.jar

# Set file permissions
RUN chown appuser:appgroup app.jar

USER appuser

# Expose application port
EXPOSE 8080

# Define healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s CMD wget --spider http://localhost:8080/actuator/health || exit 1

# Run the JAR
ENTRYPOINT ["java", "-jar", "app.jar"]
