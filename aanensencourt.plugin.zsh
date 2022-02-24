#!/usr/bin/env zsh

export SONAR_TOKEN
export SONAR_API_ENDPOINT

function sonar () {
  [[ $# -gt 0 ]] || {
    _sonar::help
    return 1
  }

  local command="$1"
  shift

  (( $+functions[_sonar::$command] )) || {
    _sonar::help
    return 1
  }

  _sonar::$command "$@"
}

function _sonar {
  local -a cmds subcmds
  cmds=(
    'help:Usage information'
    'init:Initialisation information'
  )

  if (( CURRENT == 2 )); then
    _describe 'command' cmds
  elif (( CURRENT == 3 )); then
    case "$words[2]" in
      teams) subcmds=(
        'list:List all the teams'
        )
    esac
  fi

  return 0
}

compdef _sonar sonar    

function _sonar::help {
    cat <<EOF
Usage: sonar <command> [options]

Available commands:

  complexity
  bug

EOF
}

function _sonar::init {
  if [ -n "${SONAR_API_ENDPOINT}" ] && [ -n "${SONAR_TOKEN}" ]; then
    echo "============================================="
    echo "Current Configuration"
    echo "SONAR_API_ENDPOINT  ...... ${SONAR_API_ENDPOINT}"
    echo "SONAR_TOKEN .............. ${SONAR_TOKEN}"
    echo "============================================="
  else
    echo "============================================="
    echo "Create Configuration"
    echo "SONAR_API_ENDPOINT=<http://...>"
    echo "SONAR_TOKEN=<token>"
    echo "============================================="
  fi
}

function _sonar::complexity () {
  seq 1 1 14 | \
    xargs -I {} -n1 -P1 \
      curl --silent --location --user ${SONAR_TOKEN}: \
           --request GET "${SONAR_API_ENDPOINT}/api/issues/search?p={}&ps=100&resolved=false&rules=java%3AS3776&severities=CRITICAL&additionalFields=_all" | \
    jq -r .issues | \
    jq -cn --stream 'fromstream(1|truncate_stream(inputs))' | \
    jq -r "{ component : .component, message : .message }" | \
    jq -r '{ component : .component | gsub(".*/"; ""), complexity : .message | gsub("15";"") | gsub(".*from "; "") | gsub("[^0-9]"; "") | tonumber}' | \
    jq --slurp | jq 'group_by(.component)|.[] | reduce .[] as $item ({}; .component = $item.component | .complexity |= . + $item.complexity)' | \
    jq --slurp | jq -r 'sort_by(.complexity)|reverse' | \
    jq -r '(["Component", "Complexity"] | (., map(length*"-"))), (.[] | [.component, .complexity]) | @tsv' | \
    column -t
}

function _sonar::bug () {
  local CODE=${1:-""}

  if [[ -z "${CODE}" ]]; then
    local BUGS=("servlet" "equals" "optional")
    PS3='Select an bug type and press enter: '
    select BUG in "${BUGS[@]}"; do
      case "$BUG,$REPLY" in
        servlets,*|*,servlets) CODE=2226; break ;;
        equals,*|*,equals)     CODE=1206; break ;;
        optional,*|*,optional) CODE=3655; break ;;
      esac
    done
  fi

  seq 1 1 14 | \
    xargs -I {} -n1 -P1 \
      curl --silent \
           --location --user ${SONAR_TOKEN}: \
           --request GET "${SONAR_API_ENDPOINT}/api/issues/search?p={}&ps=100&resolved=false&rules=java%3AS${CODE}&types=BUG&additionalFields=_all" | \
    jq -r .issues | \
    jq -cn --stream 'fromstream(1|truncate_stream(inputs))' | \
    jq -r "{ component : .component, message : .message }" | \
    jq -r '{ component : .component | gsub(".*/"; ""), message : .message }' | \
    jq --slurp | \
    jq -r '(["Component", "Message"] | (., map(length*"-"))), (.[] | [.component, .message]) | @csv' | \
    column -t -s ,
}
