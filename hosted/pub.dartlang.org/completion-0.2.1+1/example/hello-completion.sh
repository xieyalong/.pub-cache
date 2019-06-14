#
# Installation:
#
# Via shell config file  ~/.bashrc  (or ~/.zshrc)
#
#   Append the contents to config file
#   'source' the file in the config file
#
# You may also have a directory on your system that is configured
#    for completion files, such as:
#
#    /usr/local/etc/bash_completion.d/

###-begin-hello.dart-completion-###

if type complete &>/dev/null; then
  __hello_dart_completion() {
    local si="$IFS"
    IFS=$'\n' COMPREPLY=($(COMP_CWORD="$COMP_CWORD" \
                           COMP_LINE="$COMP_LINE" \
                           COMP_POINT="$COMP_POINT" \
                           hello.dart completion -- "${COMP_WORDS[@]}" \
                           2>/dev/null)) || return $?
    IFS="$si"
  }
  complete -F __hello_dart_completion hello.dart
elif type compdef &>/dev/null; then
  __hello_dart_completion() {
    si=$IFS
    compadd -- $(COMP_CWORD=$((CURRENT-1)) \
                 COMP_LINE=$BUFFER \
                 COMP_POINT=0 \
                 hello.dart completion -- "${words[@]}" \
                 2>/dev/null)
    IFS=$si
  }
  compdef __hello_dart_completion hello.dart
elif type compctl &>/dev/null; then
  __hello_dart_completion() {
    local cword line point words si
    read -Ac words
    read -cn cword
    let cword-=1
    read -l line
    read -ln point
    si="$IFS"
    IFS=$'\n' reply=($(COMP_CWORD="$cword" \
                       COMP_LINE="$line" \
                       COMP_POINT="$point" \
                       hello.dart completion -- "${words[@]}" \
                       2>/dev/null)) || return $?
    IFS="$si"
  }
  compctl -K __hello_dart_completion hello.dart
fi

###-end-hello.dart-completion-###

## Generated 2018-04-24 15:45:52.542816Z
## By /Users/kevmoo/source/github/completion.dart/bin/shell_completion_generator.dart
