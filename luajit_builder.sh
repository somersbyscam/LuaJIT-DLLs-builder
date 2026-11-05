#!/bin/bash
# Скрипт для автоматической сборки LuaJIT DLL в CI/CD (GitHub Actions)
set -e # Останавливать выполнение при любой ошибке

echo "=== 1. Клонирование исходников LuaJIT v2.1 ==="
if [ ! -d "LuaJIT/src" ]; then
    git clone --branch v2.1 https://github.com/LuaJIT/LuaJIT.git
fi

mkdir -p LuaJIT/build/windows

# Общие флаги для линковщика, чтобы DLL были максимально автономными
LDFLAGS_STATIC="-static -static-libgcc -static-libstdc++"

echo "=== 2. Сборка Windows x64 (64-bit) ==="
cd LuaJIT/src
make clean
make HOST_CC=gcc CROSS=x86_64-w64-mingw32- TARGET_SYS=Windows BUILDMODE=dynamic XCFLAGS="-static" LDFLAGS="${LDFLAGS_STATIC}"
mv lua51.dll ../build/windows/lua_5.1_x64.dll
echo "x64 собрана."

echo "=== 3. Сборка Windows x86 (32-bit) ==="
make clean
make HOST_CC="gcc -m32" CROSS=i686-w64-mingw32- TARGET_SYS=Windows BUILDMODE=dynamic XCFLAGS="-static" LDFLAGS="${LDFLAGS_STATIC}"
mv lua51.dll ../build/windows/lua_5.1_x86.dll
echo "x86 собрана."

echo "=== 4. Очистка исходников ==="
make clean
cd ../..

echo "=== 5. Упаковка результатов в ZIP ==="
# Генерируем текущую дату в формате ДД.ММ.ГГГГ
BUILD_DATE=$(date +"%d.%m.%Y")
ZIP_NAME="LuaJIT_DLLs_${BUILD_DATE}.zip"

# Переходим в папку с результатами и пакуем только DLL
cd LuaJIT/build/windows
zip -r "../../../${ZIP_NAME}" *.dll
cd ../../..

echo "=== Сборка успешно завершена! Создан файл ${ZIP_NAME} ==="