org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A ; Переменная, перенос строки

;
; FAT12 параметры
;
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'           ; 8 байт, метка которая обычно используется для форматирования диска
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                 ; 2880 * 512 = 1.44МБ
bdb_media_descriptor_type:  db 0F0h                 ; F0 = 3.5" флоппи дискета
bdb_sectors_per_fat:        dw 9                    ; 9 секторов в одной таблице FAT(File Allocation Table)
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; Расширенная запись
ebr_drive_number:           db 0                    ; 0x00 дискета, 0x80 жесткий диск, для красоты
                            db 0                    ; Зарезервировано
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h   ; Серийный номер
ebr_volume_label:           db 'TspOS Live'        ; 11 байт метка раздела
ebr_system_id:              db 'FAT12   '           ; 8 байт

start:
    jmp main

;
; Функция print печатает строку на экран
; Чтобы напечатать строку, переносим её в регистр si и вызываем функцию, пример в главной функции
;
print:
    push si
    push ax
    push bx

.loop:
    lodsb ; загружаем следующий символ из строки в al
    or al, al ; Проверяем, следующий символ конец?
    jz .done ; Если следующий символ конечный, заканчиваем печатать и прыгаем в .done

    mov ah, 0x0E ; Вызываем прерывание БИОСа, для вывода символа из al
    mov bh, 0
    int 0x10

    jmp .loop

.done:
    pop bx ; Удаляем переменные из стека
    pop ax
    pop si
    ret

clear:
    mov ah, 0 ; Очищаем экран
    mov al, 0x03
    int 0x10
    ret

main:
    ; Инициализируем сегмент данных

    mov ax, 0 ; Мы не можем записывать в регистры сегмента ds/es напрямую, используем промежуточный регистр ax
    mov ds, ax
    mov es, ax

    ; Инициализируем стек

    mov ss, ax
    mov sp, 0x7C00 ; Стек будет расти в начало загрузчика, чтобы не перезаписывать ОС
    
    mov [ebr_drive_number], dl

    mov ax, 1
    mov cl, 1
    mov bx, 0x7E00 ; Данные должны быть после загрузчика
    call read_disk

    call clear

    mov si, msg_hello
    call print

    cli
    hlt

;
; Обработка ошибок
;

floppy_error:
    mov si, msg_fail
    call print
    jmp wait_key_and_reboot
    hlt

wait_key_and_reboot:
    mov ah, 0
    int 16h ; Ждем нажатие кнопки
    jmp 0FFFFh:0 ; Прыгаем в начало БИОСа, тем самым перезагружаем систему
    hlt

.halt:
    cli
    hlt

;
; Чтение диска
;

;
; Конвертатор LBA в CHS
; Конвертирует адрес LBA(Logical block addressing) из регистра ax в адрес CHS(Cylinder, Head, Sector) по формуле
; C=(LBA/секторов_на_треке)/головок H=(LBA/секторов_на_треке)%головок S=(LBA%секторов_на_треке)+1
;
LBA_to_CHS:

    ; Необходимо сохранить переменные в стеке, так как они изменятся
    push ax
    push dx

    ; Обчисляем S(сектор)
    xor dx, dx ; Необходимо обнулить регистр dx
    div word [bdb_sectors_per_track] ; ax = LBA/секторов_на_треке
                                     ; dx = LBA%секторов_на_треке
    inc dx ; Прибавляем 1 к регистру dx и получаем сектор
    mov cx, dx
    
    ; Обчисляем H(головку) и C(цилиндр)
    xor dx, dx ; Необходимо обнулить регистр dx
    div word [bdb_heads] ; ax = (LBA/секторов_на_треке) / Головок
                          ; dx = (LBA/секторов_на_треке) % Головок
    mov dh, dl ; dl = нижние 8 бит регистра dx
    mov ch, al ; ch = нижние 8 бит регистра cx
    shl ah, 6
    or cl, ah ; Отправляем нижние 2 бита в регистр CL

    ; Восстанавливаем регистр dl
    pop ax
    mov dl, al
    pop ax
    ret

;
; Функция чтения секторов с диска
; Читает cl секторов с диска по адресу LBA из регистра ax на диске с номером dl и хранит прочитанные данные в регистре es:bx
;
read_disk:
    ; Необходимо сохранить переменные в стеке, так как они изменятся
    push ax
    push bx
    push cx
    push dx
    push di

    push cx
    call LBA_to_CHS ; Обчисляем адрес чтения
    pop ax ; al = количество секторов для чтения

    mov ah, 02h
    mov di, 3 ; Рекомендуют пробовать читать диск 3 раза

.retry:
    pusha ; Сохраняем все регистры в стек
    stc ; Устанавливаем флаг переноса, так как некоторые БИОСы не устанавливают его
    int 13h ; Прерывание чтения, если флаг переноса очистился, чтение прошло успешно
    jnc .done ; Прыгаем на метку .done если чтение успешно
    
    popa ; popa kak u kim
    call reset_disk

    dec di
    test di, di
    jnz .retry

.fail:
    ; Если диск не прочитался с 3 раз то вызываем floppy_error
    jmp floppy_error

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

reset_disk:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret

msg_hello: db "Welcome to TspBoot!", ENDL, 0
msg_fail: db "Read failed!", ENDL, 0

times 510-($-$$) db 0
dw 0AA55h