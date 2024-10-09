#!/usr/bin/env bash

if [[ "$#" -eq 1 && ("$1" == "--help" || "$1" == "-h") ]]; then
cat << 'END'
Справка по скрипту: delete_virtual_disk.sh

Этот скрипт удаляет заданный раздел (виртуальный диск).

Использование:
./create_virtual_disk.sh <имя раздела без .img>

Опции:
-h, --help      Показать эту справку и выйти

Пример:
./delete_virtual_disk.sh virtual_disk_20241005_222743

END
exit 0
fi

# Проверка на наличие аргумента (имя файла образа)
if [ "$#" -lt 1 ]; then
  echo "Использование: $0 <имя файла образа без .img>"
  exit 1
fi

# Переменные
img_file="$1.img"
mount_dir="$HOME/backup_laba/$1"

# Размонтируем раздел
if mount | grep "$mount_dir" > /dev/null; then
echo "Размонтируем $mount_dir"
fusermount -u "$mount_dir"
else
echo "$mount_dir не смонтирован"
fi

# Удаляем файл-образ
if [ -f "$img_file" ]; then
echo "Удаляем файл-образ $img_file..."
rm "$img_file"
else
echo "Файл-образ $img_file не найден"
fi

# Удаляем директорию для монтирования
if [ -d "$mount_dir" ]; then
echo "Удаляем директорию $mount_dir..."
rmdir "$mount_dir"
else
echo "Директория $mount_dir не найдена"
fi

echo "Удаление виртуального раздела завершено."
