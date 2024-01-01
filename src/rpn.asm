; Компоновщик находит символ _start и начинает выполнение программы
; отсюда.
global _start

section .data
    stack_size: dd 0        ; создаём переменную dword (4 байта) со значением 0
    stack: times 256 dd 0   ; заполняем стек нулями
	error_msg: db "Invalid input", 0xA, 0x0

section .text
_strlen:
    enter 0, 0          ; сохраняем указатель базы предыдущего фрейма и настраиваем ebp
    ; Здесь я бы сохранил регистры вызываемой подпрограммы, но я ничего не 
    ; собираюсь изменять
    ; Здесь начинается функция
    mov eax, 0          ; length = 0
    mov ecx, [ebp+8]    ; первый аргумент функции (указатель на первый
                        ; символ строки) копируется в ecx (его сохраняет вызывающая 
                        ; сторона, так что нам нет нужды сохранять)
_strlen_loop_start:     ; это метка, куда можно перейти
    cmp byte [ecx], 0   ; разыменование указателя и сравнение его с нулём. По
                        ; умолчанию память считывается по 32 бита (4 байта).
                        ; Иное нужно указать явно. Здесь мы указываем
                        ; чтение только одного байта (один символ)
    je _strlen_loop_end ; выход из цикла при появлении нуля
    inc eax             ; теперь мы внутри цикла, добавляем 1 к возвращаемому значению
    add ecx, 1          ; переход к следующему символу в строке
    jmp _strlen_loop_start  ; переход обратно к началу цикла
_strlen_loop_end:
    ; Здесь функция заканчивается, eax равно возвращаемому значению
    ; Здесь я бы восстановил регистры, но они не сохранялись
    leave               ; восстановление указателя базы предыдущего фрейма
    ret
_print_msg:
    enter 0, 0
    ; Здесь начинается функция
    mov eax, 0x04       ; 0x04 = системный вызов write()
    mov ebx, 0x1        ; 0x1 = стандартный вывод
    mov ecx, [ebp+8]    ; мы хотим вывести первый аргумент этой функции,
    ; сначала установим edx на длину строки. Пришло время вызвать _strlen
    push eax            ; сохраняем регистры вызываемой функции (я решил не сохранять edx)
    push ecx       
    push dword [ebp+8]  ; пушим аргумент _strlen в _print_msg. Здесь NASM
                        ; ругается, если не указать размер, не знаю, почему.
                        ; В любом случае указателем будет dword (4 байта, 32 бита)
    call _strlen        ; eax теперь равен длине строки
    mov edx, eax        ; перемещаем размер строки в edx, где он нам нужен
    add esp, 4          ; удаляем 4 байта со стека (один 4-байтовый аргумент char*)
    pop ecx             ; восстанавливаем регистры вызывающей стороны
    pop eax
    ; мы закончили работу с функцией _strlen, можно инициировать системный вызов
    int 0x80
    leave
    ret
_push:
    enter 0, 0
    ; Сохраняем регистры вызываемой функции, которые будем использовать
    push eax
    push edx
    mov eax, [stack_size]
    mov edx, [ebp+8]
    mov [stack + 4*eax], edx    ; Заносим аргумент на стек. Масштабируем по
                                ; четыре байта в соответствии с размером dword
    inc dword [stack_size]      ; Добавляем 1 к stack_size
    ; Восстанавливаем регистры вызываемой функции
    pop edx
    pop eax
    leave
    ret

_pop:
    enter 0, 0
    ;  Сохраняем регистры вызываемой функции
    dec dword [stack_size]      ; Сначала вычитаем 1 из stack_size
    mov eax, [stack_size]
    mov eax, [stack + 4*eax]    ; Заносим число на верх стека в eax
    ; Здесь я бы восстановил регистры, но они не сохранялись
    leave
    ret

_pow_10:
    enter 0, 0
    mov ecx, [ebp+8]    ; задаёт ecx (сохранённый вызывающей стороной) аргументом 
                        ; функции
    mov eax, 1          ; первая степень 10 (10**0 = 1)
_pow_10_loop_start:     ; умножает eax на 10, если ecx не равно 0
    cmp ecx, 0
    je _pow_10_loop_end
    imul eax, 10
    sub ecx, 1
    jmp _pow_10_loop_start
_pow_10_loop_end:
    leave
    ret

_mod:
    enter 0, 0
    push ebx
    mov edx, 0          ; объясняется ниже
    mov eax, [ebp+8]
    mov ebx, [ebp+12]
    idiv ebx            ; делит 64-битное целое [edx:eax] на ebx. Мы хотим поделить
                        ; только 32-битное целое eax, так что устанавливаем edx равным 
                        ; нулю.
                        ; частное сохраняем в eax, остаток в edx. Как обычно, получить 
                        ; информацию по конкретной инструкции можно из справочников, 
                        ; перечисленных в конце статьи.
    mov eax, edx        ; возвращает остаток от деления (модуль)
    pop ebx
    leave
    ret

_putc:
    enter 0, 0
    mov eax, 0x04       ; write()
    mov ebx, 1          ; стандартный вывод
    lea ecx, [ebp+8]    ; входной символ
    mov edx, 1          ; вывести только 1 символ
    int 0x80
    leave
    ret

%define MAX_DIGITS 10

_print_answer:
    enter 1, 0              ; используем 1 байт для переменной "started" в коде C
    push ebx
    push edi
    push esi
    mov eax, [ebp+8]        ; наш аргумент "a"
    cmp eax, 0              ; если число не отрицательное, пропускаем этот условный 
                            ; оператор
    jge _print_answer_negate_end
    ; call putc for '-'
    push eax
    push 0x2d               ; символ '-'
    call _putc
    add esp, 4
    pop eax
    neg eax                 ; преобразуем в положительное число
_print_answer_negate_end:
    mov byte [ebp-4], 0     ; started = 0
    mov ecx, MAX_DIGITS     ; переменная i
_print_answer_loop_start:
    cmp ecx, 0
    je _print_answer_loop_end
    ; вызов pow_10 для ecx. Попытаемся сделать ebx как переменную "digit" в коде C.
    ; Пока что назначим edx = pow_10(i-1), а ebx = pow_10(i)
    push eax
    push ecx
    dec ecx             ; i-1
    push ecx            ; первый аргумент для _pow_10
    call _pow_10
    mov edx, eax        ; edx = pow_10(i-1)
    add esp, 4
    pop ecx             ; восстанавливаем значение i для ecx
    pop eax
    ; end pow_10 call
    mov ebx, edx        ; digit = ebx = pow_10(i-1)
    imul ebx, 10        ; digit = ebx = pow_10(i)
    ; вызываем _mod для (a % pow_10(i)), то есть (eax mod ebx)
    push eax
    push ecx
    push edx
    push ebx            ; arg2, ebx = digit = pow_10(i)
    push eax            ; arg1, eax = a
    call _mod
    mov ebx, eax        ; digit = ebx = a % pow_10(i+1), almost there
    add esp, 8
    pop edx
    pop ecx
    pop eax
    ; завершение вызова mod
    ; делим ebx (переменная "digit" ) на pow_10(i) (edx). Придётся сохранить пару 
    ; регистров, потому что idiv использует для деления и edx, eax. Поскольку 
    ; edx является нашим делителем, переместим его в какой-нибудь 
    ; другой регистр
    push esi
    mov esi, edx
    push eax
    mov eax, ebx
    mov edx, 0
    idiv esi            ; eax хранит результат (цифру)
    mov ebx, eax        ; ebx = (a % pow_10(i)) / pow_10(i-1), переменная "digit" в коде C
    pop eax
    pop esi
    ; end division
    cmp ebx, 0                        ; если digit == 0
    jne _print_answer_trailing_zeroes_check_end
    cmp byte [ebp-4], 0               ; если started == 0
    jne _print_answer_trailing_zeroes_check_end
    jmp _print_answer_loop_continue   ; continue
_print_answer_trailing_zeroes_check_end:
    mov byte [ebp-4], 1     ; started = 1
    add ebx, 0x30           ; digit + '0'
    ; вызов putc
    push eax
    push ecx
    push edx
    push ebx
    call _putc
    add esp, 4
    pop edx
    pop ecx
    pop eax
    ; окончание вызова putc
_print_answer_loop_continue:
    sub ecx, 1
    jmp _print_answer_loop_start
_print_answer_loop_end:
    pop esi
    pop edi
    pop ebx
    leave
    ret

_start:
    ; аргументы _start получаются не так, как в других функциях.
    ; вместо этого esp указывает непосредственно на argc (число аргументов), а 
    ; esp+4 указывает на argv. Следовательно, esp+4 указывает на название
    ; программы, esp+8 - на первый аргумент и так далее
    mov esi, [esp+8]         ; esi = "input" = argv[0]
    ; вызываем _strlen для определения размера входных данных
    push esi
    call _strlen
    mov ebx, eax             ; ebx = input_length
    add esp, 4
    ; end _strlen call
    mov ecx, 0               ; ecx = "i"
_main_loop_start:
    cmp ecx, ebx             ; если (i >= input_length)
    jge _main_loop_end
    mov edx, 0
    mov dl, [esi + ecx]      ; то загрузить один байт из памяти в нижний байт
                             ; edx. Остальную часть edx обнуляем.
                             ; edx = переменная c = input[i]
    cmp edx, '0'
    jl _check_operator
    cmp edx, '9'
    jg _print_error
    sub edx, '0'
    mov eax, edx             ; eax = переменная c - '0' (цифра, не символ)
    jmp _push_eax_and_continue
_check_operator:
    ; дважды вызываем _pop для выноса переменной b в edi, a переменной b - в eax
    push ecx
    push ebx
    call _pop
    mov edi, eax             ; edi = b
    call _pop                ; eax = a
    pop ebx
    pop ecx
    ; end call _pop
    cmp edx, '+'
    jne _subtract
    add eax, edi                 ; eax = a+b
    jmp _push_eax_and_continue
_subtract:
    cmp edx, '-'
    jne _multiply
    sub eax, edi                 ; eax = a-b
    jmp _push_eax_and_continue
_multiply:
    cmp edx, '*'
    jne _divide
    imul eax, edi                ; eax = a*b
    jmp _push_eax_and_continue
_divide:
    cmp edx, '/'
    jne _print_error
    push edx                     ; сохраняем edx, потому что регистр обнулится для idiv
    mov edx, 0
    idiv edi                     ; eax = a/b
    pop edx
    ; теперь заносим eax на стек и продолжаем
_push_eax_and_continue:
    ; вызываем _push
    push eax
    push ecx
    push edx
    push eax          ; первый аргумент
    call _push
    add esp, 4
    pop edx
    pop ecx
    pop eax
    ; завершение call _push
    inc ecx
    jmp _main_loop_start
_main_loop_end:
    cmp byte [stack_size], 1      ; если (stack_size != 1), печать ошибки
    jne _print_error
    mov eax, [stack]
    push eax
    call _print_answer
    ; print a final newline
    push 0xA
    call _putc
    ; exit successfully
    mov eax, 0x01           ; 0x01 = exit()
    mov ebx, 0              ; 0 = без ошибок
    int 0x80                ; здесь выполнение завершается
_print_error:
    push error_msg
    call _print_msg
    mov eax, 0x01
    mov ebx, 1
    int 0x80
