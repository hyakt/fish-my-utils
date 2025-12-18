# Completions for my-copy-pr (Copy a pull request to a new base branch)

# Disable file completion by default
complete -c my-copy-pr -f

# First argument: base branch - suggest local and remote git branches
complete -c my-copy-pr -n "not __fish_seen_argument -n 1" -a "(git branch --all --format='%(refname:short)' 2>/dev/null | sed 's/^origin\///')" -d "Base branch"

# Second argument: PR number - suggest PR numbers from gh pr list
complete -c my-copy-pr -n "__fish_seen_argument -n 1; and not __fish_seen_argument -n 2" -a "(gh pr list --json number,title 2>/dev/null | jq -r '.[] | \"\\(.number)\\t\\(.title)\"')" -d "PR number"
