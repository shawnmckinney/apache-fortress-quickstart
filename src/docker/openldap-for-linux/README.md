
   Licensed to the Apache Software Foundation (ASF) under one
   or more contributor license agreements.  See the NOTICE file
   distributed with this work for additional information
   regarding copyright ownership.  The ASF licenses this file
   to you under the Apache License, Version 2.0 (the
   "License"); you may not use this file except in compliance
   with the License.  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing,
   software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
   KIND, either express or implied.  See the License for the
   specific language governing permissions and limitations
   under the License.

OpenLDAP for Linux Apache Fortress tests
==================================

This directory contains

* a `Dockerfile` for building a Docker image with preconfigured for Fortress to run on OpenLDAP for Linux
* a `run-tests.sh` script that start such a Docker container and executes the Fortress tests against it

Build image (run from fortress-core root folder)

```bash
docker build -t shawnmckinney/iamfortress:openldap-for-linux -f src/docker/openldap-for-linux/Dockerfile .
```

Push image to docker hub:

```bash
docker push shawnmckinney/iamfortress:openldap-for-linux
``` 

Run image:

```bash
docker run  -d -p 32768:389 -P shawnmckinney/iamfortress:openldap-for-linux
```
