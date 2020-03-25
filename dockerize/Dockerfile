FROM centos:7
EXPOSE 5000

RUN rpm -iUvh http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-12.noarch.rpm

RUN yum -y update
RUN yum -y groupinstall "Development tools"
RUN yum -y install wget gcc-c++ openssl-devel \
                   postgresql-devel mysql-devel \
                   git libffi-devel libxml2-devel libxml2 \
                   libxslt-devel zlib1g-dev libxslt http-parser uwsgi

# Install Node...

RUN curl -sL https://rpm.nodesource.com/setup_12.x | bash -
RUN yum clean all && yum makecache fast
RUN yum install -y gcc-c++ make
RUN yum install -y nodejs

# Install Python...

ENV PYTHON_VER=3.6
ENV PYTHON_PRG=/usr/bin/python${PYTHON_VER}
ENV PYTHON_ENV=/opt/venv
ENV PYTHON_LIB=${VIRTUAL_ENV}/lib/python${PYTHON_VER}

RUN echo -e \
    "\tPYTHON VERSION : $PYTHON_VER\n" \
    "\tPYTHON PROGRAM : $PYTHON_PRG\n" \
    "\tPYTHON VIRTUAL : $PYTHON_ENV\n" \
    "\tPYTHON LIBRARY : $PYTHON_LIB\n"

RUN yum -y install https://centos7.iuscommunity.org/ius-release.rpm
RUN yum -y install python${PYTHON_VER//.} python${PYTHON_VER//.}-pip python${PYTHON_VER//.}-devel python${PYTHON_VER//.}-virtualenv

RUN ${PYTHON_PRG} -m virtualenv --python=${PYTHON_PRG} ${PYTHON_ENV}
ENV PATH="$PYTHON_ENV/bin:$PATH"

# Install uwsgi
RUN pip install uwsgi

# Install Supervisor from this location. yum package is not yet available for Python3.x
RUN pip install git+https://github.com/Supervisor/supervisor

# install locale
RUN localedef -c -f UTF-8 -i en_US en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV DB_NAME="b2share-evolution"
ENV B2SHARE_UI_PATH="/eudat/b2share/webui/app"
ENV B2SHARE_BROKER_URL="redis://redis:6379/0"
ENV B2SHARE_ACCOUNTS_SESSION_REDIS_URL="redis://redis:6379/0"
ENV B2SHARE_CELERY_RESULT_BACKEND="redis://redis:6379/1"
ENV B2SHARE_SEARCH_ELASTIC_HOSTS="elasticsearch:9200"

#
# Install public-license-selector
#

WORKDIR /eudat
RUN git clone https://github.com/EUDAT-B2SHARE/public-license-selector.git
WORKDIR /eudat/public-license-selector
RUN npm install

# this next RUN is just a workaround for the old version of node on centos7
# without it, the npm run build fails when compiling less files
RUN mv webpack.config.js webpack.config.js.0
RUN echo "require('es6-promise').polyfill();" > webpack.config.js
RUN cat webpack.config.js.0 >> webpack.config.js
RUN npm install es6-promise

RUN npm run build

RUN node_modules/webpack/bin/webpack.js -p
RUN mkdir -p /eudat/b2share/webui/app/vendors
RUN cp dist/license-selector.* /eudat/b2share/webui/app/vendors/

#
# Install B2Share webui module and dependencies
#

WORKDIR /eudat
ADD ./webui/package.json b2share/webui/package.json
ADD ./webui/copy_files.sh b2share/webui/copy_files.sh

WORKDIR /eudat/b2share/webui
RUN npm install # --unsafe-perm

# Patch for invenio-deposit
RUN pip install configparser
RUN cp ${PYTHON_ENV}/lib/python${PYTHON_VER}/site-packages/configparser.py ${PYTHON_ENV}/lib/python${PYTHON_VER}/site-packages/ConfigParser.py
RUN pip uninstall enum34

#
# UWSGI Config
#

WORKDIR /eudat
ADD dockerize/uwsgi.ini b2share/uwsgi/uwsgi.ini

#
# Install python module and dependencies
#

WORKDIR /eudat/b2share
ADD setup.py setup.py
ADD b2share/version.py b2share/version.py

RUN pip install -e .

WORKDIR /eudat/b2share/demo
ADD demo/setup.py setup.py
RUN pip install -e .

COPY dockerize/b2share.sh /eudat/
COPY dockerize/supervisord.conf /etc/

#
# Copy the rest of B2Share files
#

WORKDIR /eudat/b2share
ADD webui webui
WORKDIR /eudat/b2share/webui
RUN node_modules/webpack/bin/webpack.js -p

WORKDIR /eudat
ADD . b2share

WORKDIR /eudat/b2share
CMD ["/eudat/b2share.sh"]
