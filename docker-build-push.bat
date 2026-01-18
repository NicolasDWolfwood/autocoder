@echo off
REM Build and push AutoCoder Docker image to Docker Hub
REM Windows version - builds for current platform only
REM For multi-architecture builds, use WSL2 or Linux

setlocal

REM Configuration - CHANGE THESE VALUES
set DOCKER_USERNAME=johnreijmer
set IMAGE_NAME=autocoder
set VERSION=0.0.3

REM Derived variables
set FULL_IMAGE=%DOCKER_USERNAME%/%IMAGE_NAME%

echo ============================================
echo   AutoCoder Docker Build ^& Push
echo ============================================
echo.
echo Image: %FULL_IMAGE%
echo Tags:  latest, %VERSION%
echo.

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not running
    echo Please start Docker Desktop and try again
    exit /b 1
)

REM Check if logged in (basic check)
docker info | findstr /C:"Username" >nul
if errorlevel 1 (
    echo WARNING: You may not be logged in to Docker Hub
    echo If the push fails, run: docker login
    echo.
    pause
)

echo Building image...
echo This may take 10-15 minutes...
echo.

docker build -t "%FULL_IMAGE%:latest" -t "%FULL_IMAGE%:%VERSION%" .
if errorlevel 1 (
    echo.
    echo ERROR: Build failed
    exit /b 1
)

echo.
echo Build complete! Pushing to Docker Hub...
echo.

docker push "%FULL_IMAGE%:latest"
if errorlevel 1 (
    echo.
    echo ERROR: Push failed for 'latest' tag
    echo Make sure you're logged in: docker login
    exit /b 1
)

docker push "%FULL_IMAGE%:%VERSION%"
if errorlevel 1 (
    echo.
    echo ERROR: Push failed for version tag
    exit /b 1
)

echo.
echo ============================================
echo   Image Published Successfully!
echo ============================================
echo.
echo Your image is now available at:
echo   docker pull %FULL_IMAGE%:latest
echo   docker pull %FULL_IMAGE%:%VERSION%
echo.
echo View on Docker Hub:
echo   https://hub.docker.com/r/%FULL_IMAGE%
echo.
echo Next steps:
echo 1. Test the image: docker run -d -p 8888:8888 -e ANTHROPIC_API_KEY=sk-ant-... %FULL_IMAGE%:latest
echo 2. Update your docker-compose.yml to use: %FULL_IMAGE%:latest
echo 3. Share with others!
echo.

pause
