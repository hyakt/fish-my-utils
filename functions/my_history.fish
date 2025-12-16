function my_history --description "Search command history using fzf"
  history | fzf --layout default --no-sort | read foo

  if [ $foo ]
    commandline $foo
  else
    commandline ''
  end
end
