#!/bin/bash
# Скрипт для автоматической сборки LuaJIT DLL в CI/CD (GitHub Actions)
set -e # Останавливать выполнение при любой ошибке

echo "=== 1. Клонирование исходников LuaJIT v2.1 ==="
if [ ! -d "LuaJIT/src" ]; then
    git clone --branch v2.1 https://github.com/LuaJIT/LuaJIT.git
fi

# --- Получаем информацию о коммите ---
cd LuaJIT
COMMIT_HASH=$(git rev-parse --short=8 HEAD)
COMMIT_DATE=$(git log -1 --format=%cd --date=format:'%d.%m.%Y %H:%M:%S')
COMMIT_MSG=$(git log -1 --format=%s)
cd ..

# Выводим информацию в лог сборки
echo "================================================="
echo "Хэш коммита: ${COMMIT_HASH}"
echo "Дата коммита: ${COMMIT_DATE}"
echo "Название: ${COMMIT_MSG}"
echo "================================================="
# -------------------------------------------------

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
# Генерируем текущую дату сборки
BUILD_DATE=$(date +"%d.%m.%Y")
BUILD_TIME=$(date +"%H:%M:%S")

# Формируем имя архива, включая хэш коммита
ZIP_NAME="LuaJIT_DLLs_${BUILD_DATE}_commit_${COMMIT_HASH}.zip"

# Переходим в папку с результатами
cd LuaJIT/build/windows

# Создаем текстовый файл с информацией о сборке (обязательно)
echo "=== LuaJIT Build Information ===" > build_info.txt
echo "Date of build (CI):   ${BUILD_DATE} ${BUILD_TIME}" >> build_info.txt
echo "Commit Hash:          ${COMMIT_HASH}" >> build_info.txt
echo "Commit Date:          ${COMMIT_DATE}" >> build_info.txt
echo "Commit Message:       ${COMMIT_MSG}" >> build_info.txt
echo "Target Branch:        v2.1" >> build_info.txt

# Пакуем DLL и текстовый файл
zip -r "../../../${ZIP_NAME}" *.dll build_info.txt
cd ../../..

echo "=== Сборка успешно завершена! Создан файл ${ZIP_NAME} ==="
