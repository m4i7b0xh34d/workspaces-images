#!/usr/bin/env bash
set -ex
START_COMMAND="remmina"
PGREP="remmina"
DEFAULT_ARGS=""
MAXIMUS="false"
ARGS=${APP_ARGS:-$DEFAULT_ARGS}

update_profile() {
  if [ -n "$REMMINA_OPTIONS" ] && [ -n "$REMMINA_PROFILE" ] ; then
        R_OPTIONS=""
        for i in ${REMMINA_OPTIONS//,/ }
        do
            R_OPTIONS="$R_OPTIONS --set-option $i"
        done

        remmina --update-profile $REMMINA_PROFILE $R_OPTIONS
        unset REMMINA_OPTIONS
  fi
}

options=$(getopt -o gau: -l go,assign,url: -n "$0" -- "$@") || exit
eval set -- "$options"

while [[ $1 != -- ]]; do
    case $1 in
        -g|--go) GO='true'; shift 1;;
        -a|--assign) ASSIGN='true'; shift 1;;
        -u|--url) OPT_URL=$2; shift 2;;
        *) echo "bad option: $1" >&2; exit 1;;
    esac
done
shift

# Process non-option arguments.
for arg; do
    echo "arg! $arg"
done

FORCE=$2

kasm_exec() {
    if [ -n "$OPT_URL" ] ; then
        URL=$OPT_URL
    elif [ -n "$1" ] ; then
        URL=$1
    fi 
    
    # Since we are execing into a container that already has the browser running from startup, 
    #  when we don't have a URL to open we want to do nothing. Otherwise a second browser instance would open. 
    if [ -n "$URL" ] ; then
        /usr/bin/filter_ready
        /usr/bin/desktop_ready
        $START_COMMAND $ARGS $OPT_URL
    else
        echo "No URL specified for exec command. Doing nothing."
    fi
}

kasm_startup() {
    if [ -n "$KASM_URL" ] ; then
        URL=$KASM_URL
    elif [ -z "$URL" ] ; then
        URL=$LAUNCH_URL
    fi

    if [ -z "$DISABLE_CUSTOM_STARTUP" ] ||  [ -n "$FORCE" ] ; then

        if [[ $MAXIMUS == 'true' ]] ; then
            maximus &
        fi

        while true
        do
            if ! pgrep -x $PGREP > /dev/null
            then
                /usr/bin/filter_ready
                /usr/bin/desktop_ready
                set +e
                update_profile
                $START_COMMAND $ARGS $URL $REMMINA_PROFILE
                set -e
            fi
            sleep 1
        done
    
    fi

} 

if [ -n "$GO" ] || [ -n "$ASSIGN" ] ; then
    kasm_exec
else
    kasm_startup
fi
