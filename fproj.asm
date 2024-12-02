section .data
    welcome_msg db "Welcome to the To-Do List Manager!", 10, 0
    menu db 10, "==== To-Do List Manager ====", 10, 0
    menu_choices db "[0] Exit", 10, "[1] Add Task", 10, "[2] Display Tasks", 10, "[3] Mark Task as Completed", 10, "[4] Delete Task", 10, "Enter choice: ", 0
    add_prompt db "Enter your task: ", 0
    display_prompt db "==== Current To-Do List ====", 10, 0
    no_tasks_msg db "No tasks added yet.", 10, 0
    completed_prefix db "[DONE] ", 0
    thank_you_msg db 10, "Thank you for using the To-Do List Manager!", 10, 0
    invalid_choice_msg db "Invalid choice. Please try again.", 10, 0
    task_number_prompt db "Enter the task number: ", 0
    invalid_task_msg db "Invalid task number. Please try again.", 10, 0
    task_format db "%d. %s", 10, 0
    char_format db "%d", 0  ; Format for reading integers

section .bss
    choice resd 1             ; Space for user's menu choice
    tasks resb 1024           ; Storage for tasks (up to 1024 bytes)
    task_count resd 1         ; Counter for the number of tasks
    temp_task resb 128        ; Temporary storage for a new task
    task_number resd 1        ; Task number for marking or deleting

section .text
    global _main
    extern _printf, _scanf, _gets, _exit, _strlen, _strcpy, _strcat

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
    cmp eax, 3               ; Mark task as completed if choice is 3
    je mark_completed
    cmp eax, 4               ; Delete task if choice is 4
    je delete_task
    call invalid_choice_handler ; Handle invalid input
    jmp main_loop

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

mark_completed:
    ; Mark a task as completed
    mov eax, task_number_prompt
    call print_string         ; Prompt for task number
    call get_task_number
    cmp eax, 0
    je invalid_task_handler   ; Handle invalid task number

    mov ecx, [task_number]    ; Get the task number
    dec ecx                   ; Convert to 0-based index
    call mark_task_done
    jmp main_loop

delete_task:
    ; Delete a task
    mov eax, task_number_prompt
    call print_string         ; Prompt for task number
    call get_task_number
    cmp eax, 0
    je invalid_task_handler   ; Handle invalid task number

    mov ecx, [task_number]    ; Get the task number
    dec ecx                   ; Convert to 0-based index
    call delete_task_from_list
    jmp main_loop

save_task:
    ; Save the new task in the tasks array
    mov ecx, [task_count]     ; Get current task count
    imul ecx, 128             ; Multiply by 128 for offset
    lea edi, [tasks + ecx]    ; Address of next task slot
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
    xor ecx, ecx              ; Start with the first task
    mov edx, 1                ; Task number starts at 1
.show_loop:
    cmp ecx, eax              ; Check if all tasks are displayed
    je done_tasks
    mov ebx, ecx
    imul ebx, 128             ; Compute offset: ecx * 128
    lea esi, [tasks + ebx]    ; Address of current task
    push esi
    push edx                  ; Push task number
    push dword task_format
    call _printf              ; Print the task
    add esp, 12
    inc ecx
    inc edx
    jmp .show_loop

no_tasks:
    mov eax, no_tasks_msg
    call print_string
done_tasks:
    ret

mark_task_done:
    ; Mark a specific task as completed
    mov eax, [task_count]
    cmp ecx, eax              ; Ensure task number is valid
    jae invalid_task_handler
    mov eax, ecx
    imul eax, 128             ; Compute offset for the task
    lea edi, [tasks + eax]    ; Address of the task
    push dword completed_prefix
    push edi
    call _strcat              ; Concatenate "[DONE] " prefix
    add esp, 8
    ret

delete_task_from_list:
    ; Delete a specific task
    mov eax, [task_count]
    cmp ecx, eax              ; Ensure task number is valid
    jae invalid_task_handler
    mov eax, ecx              ; Task to delete
    imul eax, 128             ; Compute offset for the task
    lea esi, [tasks + eax + 128] ; Address of the next task
    lea edi, [tasks + eax]    ; Address of the task to delete
    mov ecx, eax              ; Remaining tasks to shift
    sub ecx, 1
    rep movsb                 ; Shift tasks up
    dec dword [task_count]    ; Decrement task count
    ret

invalid_task_handler:
    mov eax, invalid_task_msg
    call print_string
    ret

invalid_choice_handler:
    mov eax, invalid_choice_msg
    call print_string
    ret

print_menu:
    mov eax, menu
    call print_string         ; Print menu header
    mov eax, menu_choices
    call print_string         ; Print menu options
    ret

get_choice:
    push choice
    push dword char_format    ; Pass format and address
    call _scanf
    add esp, 8
    ret

get_task_number:
    push task_number
    push dword char_format
    call _scanf
    add esp, 8
    ret

print_string:
    push eax                  ; Push string address
    call _printf
    add esp, 4
    ret

exit_program:
    mov eax, thank_you_msg
    call print_string         ; Print thank you message
    push 0
    call _exit                ; Exit program
