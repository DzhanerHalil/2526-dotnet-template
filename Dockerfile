# =============================================================================
# RISE Application Dockerfile
# =============================================================================
# This file must be placed in the ROOT of your RISE fork repository:
#   https://github.com/DzhanerHalil/2526-dotnet-template/Dockerfile
#
# It builds the Rise.Server project and creates a minimal runtime image.
# =============================================================================

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore src/Rise.Server/Rise.Server.csproj
RUN dotnet publish src/Rise.Server/Rise.Server.csproj \
    --configuration Release \
    --output /app/publish \
    --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

# Security: run as non-root
RUN addgroup --system --gid 1001 risegroup && \
    adduser --system --uid 1001 --gid 1001 riseuser

COPY --from=build /app/publish .
RUN chown -R riseuser:risegroup /app

USER riseuser

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "Rise.Server.dll"]
