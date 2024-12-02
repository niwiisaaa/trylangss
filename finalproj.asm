section .data
    welcome_msg db "Welcome to the To-Do List Manager!", 10, 0
    menu db 10, "==== To-Do List Manager ====", 10, 0
    menu_choices db "[0] Exit", 10, "[1] Add Task", 10, "[2] Display Tasks", 10, "Enter choice: ", 0
    add_prompt db "Enter your task: ", 0
    display_prompt db "==== Current To-Do List ====", 10, 0
    no_tasks_msg db "No tasks added yet.", 10, 0
    thank_you_msg db 10, "Thank you for using the To-Do List Manager!", 10, 0
    invalid_choice_msg db "Invalid choice. Please try again.", 10, 0
    char_format db "%d", 0
    task_format db "%s", 10, 0

section .bss
    choice resd 1             ; Space for user's menu choice
    tasks resb 1024           ; Storage for tasks (1024 bytes)
    task_count resd 1         ; Counter for the number of tasks
    temp_task resb 128        ; Temporary storage for a new task

section .text
    global _main
    extern _printf, _scanf, _gets, _exit

_main:
    ; Initialize task count
    mov dword [task_count], 0

    ; Display welcome message
    mov eax, welcome_msg
    call print_string

main_loop:
    ; Display menu and get user choice
    call print_menu
    call get_choice
    mov eax, [choice]
    cmp eax, 0               ; Exit if choice is 0
    je exit_program
    cmp eax, 1               ; Add task if choice is 1
    je add_task
    cmp eax, 2               ; Display tasks if choice is 2
    je display_tasks
    jmp invalid_choice_handler ; Handle invalid input

add_task:
    mov eax, add_prompt
    call print_string         ; Prompt for a new task
    lea eax, [temp_task]      ; Load address of temp_task
    push eax
    call _gets                ; Read the task into temp_task
    add esp, 4

    ; Add task to the task list
    call save_task
    jmp main_loop

display_tasks:
    mov eax, display_prompt
    call print_string         ; Print header for task list
    call show_tasks           ; Display all tasks
    jmp main_loop

save_task:
    ; Save the new task in the tasks array
    mov ecx, [task_count]     ; Get current task count
    mov eax, ecx
    imul eax, 128             ; Multiply ecx by 128
    lea edi, [tasks + eax]    ; Compute task storage address
    lea esi, [temp_task]      ; Address of the new task
    mov ecx, 128              ; Maximum task size
    rep movsb                 ; Copy task to tasks array

    ; Increment task count
    mov eax, [task_count]
    inc eax
    mov [task_count], eax
    ret

show_tasks:
    ; Display all tasks or a message if no tasks exist
    mov eax, [task_count]
    cmp eax, 0
    je no_tasks
    ; Iterate through tasks
    mov ecx, 0                ; Start with the first task
.show_loop:
    cmp ecx, eax              ; Check if all tasks are displayed
    je done_tasks
    mov ebx, ecx
    imul ebx, 128             ; Compute offset: ecx * 128
    lea esi, [tasks + ebx]    ; Compute address of current task
    push esi
    push dword task_format
    call _printf              ; Print the task
    add esp, 8
    inc ecx
    jmp .show_loop

no_tasks:
    mov eax, no_tasks_msg
    call print_string
done_tasks:
    ret

print_menu:
    ; Print the menu options
    mov eax, menu
    call print_string
    mov eax, menu_choices
    call print_string
    ret

get_choice:
    ; Get user choice from menu
    push choice
    push dword char_format
    call _scanf
    add esp, 8
    ret

print_string:
    ; Print a string using printf
    push eax
    call _printf
    add esp, 4
    ret

invalid_choice_handler:
    mov eax, invalid_choice_msg
    call print_string
    jmp main_loop

exit_program:
    ; Exit the program
    mov eax, thank_you_msg
    call print_string
    push 0
    call _exit
