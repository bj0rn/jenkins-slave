#!/bin/bash

source /usr/local/bin/jenkins-common.sh
# /usr/local/bin/jenkins-common.sh sets JENKINS_HOME to an incorrect value
export JENKINS_HOME=$HOME

generate_passwd_file `id -u` `id -g`

master_username=${JENKINS_USERNAME:-"admin"}
master_password=${JENKINS_PASSWORD:-"password"}
slave_executors=${EXECUTORS:-"1"}

if [[ $# -lt 1 ]] || [[ "$1" == "-"* ]]; then

  # jenkins swarm slave
  JAR=`ls -1 /opt/jenkins-slave/bin/swarm-client-*.jar | tail -n 1`

  if [[ "$@" != *"-master "* ]] && [ ! -z "$JENKINS_PORT_8080_TCP_ADDR" ]; then
	PARAMS="-master http://$JENKINS_SERVICE_HOST:$JENKINS_SERVICE_PORT -tunnel $JENKINS_SLAVE_SERVICE_HOST:$JENKINS_SLAVE_SERVICE_PORT -username ${master_username} -password ${master_password} -executors ${slave_executors}"
  fi

  echo Running java $JAVA_OPTS -jar $JAR -fsroot $HOME $PARAMS "$@"
  exec java $JAVA_OPTS -jar $JAR -fsroot $HOME $PARAMS "$@"
fi

exec "$@"
