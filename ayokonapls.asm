section .data
    greetings db "Welcome to the To-Do List Manager!", 10, 0
    menu db "=== To-Do List Manager ===", 10, "[0] Exit", 10, "[1] Add Task", 10, "[2] Display Tasks", 10, "[3] Mark Task as Completed", 10, "[4] Delete Task", 10, 0
    exit_msg db "Thank you for using the To-Do List Manager!", 10, 0
    choice_prompt db "Enter your choice (0-4): ", 0
    add_prompt db "Enter a task: ", 0
    task_added_msg db "Task added successfully!", 10, 0
    display_tasks_msg db 10, "==== Current To-Do List ====", 10, 0
    no_tasks_msg db "No tasks available.", 10, 0
    invalid_choice_msg db "Invalid choice. Please try again.", 10, 0
    task_completed_msg db "Task marked as completed.", 10, 0
    task_deleted_msg db "Task deleted successfully.", 10, 0
    task_limit_msg db "Task limit reached. Cannot add more tasks.", 10, 0
    task_number_prompt db "Enter task number: ", 0
    invalid_task_number_msg db "Invalid task number. Try again.", 10, 0
    pending_status db " [Pending]", 10, 0
    completed_status db " [Completed]", 10, 0
    char_format db "%d", 0
    task_format db "%s", 10, 0
    max_tasks equ 8

section .bss
    choice resb 1        ; choice is a byte (user input)
    tasks resb 128 * max_tasks  ; array for task descriptions
    task_status resb max_tasks ; status for each task
    task_count resd 1    ; task count (how many tasks)
    temp_task resb 128   ; temporary storage for task description
    task_number resd 1   ; task number input (for completing or deleting)

section .text
    global _main
    extern _printf, _scanf, _exit, _strlen, _strcpy

_main:
    ; display the greeting message
    push greetings
    call _printf
    add esp, 4

    main_loop_start:
        ; display the menu choices
        push menu
        call _printf
        add esp, 4

        ; pass 2 arguments and call input_choice function
        push choice_prompt ; prompt to display
        call input_choice

        cmp byte [choice], 0
        je case_0
        cmp byte [choice], 1
        je case_1
        cmp byte [choice], 2
        je case_2
        cmp byte [choice], 3
        je case_3
        cmp byte [choice], 4
        je case_4

        ; Handle invalid choice
        jmp invalid_choice_handler

        case_0:
            ; Exit the program with a thank you message
            push exit_msg
            call _printf
            add esp, 4
            call _exit  ; Exit the program

        case_1:
            ; Add a new task
            lea eax, [add_prompt]
            call print_string
            lea eax, [temp_task]
            push eax
            push dword task_format
            call _scanf
            add esp, 8

            ; Check task limit
            mov eax, [task_count]
            cmp eax, max_tasks
            jge task_limit_reached

            ; Store task description
            mov ecx, [task_count]
            imul eax, ecx, 128
            lea edi, [tasks + eax]
            lea esi, [temp_task]
            rep movsb

            ; Mark task as pending (0)
            mov byte [task_status + ecx], 0
            inc dword [task_count]

            ; Confirm task addition
            lea eax, [task_added_msg]
            call print_string

            ; Return to menu
            jmp main_loop_start

        task_limit_reached:
            lea eax, [task_limit_msg]
            call print_string
            jmp main_loop_start

        case_2:
            ; Display the tasks
            lea eax, [display_tasks_msg]
            call print_string

            ; Check if any tasks exist
            mov eax, [task_count]
            test eax, eax
            jz no_tasks_to_display

            ; Loop through tasks and display each
            xor ecx, ecx

        display_loop:
            cmp ecx, eax
            jge end_display

            ; Print task number
            mov edx, ecx
            inc edx
            push edx
            push dword char_format
            call _printf
            add esp, 8

            ; Print task description
            imul edx, ecx, 128
            lea esi, [tasks + edx]
            push esi
            push dword task_format
            call _printf
            add esp, 8

            ; Print task status (pending/completed)
            movzx edx, byte [task_status + ecx]
            cmp edx, 0
            je print_pending
            lea eax, [completed_status]
            jmp print_status

        print_pending:
            lea eax, [pending_status]
        print_status:
            push eax
            call print_string
            add esp, 4

            inc ecx
            jmp display_loop

        no_tasks_to_display:
            lea eax, [no_tasks_msg]
            call print_string

        end_display:
            jmp main_loop_start

        case_3:
            ; Mark a task as completed
            lea eax, [task_number_prompt]
            call print_string
            push task_number
            push dword char_format
            call _scanf
            add esp, 8

            ; Validate task number
            mov ecx, [task_number]
            dec ecx
            cmp ecx, [task_count]
            jae invalid_task_number

            ; Mark task as completed (1)
            mov byte [task_status + ecx], 1
            lea eax, [task_completed_msg]
            call print_string
            jmp main_loop_start

        case_4:
            ; Delete a task by its number
            lea eax, [task_number_prompt]
            call print_string
            push task_number
            push dword char_format
            call _scanf
            add esp, 8

            ; Validate task number
            mov ecx, [task_number]
            dec ecx
            mov eax, [task_count]
            cmp ecx, eax
            jae invalid_task_number

            ; Shift tasks to delete the selected one
            dec eax
            cmp ecx, eax
            je delete_last_task

            ; Shift tasks
            mov esi, ecx
            inc esi
            imul esi, 128
            mov edi, ecx
            imul edi, 128
            lea esi, [tasks + esi]
            lea edi, [tasks + edi]
            mov edx, eax
            sub edx, ecx
            dec edx
            imul edx, 128
            rep movsb

            ; Shift task statuses
            lea esi, [task_status + ecx + 1]
            lea edi, [task_status + ecx]
            mov edx, eax
            sub edx, ecx
            dec edx
            rep movsb

        delete_last_task:
            dec dword [task_count]
            lea eax, [task_deleted_msg]
            call print_string
            jmp main_loop_start

        invalid_task_number:
            lea eax, [invalid_task_number_msg]
            call print_string
            jmp main_loop_start

        invalid_choice_handler:
            lea eax, [invalid_choice_msg]
            call print_string
            jmp main_loop_start

print_string:
    push eax
    call _printf
    add esp, 4
    ret

input_choice:
    ; Prompt the user for input
    lea eax, [choice_prompt]
    call print_string

    ; Read user input
    lea eax, [choice]
    push eax
    push dword char_format
    call _scanf
    add esp, 8
    ret