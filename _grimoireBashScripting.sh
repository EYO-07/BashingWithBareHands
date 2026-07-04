# BEGIN : bash scripting inventories 

# === Bash Scripting =======================================================================

# Inventory : command operators { Linux, Bash Scripting }
# 1. `&` ; Runs the preceding command in the background, freeing up the terminal.
# 2. `;` ; Sequential execution operator; runs commands one after another regardless of success.
# 3. `&&` ; Logical AND operator; runs the second command only if the first command succeeds (exit code 0).
# 4. `||` ; Logical OR operator; runs the second command only if the first command fails (non-zero exit code).
# 5. `|` ; Pipe operator; passes the standard output (stdout) of the first command as standard input (stdin) to the next.
# 6. `>` ; Redirects standard output to a file, overwriting the file's existing contents.
# 7. `>>` ; Redirects standard output to a file, appending the content to the end of the file.
# 8. `<` ; Redirects standard input to a command from a specified file.
# 9. `2>` ; Redirects standard error (stderr) to a specified file.
# 10. `&>` ; Redirects both standard output (stdout) and standard error (stderr) to a file.

# Inventory : variables and aliases { Linux, Bash Scripting }
# 1. `NAME=value` ; Variable assignment; defines a local user variable (no spaces around `=`).
# 2. `$NAME` or `${NAME}` ; Variable expansion; references and retrieves the value stored in a variable.
# 3. `export NAME=value` ; Environment variable definition; makes the variable accessible to child processes and shells.
# 4. `alias name='command'` ; Creates a shortcut/alias for a longer command or sequence of commands.
# 5. `unalias name` ; Removes a previously defined command alias.
# 6. `$0`, `$1`, `$2`... ; Positional parameters; `$0` is the script name, `$1` onward are command-line arguments.
# 7. `$#` ; Special variable; holds the total number of arguments passed to the script.
# 8. `$?` ; Special variable; holds the exit status code of the most recently executed foreground command.
# 9. `$$` ; Special variable; holds the Process ID (PID) of the current shell session or script.
# 10. `local NAME=value` ; Declares a local variable inside a function, preventing it from leaking into the global scope.

# Inventory : functions { Linux, Bash Scripting }
# 1. `function_name() { ... }` ; Standard Bash function definition syntax.
# 2. `function function_name { ... }` ; Alternative, explicit keyword function definition syntax.
# 3. `function_name arg1 arg2` ; Function invocation; calls the function and passes arguments separated by spaces.
# 4. `return N` ; Terminates a function and returns an exit status code `N` (0-255) to the calling shell.

# Inventory : conditionals { Linux, Bash Scripting }
# 1. `if [ condition ]; then ... fi` ; Single-clause conditional; uses standard test commands (`[ ]`) to evaluate logic.
# 2. `if [[ condition ]]; then ... else ... fi` ; Conditional with fallback; uses enhanced Bash brackets (`[[ ]]`) for safer evaluation.
# 3. `if ...; elif ...; then ... fi` ; Multi-clause conditional; checks secondary conditions if preceding ones fail.
# 4. `case "$var" in pattern1) ... ;; pattern2) ... ;; *) ... esac` ; Pattern-matching conditional; branches execution based on string matching.

# Inventory : loops { Linux, Bash Scripting }
# 1. `for var in list; do ... done` ; For-in loop; iterates over a predefined list of items or words.
# 2. `for ((i=0; i<max; i++)); do ... done` ; C-style for loop; evaluates 3-expression arithmetic cycles for counting.
# 3. `while [ condition ]; do ... done` ; While loop; continuously executes a block as long as the condition evaluates to true.
# 4. `until [ condition ]; do ... done` ; Until loop; continuously executes a block until the condition becomes true (runs while false).
# 5. `break` ; Control statement; immediately terminates the innermost enclosing loop.
# 6. `continue` ; Control statement; skips the remainder of the current loop iteration and moves to the next evaluation.

# === Bash Scripting { conditionals } ==========================================================

# 1. `if [ condition ]; then ... fi` ; Single-clause conditional; uses standard test commands (`[ ]`) to evaluate logic.
#    - Integer comparisons: -eq (equal), -ne (not equal), -gt (greater than), -ge (>=), -lt (less than), -le (<=)
#    - String comparisons: = (equal), != (not equal), -z (empty), -n (not empty)
#    - File tests: -e (exists), -f (regular file), -d (directory), -r (readable), -w (writable), -x (executable)
#    - Example: if [ "$num" -gt 10 ]; then echo "Greater"; fi
#    - Note: Requires spaces around brackets; variables should be quoted to prevent word splitting.

# 2. `if [[ condition ]]; then ... else ... fi` ; Conditional with fallback; uses enhanced Bash brackets (`[[ ]]`) for safer evaluation.
#    - Supports all `[ ]` operators plus: == (string equal), != (string not equal), < and > (lexicographic, no escape needed)
#    - Pattern matching: == with wildcards (e.g., [[ "$str" == *.txt ]])
#    - Regex matching: =~ operator (e.g., [[ "$email" =~ ^[a-z]+@ ]])
#    - Logical operators: && (AND), || (OR), ! (NOT) can be used inside [[ ]]
#    - Safer: No word splitting on unquoted variables; preferred in Bash scripts.
#    - Example: if [[ "$var" == *Linux* && -n "$var" ]]; then echo "Valid"; fi

# 3. `if ...; elif ...; then ... fi` ; Multi-clause conditional; checks secondary conditions if preceding ones fail.
#    - Structure: if [ cond1 ]; then ...; elif [ cond2 ]; then ...; else ...; fi
#    - Allows chaining multiple mutually exclusive conditions.
#    - Can mix `[ ]`, `[[ ]]`, or `(( ))` (arithmetic) in different clauses.
#    - Example: if [ "$age" -lt 18 ]; then echo "Minor"; elif [ "$age" -lt 65 ]; then echo "Adult"; else echo "Senior"; fi
#    - Tip: Use `elif` instead of nested `if` inside `else` for better readability.

# 4. `case "$var" in pattern1) ... ;; pattern2) ... ;; *) ... esac` ; Pattern-matching conditional; branches execution based on string matching.
#    - Matches variable against glob patterns (wildcards *, ?, [...])
#    - Multiple values per branch: pattern1|pattern2) ... ;;
#    - Case-insensitive matching: shopt -s nocasematch (Bash 4+)
#    - Default branch: * ) ... ;; (catches all unmatched values)
#    - Example: case "$day" in Mon|Tue|Wed|Thu|Fri) echo "Weekday" ;; Sat|Sun) echo "Weekend" ;; *) echo "Invalid" ;; esac
#    - Use case for clean branching on a single variable with multiple discrete values or patterns.

# 5. `(( arithmetic_expression ))` ; Arithmetic conditional; evaluates numeric expressions directly.
#    - Operators: ==, !=, <, <=, >, >=, +, -, *, /, %
#    - No need for -eq, -gt, etc.; variables used without $ inside (( ))
#    - Returns exit status 0 if expression is non-zero (true), 1 if zero (false)
#    - Example: if (( num > 10 && num < 20 )); then echo "In range"; fi
#    - Ideal for numeric comparisons and calculations; Bash-specific.

# 6. Logical combinators: `&&` (AND), `||` (OR), `!` (NOT) ; Combine conditions outside or inside test constructs.
#    - With `[ ]`: [ cond1 ] && [ cond2 ] (both must succeed); [ cond1 ] || [ cond2 ] (either succeeds)
#    - With `[[ ]]`: [[ cond1 && cond2 ]] (preferred for readability in Bash)
#    - Negation: ! [ cond ] or [[ ! cond ]]
#    - Short-circuit evaluation: second condition only evaluated if needed.
#    - Example: [[ -f "$file" && -r "$file" ]] && echo "Readable file exists"

# 7. File comparison operators: `-nt` (newer than), `-ot` (older than), `-ef` (same inode/hard link)
#    - Usage: [ "$file1" -nt "$file2" ] — true if file1 is newer than file2
#    - Usage: [ "$file1" -ef "$file2" ] — true if both files refer to the same inode
#    - Useful for backup scripts, caching logic, or dependency checks.
#    - Example: if [ "$config" -nt "$backup" ]; then echo "Config updated"; fi

# 8. Variable substitution conditionals: `${var:-default}`, `${var:=default}`, `${var:+value}`, `${var:?error}`
#    - ${var:-default} — use default if var is unset or empty
#    - ${var:=default} — assign default if var is unset or empty
#    - ${var:+value} — use value if var is set and non-empty
#    - ${var:?error} — exit with error if var is unset or empty
#    - Lightweight alternative to if for simple defaults or validation.
#    - Example: echo "${PORT:-8080}" # uses 8080 if PORT is not set   




# -- END