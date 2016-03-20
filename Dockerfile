FROM centos:centos7

ENV JDK_VERSION=8u66 \
    JDK_BUILD_VERSION=b17 \
    JENKINS_SWARM_VERSION=2.0 \
    HOME=/var/lib/jenkins \
    LANG=en_US.utf8

RUN curl http://pkg.jenkins-ci.org/redhat/jenkins.repo -o /etc/yum.repos.d/jenkins.repo && \
    rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key && \
    yum -y --setopt=tsflags=nodocs --disableplugin=fastestmirror install epel-release && \
    sed -i -- 's/\#baseurl/baseurl/g' /etc/yum.repos.d/epel.repo && \
    sed -i -- 's/mirrorlist/\#mirrorlist/g' /etc/yum.repos.d/epel.repo && \
    yum -y --setopt=tsflags=nodocs --disableplugin=fastestmirror install gettext git tar zip unzip nss_wrapper && \
    yum clean all  && \
    localedef -f UTF-8 -i en_US en_US.utf8

RUN yum -y --disableplugin=fastestmirror groupinstall "Development Tools" && yum clean all

RUN useradd -u 1001 -r -m -d ${HOME} -s /sbin/nologin -c "Jenkins Slave" jenkins && \
    mkdir -p ${HOME}/bin

RUN curl -O https://codeload.github.com/openshift/jenkins/zip/master && \
    unzip master && \
    mv /jenkins-master/1/contrib/openshift /opt/openshift && \
    mv /jenkins-master/1/contrib/jenkins/* /usr/local/bin && \
    rm -rf /jenkins-master

RUN chown -R 1001:0 /opt/openshift && \
    /usr/local/bin/fix-permissions /opt/openshift && \
    /usr/local/bin/fix-permissions ${HOME}

# Download plugin and modify permissions
RUN curl --create-dirs -sSLo /opt/jenkins-slave/bin/swarm-client-$JENKINS_SWARM_VERSION-jar-with-dependencies.jar http://maven.jenkins-ci.org/content/repositories/releases/org/jenkins-ci/plugins/swarm-client/$JENKINS_SWARM_VERSION/swarm-client-$JENKINS_SWARM_VERSION-jar-with-dependencies.jar

# Install Java
ENV JDK_VERSION=8u66 \
    JDK_BUILD_VERSION=b17
RUN curl -LO "http://download.oracle.com/otn-pub/java/jdk/$JDK_VERSION-$JDK_BUILD_VERSION/jdk-$JDK_VERSION-linux-x64.rpm" -H 'Cookie: oraclelicense=accept-securebackup-cookie' && \
    rpm -i jdk-$JDK_VERSION-linux-x64.rpm && \
    rm -f jdk-$JDK_VERSION-linux-x64.rpm

# Add Openshift command line interface (OC)
RUN curl -L --insecure https://github.com/openshift/origin/releases/download/v1.1.1/openshift-origin-server-v1.1.1-e1d9873-linux-64bit.tar.gz | tar -zx && \
    mv openshift-origin-server-v1.1.1-e1d9873-linux-64bit/oc /usr/local/bin && \
    rm -r openshift-origin-server-v1.1.1-e1d9873-linux-64bit

COPY home ${HOME}

# The home folder needs to be world writeable to allow the random user assigned to running the slave pod on Openshift
# to write to the folder
RUN chmod -R 777 ${HOME} && chown -R 1001:0 ${HOME}

USER 1001

ENTRYPOINT ["/var/lib/jenkins/bin/jenkins-slave.sh"]
