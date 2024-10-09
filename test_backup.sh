#!/usr/bin/env bash

# Тестовый скрипт для проверки архиватора

# Параметры
log_dir="./log"
backup_dir="./backup"
test_file_size_mb=50 # Размер каждого файла в МБ

# Создание раздела диска
function new_disk() {
local size_of_disk="$1"
./create_virtual_disk.sh "$size_of_disk"
}

# Очистка старых данных перед началом тестов
cleanup() {
echo "Очистка папок $log_dir и $backup_dir..."
rm -rf "$log_dir" "$backup_dir"
mkdir -p "$log_dir" "$backup_dir"
}

# Очистка последнего созданного диска
function delete_disk() {
local file_to_delete=$(ls -t virtual_disk* 2>/dev/null | head -n 1)
local file_to_delete_no_extension=$(basename "$file_to_delete" | cut -d. -f1)
echo "Очистка виртуального диска $file_to_delete..."

# Проверяем, есть ли файлы для удаления
if [ -z "$file_to_delete" ]; then
    echo "Нет файла для удаления."
else
./delete_virtual_disk.sh "$file_to_delete_no_extension"
fi

}

# Генерация файлов в папке /log
function generate_test_data() {
local folder_size_mb="$1"
local file_count=$((folder_size_mb / test_file_size_mb))
echo "Генерация $file_count файлов по $test_file_size_mb МБ в папке $log_dir..."

for i in $(seq 1 "$file_count"); do
# Генерируем файл заданного размера
dd if=/dev/zero of="$log_dir/logfile$i.log" bs=1M count="$test_file_size_mb" status=none
# Делаем задержку в 1 секунду, чтобы изменить дату модификации файла
sleep 0.1
done
}

# Функция для запуска основного скрипта и проверки результатов
run_test_case() {
local threshold="$1"
local n_files="${2:-5}"
echo "Запуск теста: порог = $threshold%, архивируем $n_files файлов"

# Запуск основного скрипта
./backup.sh "$log_dir" "$threshold" "$n_files"
# Проверка результатов
local archived_files=$(tar -tzf "$backup_dir"/*.tar.gz 2> /dev/null | wc -l)
local remaining_files=$(ls "$log_dir" | wc -l)

echo "Архивировано файлов: $archived_files"
echo "Оставшиеся файлы: $remaining_files"
}

# Основная функция для тестов
run_tests() {
# Тест 1: Проверка архивирования при превышении порога, архивирование 10 файлов
echo "Тест 1: Проверка архивирования при превышении порога"
new_disk 1024 # 1 ГБ
generate_test_data 900
run_test_case 80 10

# Очистка после теста
cleanup
delete_disk

# Тест 2: Нет архивации при нормальной заполненности
echo "Тест 2: Нет архивации при нормальной заполненности"
new_disk 5120 # 5 ГБ
generate_test_data 2000
run_test_case 50 20

# Очистка после теста
cleanup
delete_disk

# Тест 3: Проверка корректной работы без аргументов
echo "Тест 3: Проверка корректной работы без аргументов"
new_disk 1024 # 1 ГБ
generate_test_data folder_size_mb=600
run_test_case 50

# Очистка после теста
cleanup
delete_disk

# Тест 4: Проверка корректной работы при параметре N > количество файлов
echo "Тест 4: Проверка корректной работы при параметре N > количество файлов"
new_disk 1536 # 1,5 ГБ
generate_test_data folder_size_mb=1200
run_test_case 70 50

# Очистка после теста
cleanup
delete_disk

}

# Запуск тестов
cleanup
run_tests
