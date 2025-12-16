# Completions for wt (Git worktree manager)

# Disable file completion by default
complete -c wt -f

# Subcommands
complete -c wt -n "not __fish_seen_subcommand_from add remove init" -a "add" -d "Create new branch and worktree"
complete -c wt -n "not __fish_seen_subcommand_from add remove init" -a "remove" -d "Remove worktree and branch"
complete -c wt -n "not __fish_seen_subcommand_from add remove init" -a "init" -d "Create .wt_hook.fish template"

# Branch name completion for 'wt add' - suggest all git branches
complete -c wt -n "__fish_seen_subcommand_from add; and not __fish_seen_argument -n 2" -a "(git branch --all --format='%(refname:short)' 2>/dev/null | sed 's/^origin\///' | sort -u)" -d "Branch name"

# Branch name completion for 'wt remove' - suggest only worktree branches
complete -c wt -n "__fish_seen_subcommand_from remove; and not __fish_seen_argument -n 2" -a "(git worktree list 2>/dev/null | sed -n 's/.*\[\(.*\)\].*/\1/p')" -d "Worktree branch"
