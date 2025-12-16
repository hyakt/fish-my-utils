function my_checkout_git_branch --description "Select and checkout a git branch using fzf"
    git branch | fzf --preview "git log --first-parent --graph --abbrev-commit --decorate {1}" | sed -e 's/^..\(.*\)/\1/' | read branch_name
    if test -n "$branch_name"
        echo "Swith branch to $branch_name"
        git checkout $branch_name
    end
    commandline -f repaint
end
