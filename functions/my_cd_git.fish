function my_cd_git
    set base_git_dir (git rev-parse --show-superproject-working-tree --show-toplevel)
    fd --type d --base-directory $base_git_dir | fzf --preview "ls -l (git rev-parse --show-superproject-working-tree --show-toplevel)/{}" | read directory
    if [ $directory ]
        cd $base_git_dir/$directory;
    end
    commandline -f repaint
end
