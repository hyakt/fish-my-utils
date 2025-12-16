# ref: https://hiroppy.me/blog/posts/git-worktree-fish

# Helper function to install dependencies based on lock files
function __wt_install_dependencies --description "Auto install dependencies"
    # Check for Rust project first
    if test -f "Cargo.toml"
        echo "📦 Found Cargo.toml, building project..."
        echo "Using package manager: cargo"
        cargo build
        return
    end

    # Check for Deno project
    if test -f "deno.json"; or test -f "deno.jsonc"
        if test -f "deno.lock"
            echo "📦 Found deno.json, installing dependencies..."
            echo "Using package manager: deno"
            deno install
            return
        end
    end

    # Check for Node.js project
    if test -f "package.json"
        echo "📦 Found package.json, installing dependencies..."

        # Detect package manager from lock files
        if test -f "pnpm-lock.yaml"
            echo "Using package manager: pnpm"
            pnpm install
        else if test -f "yarn.lock"
            echo "Using package manager: yarn"
            yarn install
        else if test -f "bun.lockb"
            echo "Using package manager: bun"
            bun install
        else if test -f "package-lock.json"
            echo "Using package manager: npm"
            npm install
        else
            echo "No lock file found, using npm as default"
            npm install
        end
        return
    end
end

function wt --description "Git worktree manager with fzf interface"
    # Parse options for the main command
    argparse -n wt 'z/zed' -- $argv
    or return

    set -l cmd $argv[1]

    if test -z "$cmd"
        # Show worktree list with fzf
        set -l selected (git worktree list | fzf \
            --preview-window="right:60%:wrap" \
            --preview='
                worktree_path=$(echo {} | awk "{print \$1}")
                branch=$(echo {} | sed "s/.*\[//" | sed "s/\]//")

                echo "┌──────────────────────────────────────────────────┐"
                echo "│ 🌳 Branch: $branch"
                echo "└──────────────────────────────────────────────────┘"
                echo ""
                echo "📁 Path: $worktree_path"
                echo ""
                echo "📝 Changed files:"
                echo "───────────────────────────────────────────────────"
                changes=$(git -C "$worktree_path" status --porcelain 2>/dev/null)
                if [ -z "$changes" ]; then
                    echo "  ✨ Working tree clean"
                else
                    echo "$changes" | head -10 | while read line; do
                        file_status=$(echo "$line" | cut -c1-2)
                        file_name=$(echo "$line" | cut -c4-)
                        case "$file_status" in
                            "M "*) echo "  🔧 Modified: $file_name";;
                            "A "*) echo "  ➕ Added: $file_name";;
                            "D "*) echo "  ➖ Deleted: $file_name";;
                            "??"*) echo "  ❓ Untracked: $file_name";;
                            *) echo "  📄 $line";;
                        esac
                    done
                fi
                echo ""
                echo "📜 Recent commits:"
                echo "───────────────────────────────────────────────────"
                git -C "$worktree_path" log --oneline --color=always -10 2>/dev/null | sed "s/^/  /"
            ' \
            --header="🌲 Git Worktree Manager | Press Enter to navigate" \
            --border \
            --height=100% \
            --layout=reverse \
            --prompt="🔍 " | awk '{print $1}'
        )

        if test -n "$selected"
            cd $selected

            # Open in Zed if --zed flag is provided
            if set -q _flag_zed
                echo "Opening in Zed..."
                zed $selected
            end
        end

    else if test "$cmd" = "add"
        # Parse options
        argparse -n wt 'z/zed' -- $argv[2..]
        or return

        set -l branch_name $argv[1]

        if test -z "$branch_name"
            echo "Usage: wt add [-z|--zed] <branch_name>"
            return 1
        end

        # Get git directory
        set -l git_dir (git rev-parse --git-dir 2>/dev/null)
        if test -z "$git_dir"
            echo "Not in a git repository"
            return 1
        end

        # Create tmp_worktrees directory if it doesn't exist
        set -l tmp_worktrees_dir "$git_dir/tmp_worktrees"
        if not test -d "$tmp_worktrees_dir"
            mkdir -p "$tmp_worktrees_dir"
        end

        # Generate directory name with timestamp
        set -l timestamp (date +"%Y%m%d_%H%M%S")
        set -l dir_name "$timestamp"_"$branch_name"
        set -l worktree_path "$tmp_worktrees_dir/$dir_name"

        # Check if branch already exists
        set -l branch_exists (git branch --list "$branch_name")

        # Create worktree (with or without creating new branch)
        if test -n "$branch_exists"
            # Branch exists, create worktree from existing branch
            git worktree add "$worktree_path" "$branch_name"
        else
            # Branch doesn't exist, create new branch and worktree
            git worktree add -b "$branch_name" "$worktree_path"
        end

        if test $status -eq 0
            echo "Created worktree at: $worktree_path"
            echo "Branch: $branch_name"

            # Store project root before changing directory
            set -l project_root (git rev-parse --show-toplevel)

            cd "$worktree_path"

            # Auto install dependencies if package.json exists
            __wt_install_dependencies

            # Execute .wt_hook.fish if it exists in the project root
            if test -f "$project_root/.wt_hook.fish"
                echo "Executing .wt_hook.fish..."
                set -gx WT_WORKTREE_PATH "$worktree_path"
                set -gx WT_BRANCH_NAME "$branch_name"
                set -gx WT_PROJECT_ROOT "$project_root"
                source "$project_root/.wt_hook.fish"
                set -e WT_WORKTREE_PATH
                set -e WT_BRANCH_NAME
                set -e WT_PROJECT_ROOT
            end

            # Open in Zed if --zed flag is provided
            if set -q _flag_zed
                echo "Opening in Zed..."
                zed "$worktree_path"
            end
        end

    else if test "$cmd" = "remove"
        set -l branch_name $argv[2]

        if test -z "$branch_name"
            echo "Usage: wt remove <branch_name>"
            return 1
        end

        # Find worktree path by branch name
        set -l worktree_info (git worktree list | grep "\[$branch_name\]")

        if test -z "$worktree_info"
            echo "No worktree found for branch: $branch_name"
            return 1
        end

        set -l worktree_path (echo $worktree_info | awk '{print $1}')

        # Remove worktree
        git worktree remove --force "$worktree_path"

        if test $status -eq 0
            # Delete branch
            git branch -D "$branch_name"
            echo "Removed worktree and branch: $branch_name"
        end

    else if test "$cmd" = "init"
        # Check if .wt_hook.fish already exists
        if test -f ".wt_hook.fish"
            echo ".wt_hook.fish already exists"
            return 1
        end

        # Create .wt_hook.fish with copy template
        echo "# .wt_hook.fish - Executed after 'wt add' command in worktree directory
# Available variables:
# - \$WT_WORKTREE_PATH: Path to the new worktree (current directory)
# - \$WT_BRANCH_NAME: Name of the branch
# - \$WT_PROJECT_ROOT: Path to the original project root

# Files and directories to copy from project root to worktree directory
# Add or remove file/directory names as needed
set copy_items \".env\" \".claude\"

for item in \$copy_items
    if test -f \"\$WT_PROJECT_ROOT/\$item\"
        # Copy file
        cp \"\$WT_PROJECT_ROOT/\$item\" \"\$item\"
        echo \"Copied file \$item to worktree\"
    else if test -d \"\$WT_PROJECT_ROOT/\$item\"
        # Copy directory recursively
        cp -r \"\$WT_PROJECT_ROOT/\$item\" \"\$item\"
        echo \"Copied directory \$item to worktree\"
    end
end

# Example: Install dependencies
# npm install

# Add your custom initialization commands here
" > .wt_hook.fish

        echo "Created .wt_hook.fish template"

    else
        echo "Unknown command: $cmd"
        echo "Usage:"
        echo "  wt [-z|--zed]              - Show worktree list with fzf"
        echo "  wt add [-z|--zed] <branch> - Create new branch and worktree"
        echo "  wt remove <branch>         - Remove worktree and branch"
        echo "  wt init                    - Create .wt_hook.fish template"
        return 1
    end
end
