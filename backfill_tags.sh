#!/bin/bash

# Script to backfill tags from referenced commits in source repository
# Reads commit messages, extracts Original-Commit references, and applies
# tags from the source repository to corresponding commits in this repository

set -e

SOURCE_REPO="/home/daroczig/projects/sc-data"
TARGET_REPO="$(pwd)"

# Validate source repo
if [ ! -d "$SOURCE_REPO/.git" ]; then
    echo "Error: Source repository '$SOURCE_REPO' is not a valid git repository"
    exit 1
fi

# Validate we're in a git repo
if [ ! -d "$TARGET_REPO/.git" ]; then
    echo "Error: Current directory is not a valid git repository"
    exit 1
fi

echo "Source repository: $SOURCE_REPO"
echo "Target repository: $TARGET_REPO"
echo "========================================"
echo ""

# Get all commits from oldest to newest
COMMITS=$(git rev-list --reverse --all)

# Check if we have any commits
if [ -z "$COMMITS" ]; then
    echo "Error: No commits found"
    exit 1
fi

# Counter for commits
COMMIT_COUNT=0
TOTAL_COMMITS=$(echo "$COMMITS" | wc -l)
TAGS_APPLIED=0

echo "Total commits to process: $TOTAL_COMMITS"
echo ""

# Iterate through each commit
for COMMIT_SHA in $COMMITS; do
    COMMIT_COUNT=$((COMMIT_COUNT + 1))

    # Get commit message
    COMMIT_MESSAGE=$(git log -1 --format='%B' "$COMMIT_SHA")
    
    # Extract Original-Commit from the last few lines
    # Look for "Original-Commit: <SHA>" pattern
    ORIGINAL_COMMIT=$(echo "$COMMIT_MESSAGE" | grep -E '^Original-Commit: [0-9a-f]{40}$' | sed 's/Original-Commit: //' || true)
    
    if [ -z "$ORIGINAL_COMMIT" ]; then
        echo "  No Original-Commit found in commit message - skipping"
        echo ""
        continue
    fi
    
    echo "[$COMMIT_COUNT/$TOTAL_COMMITS] Processing commit $COMMIT_SHA"
    echo "  Referenced commit: $ORIGINAL_COMMIT"
    
    # Check if the original commit exists in source repo
    if ! git -C "$SOURCE_REPO" rev-parse --verify "$ORIGINAL_COMMIT" >/dev/null 2>&1; then
        echo "  ⚠ Original commit not found in source repository - skipping"
        echo ""
        continue
    fi
    
    # Get tags from the original commit in source repo
    ORIGINAL_TAGS=$(git -C "$SOURCE_REPO" tag --points-at "$ORIGINAL_COMMIT" 2>/dev/null || true)
    
    if [ -z "$ORIGINAL_TAGS" ]; then
        echo "  No tags found on original commit"
        echo ""
        continue
    fi
    
    echo "  Tags found on original commit:"
    for TAG in $ORIGINAL_TAGS; do
        echo "    - $TAG"
        
        # Check if tag already exists in target repo
        if git rev-parse "$TAG" >/dev/null 2>&1; then
            EXISTING_COMMIT=$(git rev-parse "$TAG")
            if [ "$EXISTING_COMMIT" = "$COMMIT_SHA" ]; then
                echo "      ✓ Tag '$TAG' already points to this commit"
                continue
            else
                echo "      Tag '$TAG' already exists (pointing to $EXISTING_COMMIT), deleting it first..."
                git tag -d "$TAG" 2>&1 || echo "      ⚠ Failed to delete existing tag"
            fi
        fi
        
        # Create the tag (lightweight, no GPG signing)
        if git tag --no-sign "$TAG" "$COMMIT_SHA" 2>&1; then
            echo "      ✓ Tag '$TAG' applied to commit $COMMIT_SHA"
            TAGS_APPLIED=$((TAGS_APPLIED + 1))
        else
            echo "      ⚠ Failed to apply tag '$TAG'"
        fi
    done
    
    echo ""
done

echo "========================================"
echo "Completed processing $COMMIT_COUNT of $TOTAL_COMMITS commits"
echo "Total tags applied: $TAGS_APPLIED"
echo "========================================"
