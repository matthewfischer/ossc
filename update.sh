#!/bin/bash

# packages:
# git libmysqlclient-dev python-tox libpq-dev python-dev
# libxml2-dev libxslt-dev libffi-dev python-libvirt pkg-config
# libvirt-dev

# heat is broken as of Feb 19 2015
# neutron doesn't seem to have the option at all

SERVICES="nova cinder glance ceilometer"
BRANCHES="master"

set -x
#set -e

for SERVICE in ""${SERVICES}""
do
    cd ~/openstack/${SERVICE}
    git remote update
    for BRANCH in ""${BRANCHES}""
    do
        echo "Generating ${BRANCH} for ${SERVICE}"
        git checkout ${BRANCH}
        git reset origin/${BRANCH}
        git pull
        rm -rf .venv
        tox -egenconfig
        RELEASE=`basename ${BRANCH}`
        LOG_SUFFIX=`git log -n1 --oneline`
        echo "Last commit for ${SERVICE} is ${LOG_SUFFIX}"
        cp etc/${SERVICE}/${SERVICE}*conf.sample ~/ossc/samples/
        # glance is special for some annoying reason
        if [ "${SERVICE}" == "glance" ]; then
            cp etc/${SERVICE}*conf.sample ~/ossc/samples/
        fi
        cd ~/ossc
        git add samples
        git commit -a -m "${SERVICE}: ${LOG_SUFFIX}"
    done
done
echo "Pushing"
cd ~/ossc
git push -u origin master
