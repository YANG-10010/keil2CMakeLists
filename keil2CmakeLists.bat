@echo off
:: Switch code page to UTF-8 to handle potential Unicode characters in file paths.
chcp 65001 >nul

setlocal

:: ##################################################################
:: #                                                                #
:: #  Path to the folder containing the tool files.                 #
:: #  (Pre-filled with the path you provided)                       #
:: #                                                                #
:: ##################################################################
set "SOURCE_PATH=D:\Software\Green\Convert\keil2CMakeLists\ProjectConverter-master"


:: --- Script Body Starts ---
echo.
echo ======================================================
echo ==   Keil (.uvprojx) to CMake Project Converter     ==
echo ==       (with Auto Cleanup & Auto Exit)            ==
echo ======================================================
echo.

if not exist "%SOURCE_PATH%\converter.py" (
    echo [ERROR] Core file converter.py not found in source path:
    echo         "%SOURCE_PATH%"
    echo [ERROR] Please check the path in this script.
    goto :fail
)

echo [INFO] Source Path: %SOURCE_PATH%
echo [INFO] Target Project Path: %cd%
echo.

:: Define the list of files to COPY. This includes all tool files.
set "FILES_TO_COPY=cmake.py CMakeLists.txt converter.py ewpproject.py STM32FLASH.ld uvprojxproject.py"

:: Define the list of files to DELETE. This list excludes CMakeLists.txt.
set "FILES_TO_DELETE=cmake.py converter.py ewpproject.py STM32FLASH.ld uvprojxproject.py"


:: Step 1: Copy tool files
echo [STEP 1/4] Copying tool files from source path...
for %%f in (%FILES_TO_COPY%) do (
    echo     -> Copying %%f...
    copy /Y "%SOURCE_PATH%\%%f" . > nul
)
echo [SUCCESS] Tool files copied to the current directory.
echo.


:: Step 2: Execute the Python conversion script
echo [STEP 2/4] Executing conversion command...
echo   Executing: python converter.py uvprojx "%cd%"
echo.
python converter.py uvprojx "%cd%"
echo.
echo [SUCCESS] Conversion command finished.
echo.


:: Step 3: Clean up the copied files, keeping CMakeLists.txt
echo [STEP 3/4] Cleaning up temporary files (CMakeLists.txt will be kept)...
for %%f in (%FILES_TO_DELETE%) do (
    if exist "%%f" (
        echo     -> Deleting %%f...
        del "%%f" > nul
    )
)
del "Copying" > nul 2>&1
del "Deleting" > nul 2>&1
if exist "__pycache__" rmdir /s /q "__pycache__" > nul

echo [SUCCESS] Temporary files have been deleted.
echo.

:: Step 4: Check if CLion is running and open it if not
echo [STEP 4/4] Checking for and launching CLion IDE...
tasklist /FI "IMAGENAME eq clion64.exe" 2>NUL | findstr /I /N "clion64.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    echo [INFO] CLion is already running. No new instance will be opened.
) else (
    echo [INFO] CLion is not running. Attempting to launch...
    start "" "clion64.exe" "%cd%"
    if %errorlevel% equ 0 (
        echo [SUCCESS] CLion launched successfully.
    ) else (
        echo [WARNING] CLion launch command was executed, but its status could not be verified.
    )
)
echo.

:end
echo [COMPLETE] Script has finished. The window will close automatically.
timeout /t 3 /nobreak >nul
endlocal
exit /b

:fail
echo.
echo [FAILURE] Script terminated due to an error.
pause
endlocal
exit /b 1
