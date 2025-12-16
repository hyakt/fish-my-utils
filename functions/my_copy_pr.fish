function my_copy_pr --description "Copy a pull request to a new base branch"
	set -l base_branch $argv[1]
	set -l pr_number $argv[2]

    gh pr create -w --base $base_branch --body "$(gh pr view $pr_number --json body --jq '.body')" --title "$(gh pr view $pr_number --json title --jq '.title')"
end
