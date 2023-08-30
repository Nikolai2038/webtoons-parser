#!/usr/bin/env bash

# Полный путь к папке с текущим скриптом
DIRECTORY_WITH_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit "$?"

function main() {
    local url_without_episode_number="${1}" && shift
    if [[ -z "${url_without_episode_number}" ]]; then
        echo "Enter URL without episode number!" >&2
        return 1
    fi

    local title_number
    title_number="$(echo "${url_without_episode_number}" | sed -E 's/.*title_no=([0-9]+).*/\1/')" || return "$?"
    if [[ -z "${title_number}" ]]; then
        echo "Can't get title_no from provided URL!" >&2
        return 1
    fi

    local is_tidy_installed
    which "tidy" &> /dev/null && is_tidy_installed="1" || is_tidy_installed="0"
    if ((!is_tidy_installed)); then
        echo "You need to install tidy package!" >&2
        return 1
    fi

    local temp_dir="${DIRECTORY_WITH_SCRIPT}/downloads"
    if [[ ! -d "${temp_dir}" ]]; then
        mkdir "${temp_dir}" || return "$?"
    fi

    local webtoon_dir="${temp_dir}/${title_number}"
    if [[ ! -d "${webtoon_dir}" ]]; then
        mkdir "${webtoon_dir}" || return "$?"
    fi

    local htmls_dir="${webtoon_dir}/html"
    if [[ ! -d "${htmls_dir}" ]]; then
        mkdir "${htmls_dir}" || return "$?"
    fi

    local imgs_dir="${webtoon_dir}/img"
    if [[ ! -d "${imgs_dir}" ]]; then
        mkdir "${imgs_dir}" || return "$?"
    fi

    local episodes_count="${1:-1}" && shift

    local episode_number
    for ((episode_number = 1; episode_number <= episodes_count; episode_number++)); do
        local url="${url_without_episode_number}${episode_number}"

        echo -n "Episode ${episode_number}: ${url}:" >&2

        local episode_file_path="${htmls_dir}/${episode_number}"

        # ========================================
        # Get HTML
        # ========================================
        local html
        if [[ ! -f "${episode_file_path}" ]]; then
            echo " will be downloaded!" >&2
            html="$(curl --silent -L "${url}")" || return "$?"
            # shellcheck disable=SC2320
            echo "${html}" | tidy -quiet --show-body-only yes -raw -wrap 0 -ashtml --drop-empty-elements no &> "${episode_file_path}"
        else
            echo " already downloaded!" >&2
            html="$(cat "${episode_file_path}")" || return "$?"
        fi
        # ========================================

        # ========================================
        # Get images links from HTML
        # ========================================
        local line_with_img_tags
        local image_list_tag_id="_imageList"
        line_with_img_tags="$(echo "${html}" | sed -En "/${image_list_tag_id}/p")" || return "$?"

        local image_links
        image_links="$(echo "${line_with_img_tags}" | sed -E 's/>\s*<img /\n/g' | sed -En 's/^.*data-url="([^"]+)".*/\1/p' | uniq)" || return "$?"

        if [[ -z "${image_links}" ]]; then
            echo "- Image list for episode ${episode_number} is empty!" >&2
            return 1
        fi

        declare -a image_links_array=()
        # Преобразование текста из строк в массив
        mapfile -t image_links_array <<< "${image_links}"
        # ========================================

        if [[ "${#image_links_array[@]}" -eq 0 ]]; then
            echo "- Images for episode ${episode_number} were not found!" >&2
            return 1
        fi

        # ========================================
        # Download all images
        # ========================================
        local image_link
        local link_number=1
        for image_link in "${image_links_array[@]}"; do
            echo -n "- Image ${link_number}: ${image_link}:" >&2

            local img_file_name="${imgs_dir}/${episode_number}_${link_number}.jpg"

            if [[ ! -f "${img_file_name}" ]]; then
                echo " will be downloaded!" >&2
                curl "${image_link}" \
                    -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:116.0) Gecko/20100101 Firefox/116.0' \
                    -H 'Accept: image/avif,image/webp,*/*' \
                    -H 'Accept-Language: en-US,en;q=0.5' \
                    -H 'Accept-Encoding: gzip, deflate, br' \
                    -H 'DNT: 1' \
                    -H 'Connection: keep-alive' \
                    -H 'Sec-Fetch-Dest: image' \
                    -H 'Sec-Fetch-Mode: no-cors' \
                    -H 'Sec-Fetch-Site: cross-site' \
                    -H 'Sec-GPC: 1' \
                    -H 'Pragma: no-cache' \
                    -H 'Cache-Control: no-cache' \
                    -H 'TE: trailers' \
                    -H 'Referer: https://www.webtoons.com/' \
                    --output "${img_file_name}" || return "$?"
            else
                echo " already downloaded!" >&2
            fi

            ((link_number++))
        done
        # ========================================
    done

    return 0
}

# DEBUG: Unordinary
main "https://www.webtoons.com/en/super-hero/unordinary/prologue/viewer?title_no=679&episode_no=" "10" || exit "$?"

# NO DEBUG:
# main "$@" || exit "$?"
