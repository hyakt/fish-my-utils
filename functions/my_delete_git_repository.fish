function my_delete_git_repository
    echo "Press <tab> to select the repo to be delete"
    ghq list --full-path | fzf --multi | xargs rm -rf
end
