# webtoons-parser

## Description

Bash script to download images from [www.webtoon.com](www.webtoon.com).

I created this script in order to make it convenient to quickly view all the pictures of a certain webtoon, select the necessary ones from them, and create AMVs/edits.

## Requirements

- GIT;
- Bash.

Script was tested in WSL Debian on Windows 10. Should work on MINGW in Windows 10 too, because script uses only `curl`, `sed` and base commands.

## Usage

1. Clone the repository:

    ```bash
    git pull https://github.com/Nikolai2038/webtoons-parser.git
    cd webtoons-parser
    ```

2. Run script:

    ```bash
    ./script.sh <url without episode number> <number of episodes to download>
    ```

    To get `url without episode number` just open any webtoon's episode and copy url from address bar.

    Example ([unOrdinary](https://www.webtoons.com/en/super-hero/unordinary/list?title_no=679) webtoon):

    ```bash
    ./script.sh "https://www.webtoons.com/en/super-hero/unordinary/prologue/viewer?title_no=679&episode_no=" "5"
    ```

    This will download first 5 episodes of unOrdinary webtoon.

    After executing command, script will start to download all images into `./downloads/<title number>/img` directory (this directory will be created automatically). Images will be named `<episode_number>_<image_number>.jpg`.

    Additionaly, script cache all html pages inside `./downloads/<title number>/html` directory to reduce the number of requests for repeated script calls.

    Script also does not download image, if it's filename exists. So if you want to redownload images - just delete them. Same for html files.
