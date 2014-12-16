#!/usr/bin/env bash
# ex: set ts=4 sw=4 tw=0:
# ex: set expandtab:

function usage() {
    echo "Usage: $0 -n [upgrade_demo|another_app_name] -v VERSION" 1>&2; exit 1
}

function change_version() {
    sed -e "s/###VERSION_TEMPLATE###/${VERSION}/" ${1}.template > $1
}

RELEASE_APP=("upgrade_demo", "another_app_name")

while getopts ":n:v:" o; do
    case "${o}" in
        n)
            RELEASE_NAME=${OPTARG}
            if [[ ! ${RELEASE_APP[*]} =~ $RELEASE_NAME ]]; then
                usage
            fi
            ;;
        v)
            VERSION=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${RELEASE_NAME}" ] || [ -z "${VERSION}" ]; then
    usage
fi

RUNNER_SCRIPT_DIR=$(cd ${0%/*} && pwd)
ROOT=$(echo $RUNNER_SCRIPT_DIR | sed -e "s/\(.*${RELEASE_NAME}\).*$/\1/")
REL_ROOT=$ROOT/rel
RELEASES_DIR=$REL_ROOT/$RELEASE_NAME/releases
RELEASE_BIN_DIR=$REL_ROOT/$RELEASE_NAME/bin
REBAR=$ROOT/rebar

cd $RELEASE_BIN_DIR

if [ ! -x $RELEASE_NAME ]; then
    chmod +x $RELEASE_NAME
fi

if [ -z "`./$RELEASE_NAME ping | grep pong`" ]; then
    echo $RELEASE_NAME is not running
    exit 1
fi

REL_CONFIG_FILE=$REL_ROOT/reltool.config

for FILE_PATH in `find ${ROOT} -name '*.app.src'` $REL_CONFIG_FILE
do
    change_version $FILE_PATH
done

cd $ROOT

$REBAR compile

if [ ! $? -eq 0 ]; then
    echo "compile error\n"
    exit 1
fi

cd $REL_ROOT

$REBAR generate target_dir=update_tmp/$RELEASE_NAME
$REBAR generate-appups target_dir=update_tmp/$RELEASE_NAME previous_release=../$RELEASE_NAME
$REBAR generate-upgrade target_dir=update_tmp/$RELEASE_NAME previous_release=../$RELEASE_NAME

rm -r update_tmp
mv -v ${RELEASE_NAME}_${VERSION}.tar.gz $RELEASES_DIR

cd $RELEASE_BIN_DIR
./${RELEASE_NAME} upgrade ${RELEASE_NAME}_${VERSION}

echo done
