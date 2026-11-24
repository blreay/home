#!/bin/bash
#
# mylink2.sh — Upload markdown files to AntCode repo (zhaoyong.zzy/mydocs)
# Modified from mylink.sh: uses GitLab v4 API (curl) instead of scp+ssh.
# Requires ANTCODE_SECRET_TOKEN or ANTCODE_TOKEN environment variable.
#
# Flags:
#   -v   view (preview via local bashttpd)
#   -s   send to AntCode repo
#   -f   force overwrite if file already exists in repo
#   -m   source machine IP (for index entry)
#   -i 1 use md_index1.md instead of md_index.md

typeset view_mode=0
typeset send_mode=0
typeset force_mode=0
typeset src_machine=""
typeset doc_index=0
typeset user=zhaoyong.zzy

# --- AntCode / GitLab API config ---
typeset GITLAB_API="https://code.alipay.com/api/v4"
typeset GITLAB_WEB="https://code.alipay.com"
typeset MY_WEB_SERVER="http://zzy.inc.alipay.net:38080"
typeset REPO_PROJECT="zhaoyong.zzy%2Fmydocs"  # URL-encoded project path
typeset REPO_BRANCH="master"
typeset REPO_DIR="md"
typeset TOKEN="${ANTCODE_SECRET_TOKEN:-${ANTCODE_TOKEN:-}}"

while getopts vdsfm:i: ch; do
  case $ch in
    v) view_mode=1;;
    s) send_mode=1;;
    f) force_mode=1;;
    d) set -vx;;
    i) doc_index=$OPTARG;;
    m) src_machine=$OPTARG;;
  esac
done
shift $((OPTIND-1))
typeset file=$1

# --- helpers ---
# URL-encode a path component for the GitLab API
function url_encode() {
    python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}

# Call the API and check for errors
function api_call() {
    typeset method="$1" url="$2" data="$3"
    typeset resp
    resp=$(printf '%s' "$data" | curl -s --request "${method}" \
      --header "PRIVATE-TOKEN: ${TOKEN}" \
      --header "Content-Type: application/json" \
      --data-binary @- \
      "${url}")

    typeset err
    err=$(echo "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','') or d.get('error',''))" 2>/dev/null)
    if [[ -n "$err" ]]; then
        echo "API error: ${err}" >&2
        echo "Response: ${resp}" >&2
        return 1
    fi
    echo "$resp"
    return 0
}

# --- file existence check ---
function repo_file_exists() {
    typeset api_path="$1"
    typeset code
    code=$(curl -s -o /dev/null -w "%{http_code}" \
      --header "PRIVATE-TOKEN: ${TOKEN}" \
      "${GITLAB_API}/projects/${REPO_PROJECT}/repository/files/${api_path}?ref=${REPO_BRANCH}")
    [[ "$code" == "200" ]] && return 0 || return 1
}

function set_proxy () {
    [[ "no" == "$1" ]] && unset http_proxy HTTP_PROXY https_proxy ftp_proxy no_proxy NO_PROXY AGENT_BROWSER_PROXY AGENT_BROWSER_PROXY_BYPASS && echo -e "proxy has been disabled\n$(env | grep -i 'proxy.*=')" && return;
    export HTTP_PROXY=XXXXXXXX
    [[ $(uname) =~ CYGWIN || $(uname -r) =~ WSL ]] && export HTTP_PROXY=127.0.0.1:13659;
    export no_proxy='127.0.0.1,localhost*,dl.google.com,*.alicdn.*,*alipay*,.alicdn.com,.aliyun-inc.com,.alipay.net,.aliyuncs.com,.antfin-inc.com,antfin-inc.com,*.antfin*';
    export http_proxy=$HTTP_PROXY;
    export https_proxy=$HTTP_PROXY;
    export ftp_proxy=$HTTP_PROXY;
    export NO_PROXY=${no_proxy};
    export GOPROXY=https://goproxy.cn,direct;
    export AGENT_BROWSER_PROXY=$HTTP_PROXY;
    export AGENT_BROWSER_PROXY_BYPASS=$no_proxy;
    env | grep -i "proxy.*="
}


# --- main ---
[[ ! -f "$file" ]] && echo "Error: file not found: $file" && exit 1
set_proxy no

typeset filename="${file##*/}"

if [[ $send_mode -eq 0 ]]; then
    # --- local preview mode (unchanged from mylink.sh) ---
    typeset ip=$(ip route get 1.1.1.1 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
    typeset prefix="http://${ip}:38080/os_root"
    typeset prefix_view="http://${ip}:38080/myhome/git/bashttpd/md_viewer.html?file="

    [[ ${file} =~ ^/ ]] && fullpath=$file || fullpath="$(pwd)/${file}"
    typeset url="${prefix}/${fullpath}"
    [[ ${view_mode} -eq 1 ]] && url="${prefix_view}/os_root/${fullpath}"
else
    # --- send mode: upload to AntCode via GitLab API ---
    [[ -z "$TOKEN" ]] && echo "Error: ANTCODE_SECRET_TOKEN or ANTCODE_TOKEN not set" >&2 && exit 1

    typeset api_file_path="${REPO_DIR}/${filename}"
    typeset encoded_file_path=$(url_encode "${api_file_path}")

    # AntCode blob URL for the uploaded file
    typeset blob_url="${GITLAB_WEB}/zhaoyong.zzy/mydocs/blob/${REPO_BRANCH}/${api_file_path}"
    # Raw URL (plain text, for link in index)
    #typeset plain_url="${GITLAB_WEB}/zhaoyong.zzy/mydocs/blob/${REPO_BRANCH}/${api_file_path}?plain=1"
    typeset plain_url="${GITLAB_WEB}/zhaoyong.zzy/mydocs/raw/${REPO_BRANCH}/${api_file_path}"
    typeset my_web_url="${MY_WEB_SERVER}/mydocs/${api_file_path}"

    # Check if file already exists
    if repo_file_exists "${encoded_file_path}"; then
        if [[ ${force_mode} -eq 1 ]]; then
            echo "Warning: ${filename} already exists, overwriting (forced by -f)"
        else
            echo "Error: ${filename} already exists in repo"
            echo "  ${blob_url}"
            echo "Please rename your file or use -f to force overwrite."
            exit 1
        fi
    fi

    # Base64-encode and upload
    typeset b64_content=$(base64 -w0 "$file")
    typeset commit_msg="docs: add ${filename} via mylink2"

    typeset api_method="POST"
    repo_file_exists "${encoded_file_path}" && api_method="PUT"

    api_call "${api_method}" \
      "${GITLAB_API}/projects/${REPO_PROJECT}/repository/files/${encoded_file_path}" \
      "{\"branch\":\"${REPO_BRANCH}\",\"content\":\"${b64_content}\",\"commit_message\":\"${commit_msg}\",\"encoding\":\"base64\"}" \
      || exit 1

    echo "Uploaded: ${blob_url}"

    # --- update md_index.md ---
    typeset md_title=$(grep -m1 '^# ' "$file" | sed 's/^# //')
    [[ -z "$md_title" ]] && md_title="${filename}"

    typeset index_file="md/md_index.md"
    [[ $doc_index -eq 1 ]] && index_file="md/md_index1.md"
    typeset encoded_index_path=$(url_encode "${index_file}")

    typeset ts=$(date '+%Y%m%d_%H%M%S')
    typeset src_ip=${src_machine:-$(ip route get 1.1.1.1 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')}
    typeset src_dir=$(pwd)
    typeset git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "N/A")
    typeset new_row="| [${md_title}](${blob_url}) | [md]($plain_url) | ${ts} | ${src_ip} | ${src_dir} | ${git_branch} |"

    typeset header='| 标题 | 原始文件 | 创建时间 | 来源机器 | 来源目录 | Git分支 |'
    typeset separator='|------|----------|----------|----------|----------|---------|'

    typeset index_content
    if repo_file_exists "${encoded_index_path}"; then
        # FETCH existing index
        typeset index_resp
        index_resp=$(curl -s --header "PRIVATE-TOKEN: ${TOKEN}" \
          "${GITLAB_API}/projects/${REPO_PROJECT}/repository/files/${encoded_index_path}?ref=${REPO_BRANCH}")
        index_content=$(echo "$index_resp" | python3 -c "import sys,json,base64; d=json.load(sys.stdin); print(base64.b64decode(d['content']).decode('utf-8'))" 2>/dev/null)
        if [[ -z "$index_content" ]]; then
            echo "Warning: could not decode existing index, creating new" >&2
            index_content="${header}"$'\n'"${separator}"$'\n'"${new_row}"$'\n'
        else
            # Insert new row after the separator (line 2)
            index_content=$(echo "$index_content" | sed "2a\\${new_row}")
        fi
    else
        # CREATE new index
        index_content="${header}"$'\n'"${separator}"$'\n'"${new_row}"$'\n'
    fi

    typeset index_b64=$(echo -n "$index_content" | base64 -w0)
    typeset index_method="PUT"
    repo_file_exists "${encoded_index_path}" || index_method="POST"

    api_call "${index_method}" \
      "${GITLAB_API}/projects/${REPO_PROJECT}/repository/files/${encoded_index_path}" \
      "{\"branch\":\"${REPO_BRANCH}\",\"content\":\"${index_b64}\",\"commit_message\":\"docs: update index with ${filename}\",\"encoding\":\"base64\"}" \
      >/dev/null || echo "Warning: failed to update index" >&2

    echo "Index: ${GITLAB_WEB}/zhaoyong.zzy/mydocs/blob/${REPO_BRANCH}/${index_file}"

    #typeset url="${blob_url}"
    typeset url="${plain_url}"
    fullpath="${blob_url}"
fi

echo "${url}" | myyank.sh 2>/dev/null || true
echo "${url}"

[[ ${view_mode} -eq 1 ]] && url="${prefix}${fullpath}" && echo "${url}"
