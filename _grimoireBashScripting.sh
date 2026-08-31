# BEGIN : _grimoire.sh
# ... grimoire for linux bash scripting 
# 1. Grimoire : Collection of inventories 
# 2. Inventory : Collection of syntaxes or object explanations to help programming 
# 
# (General X Specifics) 
# 1. General ; common to programming languagens in general 
# 2. Specifics ; to solve specific problems or use specific frameworks 
#
# [ LLM Prompt ]
# > Inventories are concise comment-blocks listing useful information to help programming 
# ... each line is composed of syntax and short explanation. Example of inventory:
#
# Inventory : functions { Linux, Bash Scripting }
# 1. function_name() { ... } ; Standard Bash function definition syntax.
# 2. function function_name { ... } ; Alternative, explicit keyword function definition syntax.
# 3. function_name arg1 arg2 ; Function invocation. Calls the function and passes arguments separated by spaces.
# 4. return N ; Terminates a function and returns an exit status code `N` (0-255) to the calling shell.
#
# > Constraints:
# 1. Its a cheat-sheet to be placed as comment-block on script.
# 2. Keep the comment-block style.
# 3. Each line should be something like: 
#     N. SYNTAX ; SHORTDESCRIPTION 
# 4. Be concise.
# 5. Each inventory should have no more than 25 items
# > Can you make this(these) inventory(inventories) ? 

# === GENERAL === 

# Inventory : variables/types { Linux, Bash Scripting }
# 1. var="value" ; Assign string or number (no spaces around `=`).
# 2. local var="val" ; Restrict variable scope to the enclosing function.
# 3. readonly var="val" ; Mark variable as read-only (constant).
# 4. echo "$var" ; Expand variable value (double quotes preserve whitespace).
# 5. echo '${var}' ; Literal expansion (single quotes prevent variable evaluation).
# 6. ${var:-default} ; Use `default` if `var` is unset or empty.
# 7. ${var:=default} ; Set `var` to `default` if previously unset or empty.
# 8. ${#var} ; Return length of `var` string.
# 9. ${var:offset:length} ; Substring extraction starting at `offset`.
# 10. ${var#pattern} ; Strip shortest match of `pattern` from start.
# 11. ${var##pattern} ; Strip longest match of `pattern` from start.
# 12. ${var%pattern} ; Strip shortest match of `pattern` from end.
# 13. ${var%%pattern} ; Strip longest match of `pattern` from end.
# 14. ${var/search/replace} ; Replace first match of `search` with `replace`.
# 15. ${var//search/replace} ; Replace all matches of `search` with `replace`.
# 16. declare -i var=10 ; Declare integer variable for arithmetic calculations.
# 17. declare -a arr=(a b c) ; Declare indexed array.
# 18. declare -A dict=([k]=v) ; Declare associative array (hashmap/dictionary).
# 19. ${arr[0]} ; Access element at index 0 in array.
# 20. ${arr[@]} ; Expand all elements of an array.
# 21. ${#arr[@]} ; Return total element count in array.
# 22. arr+=(val) ; Append an element to an indexed array.
# 23. unset var ; Delete variable or clear array element.
# 24. export VAR="val" ; Export variable to environment of child processes.

# Inventory : functions { Linux, Bash Scripting }
# 1. func() { ... } ; Standard Bash function definition syntax.
# 2. function func { ... } ; Alternative explicit keyword function definition syntax.
# 3. func arg1 arg2 ; Invoke function with positional arguments separated by spaces.
# 4. $1, $2, ... $9 ; Access first, second, through ninth positional arguments inside function.
# 5. ${10} ; Access positional arguments beyond 9 using curly braces.
# 6. $# ; Total count of arguments passed to function.
# 7. $@ ; All arguments passed to function as separate quoted strings.
# 8. $* ; All arguments passed to function joined into single string.
# 9. return N ; Exit function with status code `N` (0-255).
# 10. local var="val" ; Scope variable strictly inside declaring function.
# 11. shift N ; Drop first `N` arguments, shifting remaining arguments left.
# 12. $(func) ; Command substitution: capture function's stdout into variable.
# 13. export -f func ; Export function to make it available in child subshells.
# 14. unset -f func ; Delete/undefine a defined function.

# Inventory : conditional expressions { Linux, Bash Scripting }
# 1. [[ -e path ]] ; True if path exists (file, directory, socket, etc.).
# 2. [[ -f path ]] ; True if path exists and is a regular file.
# 3. [[ -d path ]] ; True if path exists and is a directory.
# 4. [[ -r path ]] ; True if path exists and is readable.
# 5. [[ -w path ]] ; True if path exists and is writable.
# 6. [[ -x path ]] ; True if path exists and is executable.
# 7. [[ -s path ]] ; True if path exists and size is greater than zero.
# 8. [[ -L path ]] ; True if path exists and is a symbolic link.
# 9. [[ -z "$str" ]] ; True if string length is zero (empty).
# 10. [[ -n "$str" ]] ; True if string length is non-zero (not empty).
# 11. [[ "$a" == "$b" ]] ; True if string `a` equals string `b`.
# 12. [[ "$a" != "$b" ]] ; True if string `a` does not equal string `b`.
# 13. [[ "$a" < "$b" ]] ; True if string `a` sorts before string `b` lexicographically.
# 14. (( a == b )) ; Numeric equality test inside arithmetic expression.
# 15. (( a != b )) ; Numeric inequality test.
# 16. (( a < b )) ; Numeric less than test.
# 17. (( a <= b )) ; Numeric less than or equal to test.
# 18. (( a > b )) ; Numeric greater than test.
# 19. (( a >= b )) ; Numeric greater than or equal to test.
# 20. [[ cond1 && cond2 ]] ; Logical AND: true if both conditions pass.
# 21. [[ cond1 || cond2 ]] ; Logical OR: true if either condition passes.
# 22. [[ ! cond ]] ; Logical NOT: negates condition result.

# Inventory : regex conditionals { Linux, Bash Scripting }
# 1. [[ "$str" =~ ^pat ]] ; Anchor match to start of string using `^`.
# 2. [[ "$str" =~ pat$ ]] ; Anchor match to end of string using `$`.
# 3. [[ "$str" =~ [a-z] ]] ; Match any single character within specified character class range.
# 4. [[ "$str" =~ [^0-9] ]] ; Match any single character NOT in specified character class (negation).
# 5. [[ "$str" =~ a|b ]] ; Alternation: match expression `a` OR expression `b`.
# 6. [[ "$str" =~ . ]] ; Wildcard match for any single character except newline.
# 7. [[ "$str" =~ a* ]] ; Match preceding element zero or more times (greedy).
# 8. [[ "$str" =~ a+ ]] ; Match preceding element one or more times.
# 9. [[ "$str" =~ a? ]] ; Match preceding element zero or one time (optional).
# 10. [[ "$str" =~ a{n} ]] ; Match preceding element exactly `n` times.
# 11. [[ "$str" =~ a{n,m} ]] ; Match preceding element between `n` and `m` times.
# 12. [[ "$str" =~ (pat) ]] ; Group expressions and capture matched string into `${BASH_REMATCH}`.
# 13. ${BASH_REMATCH[0]} ; Access full regex match result string.
# 14. ${BASH_REMATCH[1]} ; Access contents of first parenthesized capture group.
# 15. regex='^[0-9]+$' ; Store complex regex in variable to prevent shell escaping issues.
# 16. [[ "$str" =~ $regex ]] ; Evaluate string against regex pattern variable without quotes around pattern.
# 17. [[ "$str" =~ [[:digit:]] ]] ; Match POSIX character class for numbers (0-9).
# 18. [[ "$str" =~ [[:alpha:]] ]] ; Match POSIX character class for alphabetic letters.
# 19. [[ "$str" =~ [[:alnum:]] ]] ; Match POSIX character class for alphanumeric characters.
# 20. [[ "$str" =~ [[:space:]] ]] ; Match POSIX character class for whitespace characters.

# Inventory : conditional structures { Linux, Bash Scripting }
# 1. if [[ cond ]]; then ... fi ; Single-line standard `if` conditional block syntax.
# 2. if [[ cond ]]; then ... else ... fi ; Standard `if-else` branching control structure.
# 3. if [[ c1 ]]; then ... elif [[ c2 ]]; then ... fi ; Multi-branch `if-elif-else` control flow structure.
# 4. [[ cond ]] && cmd ; Inline conditional execution: runs `cmd` only if `cond` evaluates true.
# 5. [[ cond ]] || cmd ; Fallback conditional execution: runs `cmd` only if `cond` evaluates false.
# 6. [[ cond ]] && cmd1 || cmd2 ; Ternary construct: runs `cmd1` on true, `cmd2` on false (requires `cmd1` success).
# 7. case "$var" in pat) ... ;; esac ; Multi-way branch matching `$var` against glob pattern `pat`.
# 8. case pattern alternatives ; `pat1|pat2)` matches either pattern in case statement block.
# 9. case default fallback ; `*)` wildcard catch-all branch executed if no prior patterns match.
# 10. case fallthrough syntax ; `;;&` continues testing subsequent patterns in case block.
# 11. case execute-next syntax ; `;&` unconditionally executes next clause body in case block.

# Inventory : for loops { Linux, Bash Scripting }
# 1. for i in 1 2 3; do ... done ; Standard list iteration loop syntax.
# 2. for i in {1..10}; do ... done ; Iterate over sequence range expansion from 1 through 10.
# 3. for i in {1..10..2}; do ... done ; Range expansion with step size 2.
# 4. for file in *.txt; do ... done ; Iterate over filenames matching glob pattern.
# 5. for i in "${arr[@]}"; do ... done ; Iterate over each element in an indexed array safely.
# 6. for k in "${!dict[@]}"; do ... done ; Iterate over all keys of an associative array.
# 7. for ((i=0; i<10; i++)); do ... done ; C-style three-expression arithmetic loop syntax.
# 8. for i in $(cmd); do ... done ; Word-split output iteration loop (fragile with space-containing items).
# 9. break ; Instantly exit loop and resume execution after `done`.
# 10. break N ; Exit `N` levels of nested loops.
# 11. continue ; Skip remaining body in current iteration and evaluate next loop cycle.
# 12. continue N ; Skip to next cycle of `N`th enclosing loop level.

# Inventory : while loops { Linux, Bash Scripting }
# 1. while [[ cond ]]; do ... done ; Loop continuously as long as condition evaluates true.
# 2. while true; do ... done ; Infinite loop structure (terminate via `break` or process signal).
# 3. while read -r line; do ... done < file ; Read file line-by-line while keeping backslashes literal (`-r`).
# 4. cmd | while read -r line; do ... done ; Read stream line-by-line via pipe (executes loop in subshell).
# 5. while IFS= read -r line; do ... done ; Read lines preserving leading and trailing whitespace.
# 6. while read -r u p; do ... done < file ; Read space-delimited fields into separate variables `u` and `p`.
# 7. until [[ cond ]]; do ... done ; Loop continuously as long as condition evaluates false.
# 8. while (( count < 10 )); do ... done ; Numeric condition while loop using C-style arithmetic syntax.
# 9. while flag=; [[ cond ]]; do ... done ; Execute code within loop condition step before evaluation.

# Inventory : command operators { Linux, Bash Scripting }
# 1. cmd1 ; cmd2 ; Sequential execution: runs `cmd2` after `cmd1` finishes regardless of success.
# 2. cmd1 & ; Async execution: launches `cmd1` in background subshell without blocking.
# 3. cmd1 && cmd2 ; Logical AND: executes `cmd2` only if `cmd1` exits with success status (0).
# 4. cmd1 || cmd2 ; Logical OR: executes `cmd2` only if `cmd1` exits with failure status (non-zero).
# 5. cmd1 | cmd2 ; Pipe: routes stdout of `cmd1` to stdin of `cmd2`.
# 6. cmd1 |& cmd2 ; Pipe stdout AND stderr of `cmd1` to stdin of `cmd2` (Bash 4.0+ short syntax).
# 7. cmd > file ; Redirect stdout to file (overwrites existing file contents).
# 8. cmd >> file ; Redirect stdout to file (appends to end of file).
# 9. cmd < file ; Redirect stdin from file.
# 10. cmd 2> file ; Redirect stderr to file (overwrites existing contents).
# 11. cmd 2>> file ; Redirect stderr to file (appends to end of file).
# 12. cmd > file 2>&1 ; Redirect stdout and stderr to file (traditional syntax).
# 13. cmd &> file ; Redirect stdout and stderr to file (Bash short syntax).
# 14. cmd &>> file ; Redirect stdout and stderr appending to file.
# 15. cmd > /dev/null 2>&1 ; Silence output entirely by redirecting stdout and stderr to null device.
# 16. cmd << EOF ... EOF ; Here-doc: pass multiline string block to stdin.
# 17. cmd << 'EOF' ... EOF ; Here-doc with single-quoted delimiter to disable variable expansion inside block.
# 18. cmd <<< "str" ; Here-string: pass single string variable/literal to stdin.
# 19. $(cmd) ; Command substitution: run `cmd` and capture stdout output as text value.
# 20. `cmd` ; Legacy command substitution syntax (prefer `$()` for readability and nesting).
# 21. <(cmd) ; Process substitution: pass stdout of `cmd` as temporary named pipe filename argument.
# 22. >(cmd) ; Process substitution: create sink named pipe filename that pipes into stdin of `cmd`.
# 23. { cmd1; cmd2; } ; Group commands to execute sequentially in current shell scope.
# 24. (cmd1; cmd2) ; Group commands to execute sequentially inside isolated subshell environment.
# 25. ! cmd ; Negate exit status code of command (turns 0 into 1, and non-zero into 0).

# === SPECIFICS === 

# END 