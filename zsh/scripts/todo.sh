#!/bin/bash
todoFile=$NOTES/TODO.md

# Function to add a new task to the todo list
add_task() {
    local description="$1"
    local category="$2"
    local complete_by="$3"

    if [ -z "$category" ]; then
        category="Uncategorized"
    fi

    if [ -z "$complete_by" ]; then
        complete_by="N/A"
    fi

    echo "- [ ] $description [$category] $complete_by" >> $todoFile
    echo "Task added: $description [$category] $complete_by"
}

# Function to mark a task as done
mark_task_as_done() {
    local task_id="$1"

    # local line_number
    # line_number=$(awk -v id="$task_id" '/- \[ \]/{i++}i==id{print NR}' $todoFile)

    # if [ -z "$line_number" ]; then
    #     echo "Task ID $task_id not found."
    # fi

    sed -i '' "${task_id}s/\[ \]/\[x\]/" $todoFile
    echo "Task $task_id marked as done"
}

# Function to print the todo list
print_todo_list() {
    local show_done=$1
    echo "Todo List:"
    if [ "$show_done" = "true" ]; then
        mdcat -n $todoFile
    else
        grep -n "\[ ]" $todoFile
    fi
}

# Function to list tasks that must be completed today
list_tasks_due_today() {
    local today=$(date +"%Y-%m-%d")
    echo "Tasks due today ($today):"
    awk -v date="$today" -F' ' '$4 == date' $todoFile | grep -n "\[ ]"
}

# Check if $todoFile file exists, otherwise create it
if [ ! -f $todoFile ]; then
    touch $todoFile
    echo "# Todo List" >> $todoFile
fi

# Process command-line arguments
if [ "$1" = "add" ]; then
    # Check if at least the description is provided
    if [ $# -lt 2 ]; then
        echo "Usage: $0 add <description> [<category> <complete_by>]"
    fi

    # Call the add_task function with the provided task description, category, and complete by date
    add_task "$2" "$3" "$4"

elif [ "$1" = "done" ]; then
    # Check if the task ID is provided
    if [ $# -ne 2 ]; then
        echo "Usage: $0 done <task_id>"
    fi

    # Call the mark_task_as_done function with the provided task ID
    mark_task_as_done "$2"

elif [ "$1" = "list" ]; then
    # Print the todo list without done tasks
    print_todo_list "false"

elif [ "$1" = "list-all" ]; then
    # Check if no extra arguments are provided
    if [ $# -ne 1 ]; then
        echo "Usage: $0 list-all"
    fi

    # Print the todo list with all tasks
    print_todo_list "true"

elif [ "$1" = "due-today" ]; then
    # Check if no extra arguments are provided
    if [ $# -ne 1 ]; then
        echo "Usage: $0 due-today"
    fi

    # List tasks due today
    list_tasks_due_today

else
    # Print the todo list without done tasks
    print_todo_list "false"
fi
