function my_delete_local_branch --description "Select and delete local git branches using fzf"
    echo "Press <tab> to select the branch to be delete"
    git branch --format="%(refname:short)" | fzf --multi | xargs git branch -D
end
