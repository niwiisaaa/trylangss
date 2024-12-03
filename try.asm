section .data
    greetings db "Welcome to the To-Do List Manager!", 10, 0
    menu db 10, "=== To-Do List Manager ===", 10, 
         db "[0] Exit", 10, 
         db "[1] Add Task", 10, 
         db "[2] Display Tasks", 10, 
         db "[3] Mark Task as Completed", 10, 
         db "[4] Delete Task", 10, 0
    
    choice_prompt db "Enter your choice (0-4): ", 0
    new_task_prompt db 10, "Enter a task to add (add a period to finish input): ", 10, 0
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

    pending_status db "%d. %s (Pending)", 10, 0
    completed_status db "%d. %s (Completed)", 10, 0
    no_display_format db "%d.", 10, 0
    num_format db "%d", 0
    input_format db "%[^.]", 0

    MAX_TASKS equ 8 ; max number of task in the list
    TASK_SIZE equ 128 ; 127 character limit (excluding null terminator) to each task

section .bss
    choice resb 1        ; choice is a byte (user input)
    task resb TASK_SIZE   ; temporary storage for task description
    task_list resb TASK_SIZE * MAX_TASKS  ; array for task descriptions
    task_status resb MAX_TASKS ; status for each task
    task_count resd 1 ; the current number of tasks
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

    ; initialize number of task to 0
    mov dword[task_count], 0

    main_loop_start:
        ; display menu
        push menu
        call _printf
        add esp, 4

        choice_input:
            ; ask user for choice, store in al
            call input_choice

            mov al, byte[choice]
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
            push input_format
            call _scanf
            add esp, 8

            call clear_buffer

            push task
            call append_new_task
            add esp, 4

            jmp main_loop_start

        case_2:
            ; check if there is no task
            cmp dword[task_count], 0
            jne proceed_display

            ; display prompt is none
            push no_tasks_msg
            call _printf
            add esp, 4
            jmp main_loop_start

            proceed_display:
            call display_all_task ; display all tasks

            jmp main_loop_start
        case_3:


        case_4:

clear_buffer:
    clear_input_buffer:
        ; read and discard characters until newline
        call _getchar
        cmp eax, 10
        jne clear_input_buffer

    ret

input_choice:
    ; create stack frame
    mov ebp, esp

    start_input:
        ; display prompt
        push choice_prompt
        call _printf
        add esp, 4

        ; get input for choice
        push choice
        push num_format
        call _scanf
        add esp, 8

        ; check if user entered a non-numeric value
        cmp eax, 1
        jne invalid_choice

        ; check if input is within range
        cmp dword [choice], 0
        jl invalid_choice
        cmp dword [choice], 4
        jg invalid_choice

        ; destroy stack frame and return to caller
        mov esp, ebp
        ret

    invalid_choice:
        ; clear buffer if input fails
        call clear_buffer

        ; display error message
        push invalid_choice_msg
        call _printf
        add esp, 4

        ; loop back to start of input
        jmp start_input

append_new_task:
    mov ebp, esp
    
    ; check if maximum number of task is reached
    cmp ecx, MAX_TASKS
    jne proceed_append

    ; display task limit message
    push task_limit_msg
    call _printf
    add esp, 4
    jmp skip_append

    proceed_append:
    ; Store task description
    mov ecx, dword[task_count] ; current number of task
    mov eax, TASK_SIZE
    mul ecx
    lea edi, [task_list + eax] ; address of task_list as destination
    mov esi, [ebp + 4] ; address of task as source
    
    add esi, 1 ; exclude the newline at the beginning
    
    push ecx ; preserve ecx value to stack

    mov ecx, TASK_SIZE
    rep movsb ; mov the content from source to destination
    
    pop ecx ; restore ecx value

    ; Mark task as pending (0)
    mov byte [task_status + ecx], 0
    inc dword [task_count]

    ; print success message
    push task_added_msg
    call _printf
    add esp, 4
    
    skip_append:
    mov esp, ebp
    ret

display_all_task:
    push display_tasks_msg
    call _printf
    add esp, 4

    mov ebx, 1
    lea esi, [task_list]

    display_loop_start:
        cmp ebx, MAX_TASKS
        jg display_done

        push esi
        mov eax, 0
        lodsb ; store first character in esi to al
        pop esi

        cmp al, 0
        je display_empty

        ; check for task status
        dec ebx
        mov eax, [task_status + ebx] 
        inc ebx
        cmp eax, 0
        je display_pending

        ; display completed tasks
        push esi
        push ebx
        push completed_status
        call _printf
        add esp, 12

        jmp next_display

        display_pending:
            ; display pending tasks
            push esi
            push ebx
            push pending_status
            call _printf
            add esp, 12

            jmp next_display

        display_empty:
            ; display pending tasks
            push ebx
            push no_display_format
            call _printf
            add esp, 8

        next_display:
        inc ebx
        add esi, TASK_SIZE ; move to the next task

        jmp display_loop_start

    display_done:
    ret

