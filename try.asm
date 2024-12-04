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
    task_added_msg db 10, "Task added successfully!", 10, 0
    task_completed_msg db 10, "Task %d marked as completed.", 10, 0
    task_deleted_msg db 10, "Task %d deleted successfully.", 10, 0
    exit_msg db 10, "Thank you for using the To-Do List Manager!", 10, 0

    no_tasks_msg db 10, "No tasks available.", 10, 0
    task_limit_msg db 10, "Task limit reached! Cannot add more tasks.", 10, 0
    invalid_choice_msg db 10, "Invalid choice! Please try again.", 10, 0
    invalid_task_number_msg db 10, "Invalid task number! Try again.", 10, 0
    already_marked_msg db 10, "Task is already complete!", 10, 0

    pending_status db "%d. %s (Pending)", 10, 0
    completed_status db "%d. %s (Completed)", 10, 0
    no_display_format db "%d.", 10, 0
    num_format db "%d", 0
    input_format db "%[^.]", 0

    MAX_TASKS equ 8   ; max number of task in the list
    TASK_SIZE equ 128 ; 127 character limit (excluding null terminator) to each task

section .bss
    choice resb 1         ; choice is a byte (user input)
    task resb TASK_SIZE   ; temporary storage for task description
    task_list resb TASK_SIZE * MAX_TASKS  ; array for task descriptions
    task_status resb MAX_TASKS ; status for each task
    task_count resd 1     ; the current number of tasks
    task_number resd 1    ; task number input (for completing or deleting)

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

            ; display message if none
            push no_tasks_msg
            call _printf
            add esp, 4
            jmp main_loop_start

            proceed_display:
            call display_all_task ; display all tasks

            jmp main_loop_start
        case_3:
            cmp byte[task_count], 0
            je no_task_to_mark
            
            call display_all_task 

            input_number:
            ; display prompt for task number
            push task_number_prompt
            call _printf
            add esp, 4

            ; get input for task number to mark as done
            push task_number
            push num_format
            call _scanf
            add esp, 8

            ; store task number and task count to registers for comparison
            mov eax, dword[task_number]
            mov ebx, dword[task_count]

            ; compare if task number is within the task list range
            cmp eax, 1
            jl invalid_number
            cmp eax, ebx
            jg invalid_number

            ; check if the selected task is already complete
            dec eax
            cmp byte[task_status + eax], 1
            je already_marked

            mov byte[task_status + eax], 1 ; if not, mark task as completed (1)
            
            ; display completed task prompt
            inc eax
            push eax
            push task_completed_msg
            call _printf
            add esp, 4

            jmp main_loop_start

            invalid_number:
                ; display prompt and ask for another input
                push invalid_task_number_msg
                call _printf
                add esp, 4
                
                call clear_buffer
                
                jmp input_number

            already_marked:
                ; display prompt and go back to menu
                push already_marked_msg
                call _printf
                add esp, 4

                jmp main_loop_start

            no_task_to_mark:
                ; display prompt for empty list
                push no_tasks_msg
                call _printf
                add esp, 4

                jmp main_loop_start

        case_4:
            cmp byte[task_count], 0
            je no_task_to_delete

            ; display task number prompt
            push task_number_prompt
            call _printf
            add esp, 4

            ; accept input for task number
            push task_number
            push num_format
            call _scanf
            add esp, 8

            ; check for valid task number
            mov eax, dword[task_count]
            cmp dword[task_number], 0
            jle invalid_delete
            cmp dword[task_number], eax
            jg invalid_delete

            ; delete task at corresponding task number
            push dword[task_number]
            call delete_task

            ; re-arrange tasks after deletion
            push task_list
            call rearrange_tasks

            jmp main_loop_start

            invalid_delete:
                push invalid_task_number_msg
                call _printf
                add esp, 4
                
                jmp case_4

            no_task_to_delete:
                ; display prompt for empty list
                push no_tasks_msg
                call _printf
                add esp, 4

                jmp main_loop_start

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
    cmp dword[task_count], MAX_TASKS
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
    
    mov ecx, TASK_SIZE
    rep movsb ; mov the content from source to destination
    
    ; Mark task as pending (0)
    mov ecx, dword[task_count] ; current number of task
    mov byte[task_status + ecx], 0
    inc byte[task_count]

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

    mov ebx, 0
    lea esi, [task_list]

    display_loop_start:
        cmp ebx, MAX_TASKS
        jge display_done

        ; check if task list is empty
        cmp byte[esi], 0
        je display_empty

        ; check for task status
        cmp byte[task_status + ebx], 0
        je display_pending

        ; display completed tasks
        push esi
        inc ebx
        push ebx
        push completed_status
        call _printf
        add esp, 12

        jmp next_display

        display_pending:
            ; display pending tasks
            push esi
            inc ebx
            push ebx
            push pending_status
            call _printf
            add esp, 12

            jmp next_display

        display_empty:
            ; display empty task slots
            inc ebx
            push ebx
            push no_display_format
            call _printf
            add esp, 8

        next_display:
        add esi, TASK_SIZE ; move to the next task

        jmp display_loop_start

    display_done:
    ret

delete_task:
    mov ebp, esp

    mov ebx, [ebp + 4] ; number of task to delete
    
    ; calculate the address of task to be deleted
    mov ecx, ebx
    dec ecx
    mov eax, TASK_SIZE
    mul ecx
    lea edi, [task_list + eax] ; store the address to edi

    ; mov 0 as the first character of the string in the address
    mov al, 0
    stosb

    ; decrement task count
    dec dword[task_count]

    ; display after delete message
    push ebx
    push task_deleted_msg
    call _printf
    add esp, 4

    mov esp, ebp
    ret

rearrange_tasks:
    mov ebp, esp

    mov edi, dword[ebp + 4] ; task list to re-arrange
    
    ; TODO: implement re-arrange after delete

    check_loop_done:
    mov esp, ebp
    ret