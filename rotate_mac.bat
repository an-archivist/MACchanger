@echo off
setlocal enabledelayedexpansion

:: === User Config ===
set "INTERFACE_NAME=Wi-Fi"
set "USE_RANDOM=true"

:: Known MAC pool
set MACS[0]=001122334455
set MACS[1]=66778899AABB
set MACS[2]=CCDDEEFF0011

:: === End Config ===

:: Generate random MAC
set "hex=0123456789ABCDEF"

:generate
set "RANDOM_MAC=02"
for /L %%i in (1,1,5) do (
    set /A idx=!random! %% 16
    call set "RANDOM_MAC=!RANDOM_MAC!!hex:~%idx%,1!"
)

if "%USE_RANDOM%"=="true" (
    set "FINAL_MAC=%RANDOM_MAC%"
) else (
    set /A PICK=%RANDOM% %% 3
    for %%i in (0 1 2) do (
        if "!PICK!"=="%%i" set "FINAL_MAC=!MACS[%%i]!"
    )
)

echo Changing MAC Address on %INTERFACE_NAME% to %FINAL_MAC%

:: WARNING: Adjust Registry key to match your actual adapter ID:
set "REGKEY=HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001"

reg add "%REGKEY%" /v NetworkAddress /d %FINAL_MAC% /f

netsh interface set interface "%INTERFACE_NAME%" disable
timeout /t 3 >nul
netsh interface set interface "%INTERFACE_NAME%" enable

echo MAC Address successfully changed to %FINAL_MAC%.
pause
