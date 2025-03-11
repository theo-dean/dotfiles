# Script to automatically mark notifications for merged PRs as read
# Requires GitHub CLI (gh) to be installed and authenticated

gh_notifications_cleanup() {
    notifications_response=$(gh api notifications --paginate --slurp)
    notifications=$(echo "$notifications_response" | jq 'flatten | .[] | {id: .id, repository: .repository.full_name, url: .subject.url, title: .subject.title}')

    if [[ -z "$notifications" ]]; then
        log "No pull request notifications found."
        exit 0
    fi

    echo "$notifications" | jq -c '.' | while read -r notification; do
        pr_url=$(echo "$notification" | jq -r '.url')
        pr_state=$(gh api "$pr_url" --jq '.state')
        pr_title=$(echo "$notification" | jq -r '.title')
        notification_id=$(echo "$notification" | jq -r '.id')
        repo=$(echo "$notification" | jq -r '.repository')
        
        if [[ "$pr_state" == "closed" ]]; then
            gh api "notifications/threads/$notification_id" -X DELETE --silent
            echo "✓ Deleted notification for: PR #$pr_title in $repo"
        else
            echo "- Keeping notification for: PR #$pr_title in $repo"
        fi
    done
}