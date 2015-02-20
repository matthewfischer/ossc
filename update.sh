#!/bin/bash

# packages:
# git libmysqlclient-dev python-tox libpq-dev python-dev
# libxml2-dev libxslt-dev libffi-dev python-libvirt pkg-config
# libvirt-dev

GEN_SERVICES="nova cinder glance ceilometer heat"
PREBUILT_SERVICES="keystone designate neutron"
BRANCH="master"

set -x

setup()
{
    SERVICE=$1
    cd ~/openstack/${SERVICE}
    git remote update
    echo "Generating ${BRANCH} for ${SERVICE}"
    git checkout ${BRANCH}
    git checkout .
    git pull
}

commit()
{
    SERVICE=$1
    cd ~/ossc
    git add samples
    git commit -a -m "${SERVICE}: ${LOG_SUFFIX}"
}

for SERVICE in ""${PREBUILT_SERVICES}""
do
    setup ${SERVICE}
    RELEASE=`basename ${BRANCH}`
    LOG_SUFFIX=`git log -n1 --oneline`
    echo "Last commit for ${SERVICE} is ${LOG_SUFFIX}"

    if [ "${SERVICE}" == "neutron" ]; then
        cp etc/${SERVICE}.conf ~/ossc/samples/
        cp etc/l3_agent.ini ~/ossc/samples/
        cp etc/metadata_agent.ini ~/ossc/samples/
        cp etc/dhcp_agent.ini ~/ossc/samples/
    else
        cp etc/${SERVICE}/${SERVICE}*conf.sample ~/ossc/samples/
    fi

    commit ${SERVICE}
done

for SERVICE in ""${GEN_SERVICES}""
do
    setup ${SERVICE}
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

    # ceilometer is also a snowflake, lots of snowflakes...
    if [ "${SERVICE}" == "ceilometer" ]; then
        cp etc/${SERVICE}/${SERVICE}.conf ~/ossc/samples/
    fi

    # heat broken: https://bugs.launchpad.net/heat/+bug/1412571
    if [ "${SERVICE}" == "heat" ]; then
        echo "heat is busted"
    fi

    commit ${SERVICE}

done
echo "Pushing"
cd ~/ossc
git push -u origin master
