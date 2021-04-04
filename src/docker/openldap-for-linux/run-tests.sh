#!/bin/sh
#
#   Licensed to the Apache Software Foundation (ASF) under one
#   or more contributor license agreements.  See the NOTICE file
#   distributed with this work for additional information
#   regarding copyright ownership.  The ASF licenses this file
#   to you under the Apache License, Version 2.0 (the
#   "License"); you may not use this file except in compliance
#   with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing,
#   software distributed under the License is distributed on an
#   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#   KIND, either express or implied.  See the License for the
#   specific language governing permissions and limitations
#   under the License.
#

# stop execution if any command fails (i.e. exits with status code > 0)
set -e

# trace commands
set -x

# startup docker container
docker pull apachedirectory/openldap-for-linux-apache-fortress-tests
CONTAINER_ID=$(docker run -d -P apachedirectory/openldap-for-linux-apache-fortress-tests)
CONTAINER_PORT=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "389/tcp") 0).HostPort}}' $CONTAINER_ID)
echo $CONTAINER_PORT

# configure build.properties
cp build.properties.example build.properties
#cp slapd.properties.example slapd.properties
sed -i 's/^ldap\.host=.*/ldap.host=localhost/' slapd.properties
sed -i 's/^ldap\.port=.*/ldap.port='${CONTAINER_PORT}'/' slapd.properties

# prepare
mvn clean install
mvn install -Dload.file=./ldap/setup/refreshLDAPData.xml

# run tests
mvn test -Dtest=FortressJUnitTest

# rerun tests to verify teardown APIs work
mvn test -Dtest=FortressJUnitTest

# stop and delete docker container
docker stop $CONTAINER_ID
docker rm $CONTAINER_ID
