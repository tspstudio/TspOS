org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A ; Переменная, перенос строки

start:
    jmp main

;
; Функция print печатает строку на экран
; Чтобы напечатать строку, переносим её в регистр si и вызываем функцию, пример в главной функции
;
print:
    push si
    push ax

.loop:
    lodsb ; загружаем следующий символ из строки в al
    or al, al ; Проверяем, следующий символ конец?
    jz .done ; Если следующий символ конечный, заканчиваем печатать и прыгаем в .done

    mov ah, 0Eh ; Вызываем прерывание БИОСа, для вывода символа из al
    int 0x10

    jmp .loop

.done:
    pop ax ; Удаляем переменные из стека
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
    
    call clear

    mov si, msg_hello
    call print

    hlt

.halt:
    jmp .halt

msg_hello: db "Welcome to TspBoot!", 0, ENDL

times 510-($-$$) db 0
dw 0AA55h