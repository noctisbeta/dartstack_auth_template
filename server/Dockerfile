# Use latest stable channel SDK.
FROM dart:stable AS build

# Set base working directory
WORKDIR /app

# Copy the common package
COPY common /app/common/

# Copy the server package
COPY server /app/server/

# Move to server directory and get dependencies
WORKDIR /app/server
RUN dart pub get

# Compile
RUN dart compile exe bin/server.dart -o bin/server

# Final stage
FROM debian:buster-slim

WORKDIR /app

# Copy compiled application
COPY --from=build /app/server/bin/server /app/server
COPY --from=build /runtime/ /

# Expose ports
EXPOSE 8080

CMD ["/app/server"]
