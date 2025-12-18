function my-hide-git-time --description "Hide git commit timestamps by setting them to midnight"
    set -l first_commit (git rev-list HEAD | tail -n 1)"~"
    set -l last_commit "HEAD"
    git filter-branch --env-filter '
        d="$(echo "$GIT_COMMITTER_DATE" | sed "s/T.*//")T00:00:00+00:00)"
        export GIT_COMMITTER_DATE="$d"
        export GIT_AUTHOR_DATE="$d"
    ' -f -- --all
end
