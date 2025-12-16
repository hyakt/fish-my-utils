function my_history
  history | fzf --layout default --no-sort | read foo

  if [ $foo ]
    commandline $foo
  else
    commandline ''
  end
end
