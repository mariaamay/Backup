#!/usr/bin/env bash

if [[ "$#" -eq 1 && ("$1" == "--help" || "$1" == "-h") ]]; then
cat << 'END'
Справка по скрипту: backup.sh

Этот скрипт выполняет резервное копирование заданной директории.

Скрипт не требует дополнительных зависимостей, но должен выполняться в среде Unix/Linux.

Использование:
./backup.sh <source_directory> <threshold percentage> [number of files to archive]"
Где [number of files to archive] - необязательный параметр"

Опции:
-h, --help      Показать эту справку и выйти

Пример:
./backup.sh /home/user/documents 70 20
END
exit 0
fi

# Проверка на наличие аргументов
if [ "$#" -lt 2 ]; then
echo "Недостаточно аргументов. Введите запрос в формате: $0 <путь к папке> <процент заполненности> [количество файлов для архивирования]"
exit 1
fi

# Переменные
log_dir="$1"
threshold="$2"
N="${3:-5}" # По умолчанию архивируем 5 файлов, если N не указано
backup_dir="$HOME/backup_laba/backup"

# Поиск последнего созданного виртуального диска (файл-образ)
img_file=$(ls -t virtual_disk*.img 2>/dev/null | head -n 1)

# Проверка на существование папки
if [ ! -d "$log_dir" ]; then
echo "Папки $log_dir не существует"
exit 1
fi

# Создание папки для архивации, если её не существует
if [ ! -d "$backup_dir" ]; then
mkdir -p "$backup_dir"
fi

# Получаем размер папки в гигабайтах
folder_size=$(du -s "$log_dir" | awk '{printf "%.2f", $1 / 1024 / 1024}')
echo "Размер папки $log_dir: $folder_size GB"

# Проверка существования файла-образа виртуального диска
if [ ! -f "$img_file" ]; then
  echo "Файл-образ виртуального диска не найден: $img_file"
  exit 1
fi

# Получаем размер папки в байтах
folder_size=$(du -sb "$log_dir" | awk '{print $1}')

# Получаем размер виртуального раздела в байтах
total_space=$(stat --format="%s" "$img_file")

# Вычисляем процент заполненности папки относительно виртуального раздела
folder_usage_percent=$(echo "scale=2; $folder_size * 100 / $total_space" | bc)

# Если процент заполненности превышает введенный порог, архивируем и удаляем N самых старых файлов в зависимости от даты модификации
if (( $(echo "$folder_usage_percent > $threshold" | bc -l) )); then
echo "Заполненность превышает $threshold%. Архивируем $N старейших файлов..."

old_files=$(find "$log_dir" -type f -printf "%T+ %p\n" | sort | head -n "$N" | awk '{print $2}')

# Проверка что есть файлы для архивирования
if [ -z "old_files" ]; then
echo "Нет файлов для архивирования"
exit 0
fi

# Создаем архив
archive_name="$backup_dir/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$archive_name" $old_files

# Проверяем, был ли создан архив
if [ $? -eq 0 ]; then
echo "Файлы успешно заархивированы в $archive_name"

echo "Удаляем заархивированные файлы..."
for file in $old_files; do
rm "$file"
echo "Удален файл: $file"
done

else
echo "Ошибка при создании архива."
exit 1
fi

else
echo "Заполненность не превышает $threshold%. Архивирование не требуется."
fi

