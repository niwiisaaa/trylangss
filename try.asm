section .data
    greetings db "Welcome to the To-Do List Manager!", 10, 0
    menu db "=== To-Do List Manager ===", 10, 
         db "[0] Exit", 10, 
         db "[1] Add Task", 10, 
         db "[2] Display Tasks", 10, 
         db "[3] Mark Task as Completed", 10, 
         db "[4] Delete Task", 10, 0
    
    choice_prompt db "Enter your choice (0-4): ", 0
    new_task_prompt db "Enter a task to add: ", 0
    task_number_prompt db "Enter task number: ", 0
    
    display_tasks_msg db 10, "==== Current To-Do List ====", 10, 0
    task_added_msg db "Task added successfully!", 10, 0
    task_completed_msg db "Task marked as completed.", 10, 0
    task_deleted_msg db "Task deleted successfully.", 10, 0
    task_limit_msg db "Task limit reached. Cannot add more tasks.", 10, 0
    exit_msg db "Thank you for using the To-Do List Manager!", 10, 0

    no_tasks_msg db "No tasks available.", 10, 0
    invalid_choice_msg db "Invalid choice. Please try again.", 10, 0
    invalid_task_number_msg db "Invalid task number. Try again.", 10, 0

    pending_status db " [Pending]", 10, 0
    completed_status db " [Completed]", 10, 0
    
    num_format db "%d", 0
    str_format db "%s", 10, 0

    task_count dd 1 ; task count (how many tasks)

    MAX_TASKS equ 8 ; max number of task in the list
    TASK_SIZE equ 128 ; 127 character limit (excluding null terminator) to each task

section .bss
    choice resb 1        ; choice is a byte (user input)
    
    task resb TASK_SIZE   ; temporary storage for task description
    task_list resb TASK_SIZE * MAX_TASKS  ; array for task descriptions
    task_status resb MAX_TASKS ; status for each task
    
    task_number resd 1   ; task number input (for completing or deleting)

section .text
    global _main
    extern _printf 
    extern _scanf
    extern _getchar

_main:
    ; display greetings
    push greetings
    call _printf
    add esp, 4

    main_loop_start:
        ; display menu
        push menu
        call _printf
        add esp, 4

        choice_input:
        ; ask user for choice, store in al
        call input_choice

        cmp al, 0
        je case_0
        cmp al, 1
        je case_1
        cmp al, 2
        je case_2
        cmp al, 3
        je case_3
        cmp al, 4
        je case_4


        push invalid_choice_msg
        call _printf
        add esp, 8

        jmp choice_input

        case_0:
            push exit_msg
            call _printf
            add esp, 4

            ret

        case_1:
            push new_task_prompt
            call _printf
            add esp, 4

            push task
            push str_format
            call _scanf
            add esp, 8

            push task
            call append_new_task

        case_2:
            call display_all

        case_3:


        case_4:


        jmp main_loop_start

clear_buffer:
    clear_input_buffer:
        ; read and discard characters until newline
        call _getchar
        cmp eax, 10
        jne clear_input_buffer

    ret

input_choice:
    ; display choice prompt
    push choice_prompt
    call _printf
    add esp, 4

    push choice
    push num_format
    call _scanf
    add esp, 8

    mov al, byte[choice]
    
    ret

append_new_task:
    mov ebp, esp

    ; calculate the offset in task_list
    mov eax, [task_count]
    dec eax  ; subtract 1 to start index from 0
    mov ebx, TASK_SIZE
    mul ebx 

    ; source address of the new task
    mov esi, [ebp + 8] ; new task to append

    ; destination address in task_list
    mov edi, task_list
    add edi, eax

    ; copy task to task_list
    mov ecx, TASK_SIZE
    rep movsb

    ; set task status to pending (0)
    mov eax, [task_count]
    dec eax
    mov byte [task_status + eax], 0

    ; print success message
    push task_added_msg
    call _printf
    add esp, 4
    
    mov esp, ebp
    ret

display_all:
    ret

