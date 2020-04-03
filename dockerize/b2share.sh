#!/bin/bash -e
# This file is supposed to live in a docker container

# wait for all the services to start
# FIXME: we should have some shell code to check that instead of a sleep.
sleep 30

B2SHARE_INSTANCE="${B2SHARE_INSTANCE:-/usr/var/b2share-instance}"

mkdir -p ${B2SHARE_INSTANCE}/files

if [ ! -f ${B2SHARE_INSTANCE}/provisioned ]; then

    # if a config file already exists, continue
    b2share demo load-config || true

    if [ "${INIT_DB_AND_INDEX}" = "1" ]; then
        b2share db init
        b2share upgrade run -v
        sleep 20
    fi

    if [ "${LOAD_DEMO_COMMUNITIES_AND_RECORDS}" = "1" ]; then
        b2share demo load-data
    elif [ "${INIT_DB_AND_INDEX}" = "1" ]; then
        # add default location
        b2share files add-location 'local' file://${B2SHARE_INSTANCE}/files --default
    fi

    touch ${B2SHARE_INSTANCE}/provisioned
fi

# safe to run even when up to date
b2share upgrade run -v

supervisord
