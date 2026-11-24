@echo off
title Build AI Reel Studio APK via GitHub Actions
cd /d "%~dp0"

echo =========================================================================
echo       AI REEL STUDIO - AUTOMATIC APK BUILD & GITHUB PUSH
echo =========================================================================
echo.
echo 1. Apne GitHub account (mylovevmchaudhary-svg) par jakar ek New Repo banayein:
echo    Repo Name: ai-reel-studio (Public ya Private)
echo.
echo 2. Banane ke baad uska link copy karein:
echo    Jaise: https://github.com/mylovevmchaudhary-svg/ai-reel-studio.git
echo.
set /p REPO_URL="Aapna GitHub Repo Link yahan Paste karke ENTER dabayein: "

if "%REPO_URL%"=="" (
    echo Koi link enter nahi kiya gaya! Exiting...
    pause
    exit /b
)

echo.
echo Git initialize aur files add ki ja rahi hain...
git init
git add .
git commit -m "feat: complete production-ready AI Reel Studio with 23 screens"

echo.
echo GitHub se connect kiya ja raha hai...
git remote remove origin >nul 2>&1
git remote add origin %REPO_URL%
git branch -M main

echo.
echo Project ko GitHub par upload kiya ja raha hai...
git push -u origin main

echo.
echo =========================================================================
echo    PROJECT GITHUB PAR SAFALTAPOORVAK UPLOAD HO GAYA HAI! 🎉
echo =========================================================================
echo.
echo Ab apne GitHub repo me "Actions" tab par jaiye:
echo Wahan "Build AI Reel Studio APK" workflow automatically start ho gaya hai.
echo ~3 minutes me "AIReelStudio-Release-APK" ready ho jayega jise aap
echo direct download karke apne Android phone me install kar sakte hain!
echo.
pause
