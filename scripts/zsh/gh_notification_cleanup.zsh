# Script to automatically mark notifications for merged PRs as read
# Requires GitHub CLI (gh) to be installed and authenticated

gh_notifications_cleanup() {
    notifications=$(gh api notifications --jq '.[] | select(.reason == "review_requested") | {id: .id, repository: .repository.full_name, url: .subject.url, title: .subject.title}')
    if [[ -z "$notifications" ]]; then
        log "No pull request notifications found."
        exit 0
    fi
    echo "$notifications" | jq -c '.' | while read -r notification; do
        pr_url=$(echo "$notification" | jq -r '.url')
        pr_merged=$(gh api "$pr_url" --jq '.merged')
        pr_title=$(echo "$notification" | jq -r '.title')
        notification_id=$(echo "$notification" | jq -r '.id')
        repo=$(echo "$notification" | jq -r '.repository')
        
        if [[ "$pr_merged" == "true" ]]; then
            gh api "notifications/threads/$notification_id" -X PATCH --silent
            echo "✓ Marked notification as read: PR #$pr_title in $repo (merged)"
        else
            echo "- Keeping notification: PR #$pr_title in $repo (not merged)"
        fi
    done
}

