#!/usr/bin/env bash

if [[ "$#" -eq 1 && ("$1" == "--help" || "$1" == "-h") ]]; then
cat << 'END'
Справка по скрипту: create_virtual_disk.sh

Этот скрипт создает раздел (виртуальный диск) заданного размера.

Использование:
./create_virtual_disk.sh <размер раздела>

Опции:
-h, --help      Показать эту справку и выйти

Пример:
./create_virtual_disk.sh 1024

END
exit 0
fi

# Создаем виртуальный раздел с уникальным именем на основе текущей даты и времени
date_time=$(date +%Y%m%d_%H%M%S)
img_file="$HOME/backup_laba/virtual_disk_$date_time.img"
mount_dir="$HOME/backup_laba/virtual_disk_$date_time"

# Размер в МБ, можно передавать параметром
size_mb=${1:-10000}

# Проверяем установлен ли FUSE
if ! dpkg -l | grep -q fuse; then
echo "FUSE не установлен. Пожалуйста, установите FUSE для использования."
exit 1
fi

# Создаем виртуальный раздел (файл-образ)
echo "Создаем виртуальный диск размером ${size_mb} MB..."
dd if=/dev/zero of=$img_file bs=1M count=$size_mb

# Форматируем файл как ext4
echo "Форматируем виртуальный диск в файловую систему ext4..."
mkfs.ext4 $img_file > /dev/null 2>&1

# Создаем директорию для монтирования, если она не существует
echo "Создаем директорию для монтирования..."
mkdir -p $mount_dir

# Монтируем файл-образ через FUSE
echo "Монтируем виртуальный диск через FUSE..."
fuse2fs $img_file $mount_dir > /dev/null 2>&1

echo "Виртуальный диск смонтирован в $mount_dir"
