@echo off
title ETL Insentif Q1

echo ======================================
echo ETL INSENTIF Q1
echo ======================================
echo.

python "etl_insentif.py"

if %errorlevel% neq 0 (
    echo.
    echo ERROR TERJADI!
    pause
    exit /b 1
)

echo.
echo ETL BERHASIL
echo Membuka folder output...
echo.

explorer output

pause