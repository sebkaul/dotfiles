#!/usr/bin/env bash
# Only run selector if not already inside tmux
if [ -z "$TMUX" ]; then
    # Define sessions to ensure they exist
    sessions=(home devops school)
    
    # Create sessions if they don't exist
    for s in "${sessions[@]}"; do
        tmux has-session -t "$s" 2>/dev/null || tmux new-session -d -s "$s"
    done
    
    # Pre-fetch session info
    home_attached=$(tmux list-sessions 2>/dev/null | grep "^home:" | grep -q "(attached)" && echo " (attached)" || echo "")
    devops_attached=$(tmux list-sessions 2>/dev/null | grep "^devops:" | grep -q "(attached)" && echo " (attached)" || echo "")
    school_attached=$(tmux list-sessions 2>/dev/null | grep "^school:" | grep -q "(attached)" && echo " (attached)" || echo "")
    
    home_info="home: $(tmux list-windows -t home 2>/dev/null | wc -l) windows$home_attached"
    devops_info="devops: $(tmux list-windows -t devops 2>/dev/null | wc -l) windows$devops_attached"
    school_info="school: $(tmux list-windows -t school 2>/dev/null | wc -l) windows$school_attached"
    
    # Build fzf menu with pre-fetched info
    choice=$(
        printf "%s\n%s\n%s\n%s\nnotmux: shell without tmux\n" \
            "$home_info" \
            "$devops_info" \
            "$school_info" \
        | fzf \
            --height=80% \
            --layout=reverse \
            --border=rounded \
            --margin=20%,30% \
            --prompt="Select session > " \
            --pointer="▶" \
            --color="border:#5f5f5f,header:#8be9fd,pointer:#c94f4e,prompt:#a6e3a1" \
        | awk -F: '{print $1}' | xargs
    )
    
    # If nothing selected, default to home session
    [ -z "$choice" ] && exec zsh
    
    # Skip tmux if "notmux" chosen
    if [ "$choice" = "notmux" ]; then
        exec zsh
    fi
    
    # Attach to selected session
    exec tmux attach-session -t "$choice"
fi

# Fallback if already in tmux
exec zsh
