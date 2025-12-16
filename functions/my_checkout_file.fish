function my_checkout_file
    echo "Press <tab> to select the file to be checkouted"
    git diff --name-status | fzf --multi | cut -f2 | xargs git checkout
end
