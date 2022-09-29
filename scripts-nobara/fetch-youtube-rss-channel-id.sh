#!/bin/bash

function fetch_website_content() {
    content=$(curl --fail-early "$*")

    if [ ! "${#content}" ]; then
        echo "Webpage content has not been downloaded. Exiting."
        exit 1
    fi

    echo -e "\nFetched ${#content} characters."
}

function strip_webpage_content_to_metadata_only() {
    printf "Stripping webpage content to approximated metadata subset… "
    local -r position=$(echo "$content" | grep -ob 'channelMetadataRenderer' | cut -d: -f1)
    local -r offset=$(echo "$position - 3200" | bc)
    local -r metadata=${content:$offset}
    echo "position=$position, offset=$offset, characters=${#metadata}"

    printf "Constraining to metadata boundaries… "
    local -r offsetUpper=$(echo "$metadata" | grep -ob '"metadata"' | cut -d: -f1)
    local -r offsetLower=$(echo "$metadata" | grep -ob "requestLanguage" | cut -d: -f1)
    local -r offsetRight=$(echo "$offsetLower - $offsetUpper" | bc)
    local -r metadataContent=${metadata:$offsetUpper:$offsetRight}
    echo "offsets=[$offsetUpper, $offsetLower], characters=${#metadataContent}"

    printf "Cutting to JSON data only… "
    local metadataJson="${metadataContent#*channelMetadataRenderer}"
    metadataJsonOnly="${metadataJson%%trackingParams*}"
    echo "characters=${#metadataJsonOnly}"
}

function print_string_between_words() {
    # print_string_between_words "$str" "fromWord" "toWord"
    local -r str="$1"
    local content1="${str#*$2}"
    local content2="${content1%%$3*}"
    echo "$2$content2"
}

function print_help() {
    echo "SYNOPSIS:"
    echo "  ./fetch-youtube-rss-channel-id [URL | option]"
    echo " "
    echo "URL:"
    echo "URL ought to link to tabPath=videos!"
    echo "  ./fetch-youtube-rss-channel-id https://www.youtube.com/c/SoundOfTheAviators/videos"
    echo "  ./fetch-youtube-rss-channel-id https://www.youtube.com/channel/UCglRFcYdEODvTx55VrlS1qA/videos"
    echo " "
    echo "OPTIONS:"
    echo "  ./fetch-youtube-rss-channel-id --help"
}

function _main_program() {
    if [ "$*" = "--help" ]; then
        print_help
        return 0
    fi

    fetch_website_content "$@"
    strip_webpage_content_to_metadata_only "$@"
    printf '\n'
    print_string_between_words "$metadataJsonOnly" "\"title\"" ","
    print_string_between_words "$metadataJsonOnly" "\"description\"" ",\""
    print_string_between_words "$metadataJsonOnly" "\"rssUrl\"" ",\""
    print_string_between_words "$metadataJsonOnly" "\"keywords\"" ",\""
    print_string_between_words "$metadataJsonOnly" "\"externalId\"" ",\""
    print_string_between_words "$metadataJsonOnly" "\"channelUrl\"" ",\""
    print_string_between_words "$metadataJsonOnly" "\"isFamilySafe\"" ",\""
    print_string_between_words "$metadataJsonOnly" "\"androidDeepLink\"" ",\""
    print_string_between_words "$metadataJsonOnly" "\"androidAppindexingLink\"" ",\""
    print_string_between_words "$metadataJsonOnly" "\"iosAppindexingLink\"" ",\""
    print_string_between_words "$metadataJsonOnly" "\"vanityChannelUrl\"" "}}"
}

_main_program "$@"
