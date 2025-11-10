# Multi-stage Dockerfile for ASP.NET Core 8.0 API
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy full backend folder to resolve project references (Core/Infrastructure)
COPY . .

# Restore and publish the API project
RUN dotnet restore ./PetLove.API/PetLove.API.csproj \
 && dotnet publish ./PetLove.API/PetLove.API.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Bind Kestrel to Render-provided PORT
ENV ASPNETCORE_URLS=http://0.0.0.0:${PORT}

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "PetLove.API.dll"]