#!/bin/bash

CONTAINERS_TO_KEEP=(
    "minikube"
)

IMAGES_TO_KEEP=(
    "gcr.io/k8s-minikube/kicbase"
)

# Ensure the script is run with sudo privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo privileges. Exiting."
   exit 1
fi

echo "Select cleanup mode:"
echo "1) Containers only"
echo "2) Images only"
echo "3) Containers and images"
echo "4) Keyword-based deletion (interactive)"
read -r -p "Mode selection (1/2/3, default 3): " mode_selection

KEYWORD_MODE=0

echo " ACTION REQUIRED: Confirm Cleanup"

echo "Containers to KEEP: ${CONTAINERS_TO_KEEP[*]}"
echo "Images to KEEP: ${IMAGES_TO_KEEP[*]}"
echo ""
read -r -p "Do you want to proceed with the cleanup? (Y/N): " confirm_delete

if [[ "$confirm_delete" != "Y" && "$confirm_delete" != "y" ]]; then
    echo "Cleanup aborted by user."
    exit 0
fi

REMOVE_CONTAINERS=0
REMOVE_IMAGES=0

case "$mode_selection" in
    1|c|C)
        REMOVE_CONTAINERS=1
        ;;
    2|i|I)
        REMOVE_IMAGES=1
        ;;
    3|b|B|"" )
        REMOVE_CONTAINERS=1
        REMOVE_IMAGES=1
        ;;
    4)
        # Keyword-based interactive mode
        KEYWORD_MODE=1
        read -r -p "Target (containers/images/both) [containers]: " keyword_target
        keyword_target=${keyword_target:-containers}
        read -r -p "Enter keyword to match (partial match): " MATCH_KEYWORD
        if [ -z "$MATCH_KEYWORD" ]; then
            echo "No keyword entered. Aborting keyword mode."
            exit 0
        fi
        ;;
    *)
        echo "Invalid selection. Defaulting to containers and images."
        REMOVE_CONTAINERS=1
        REMOVE_IMAGES=1
        ;;
esac

containers_removed=0
images_removed=0


if [ "$REMOVE_CONTAINERS" -eq 1 ]; then
    echo "Stopping and removing containers NOT in the exclusion list..."
    ALL_CONTAINERS=$(docker ps -aq)
    if [ -z "$ALL_CONTAINERS" ]; then
        echo "No containers found (running or stopped). Skipping removal."
    else
        for container_id in $ALL_CONTAINERS; do
            KEEP=0
            for keep_id in "${CONTAINERS_TO_KEEP[@]}"; do
                if docker inspect --format '{{.Name}} {{.ID}}' "$container_id" 2>/dev/null | grep -q "$keep_id"; then
                    KEEP=1
                    break
                fi
            done
            if [ "$KEEP" -eq 1 ]; then
                echo "-> KEEPING container: $container_id"
            else
                STATUS=$(docker inspect --format '{{.State.Status}}' "$container_id")
                ACTION="REMOVING container"
                if [ "$STATUS" == "running" ]; then
                    echo "-> STOPPING container: $container_id"
                    docker stop "$container_id" > /dev/null
                    ACTION="STOPPED and REMOVED container"
                fi
                echo "-> $ACTION: $container_id"
                if docker rm "$container_id" > /dev/null; then
                    containers_removed=$((containers_removed + 1))
                fi
            fi
        done
    fi
else
    echo "Container cleanup skipped."
fi

    if [ "$KEYWORD_MODE" -eq 1 ]; then
        # Normalize the keyword target
        keyword_target=$(echo "$keyword_target" | tr '[:upper:]' '[:lower:]')

        # Helper: check exclusion list for a container name or id
        is_container_excluded() {
            local cid="$1"
            for keep in "${CONTAINERS_TO_KEEP[@]}"; do
                if docker inspect --format '{{.Name}} {{.ID}}' "$cid" 2>/dev/null | grep -qi "$keep"; then
                    return 0
                fi
            done
            return 1
        }

        # Helper: confirm and delete containers by keyword
        if [[ "$keyword_target" == "containers" || "$keyword_target" == "both" ]]; then
            echo "Searching for containers matching keyword: '$MATCH_KEYWORD'"
            mapfile -t matched_containers < <(docker ps -a --format "{{.ID}} {{.Names}} {{.Image}}" | grep -i "$MATCH_KEYWORD" || true)
            if [ ${#matched_containers[@]} -eq 0 ]; then
                echo "No containers match keyword '$MATCH_KEYWORD'."
            else
                echo "Matched containers:"
                for line in "${matched_containers[@]}"; do
                    echo "  $line"
                done
                read -r -p "Proceed to stop & remove these containers? (Y/N): " ydelc
                if [[ "$ydelc" == "Y" || "$ydelc" == "y" ]]; then
                    for line in "${matched_containers[@]}"; do
                        cid=$(echo "$line" | awk '{print $1}')
                        if is_container_excluded "$cid"; then
                            echo "-> SKIPPING excluded container: $cid"
                            continue
                        fi
                        status=$(docker inspect --format '{{.State.Status}}' "$cid")
                        if [ "$status" == "running" ]; then
                            echo "-> STOPPING container $cid"
                            docker stop "$cid"
                        fi
                        echo "-> REMOVING container $cid"
                        if docker rm "$cid" >/dev/null 2>&1; then
                            containers_removed=$((containers_removed + 1))
                        fi
                    done
                else
                    echo "Container keyword deletion aborted by user."
                fi
            fi
        fi

        # Helper: check exclusion list for images
        is_image_excluded() {
            local imgid="$1"
            for keep in "${IMAGES_TO_KEEP[@]}"; do
                # compare repository:tag and id
                if docker images --no-trunc --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep -i "$imgid" | grep -qi "$keep"; then
                    return 0
                fi
                if [[ "$imgid" == *"$keep"* ]]; then
                    return 0
                fi
            done
            return 1
        }

        if [[ "$keyword_target" == "images" || "$keyword_target" == "both" ]]; then
            echo "Searching for images matching keyword: '$MATCH_KEYWORD'"
            mapfile -t matched_images < <(docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep -i "$MATCH_KEYWORD" || true)
            if [ ${#matched_images[@]} -eq 0 ]; then
                echo "No images match keyword '$MATCH_KEYWORD'."
            else
                echo "Matched images:"
                for line in "${matched_images[@]}"; do
                    echo "  $line"
                done
                read -r -p "Proceed to remove these images? (Y/N): " ydelim
                if [[ "$ydelim" == "Y" || "$ydelim" == "y" ]]; then
                    for line in "${matched_images[@]}"; do
                        imgid=$(echo "$line" | awk '{print $2}')
                        # If any containers use this image, stop & remove them first
                        containers_using=($(docker ps -a --filter "ancestor=$imgid" --format "{{.ID}}"))
                        for cid in "${containers_using[@]}"; do
                            if is_container_excluded "$cid"; then
                                echo "-> SKIPPING container $cid using image $imgid because it's excluded"
                                continue
                            fi
                            echo "-> STOPPING container $cid using image $imgid"
                            docker stop "$cid" >/dev/null 2>&1 || true
                            echo "-> REMOVING container $cid"
                            docker rm "$cid" >/dev/null 2>&1 || true
                            containers_removed=$((containers_removed + 1))
                        done
                        if is_image_excluded "$imgid"; then
                            echo "-> SKIPPING excluded image: $imgid"
                            continue
                        fi
                        echo "-> REMOVING image $imgid"
                        if docker rmi -f "$imgid" >/dev/null 2>&1; then
                            images_removed=$((images_removed + 1))
                        fi
                    done
                else
                    echo "Image keyword deletion aborted by user."
                fi
            fi
        fi

    fi

if [ "$REMOVE_IMAGES" -eq 1 ]; then
    echo "Deleting images NOT in the exclusion list..."
    ALL_IMAGE_IDS=$(docker images -q)
    if [ -z "$ALL_IMAGE_IDS" ]; then
        echo "No images found. Skipping removal."
    else
        for image_id in $ALL_IMAGE_IDS; do
            KEEP=0
            for keep_image in "${IMAGES_TO_KEEP[@]}"; do
                IMAGE_FULL_NAME=$(docker images --no-trunc --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep "$image_id" | awk '{print $1}')
                if [[ "$IMAGE_FULL_NAME" == *"$keep_image"* ]] || [[ "$image_id" == *"$keep_image"* ]]; then
                    KEEP=1
                    break
                fi
            done
            if [ "$KEEP" -eq 1 ]; then
                echo "-> KEEPING image: $image_id"
            else
                IMAGE_NAME=$(docker images --no-trunc --format "{{.Repository}}:{{.Tag}}" | grep "$image_id" | awk '{print $1}')
                echo "-> DELETING image: $IMAGE_NAME ($image_id)"
                if docker rmi -f "$image_id" > /dev/null 2>&1; then
                    images_removed=$((images_removed + 1))
                fi
            fi
        done
    fi
else
    echo "Image cleanup skipped."
fi

echo "Cleanup complete"

echo "Current Docker state:"

remaining_containers=$(docker ps -aq | wc -l | xargs)
remaining_images=$(docker images -q | wc -l | xargs)

echo "Summary:"
echo "Containers removed: $containers_removed"
echo "Images removed: $images_removed"
echo "Containers remaining: $remaining_containers"
echo "Images remaining: $remaining_images"

docker ps -a
docker images
