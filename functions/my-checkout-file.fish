function my-checkout-file --description "Select and checkout modified files using fzf"
    echo "Press <tab> to select the file to be checkouted"
    git diff --name-status | fzf --multi | cut -f2 | xargs git checkout
end
