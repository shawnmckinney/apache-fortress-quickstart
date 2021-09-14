![Apache Fortress](images/ApacheFortressLogo_FINAL_SM.png "Apache Fortress")

-------------------------------------------------------------------------------
# Overview of the apache-fortress-quickstart

 * This sample shows how to invoke Apache Fortress APIs using REST via command-line invocations w/ curl.
 * It also shows how to install Apache Fortress Rest component into an Apache Tomcat server instance and connect to a properly configured LDAP server.
 * Use the [DOCKER-QUICKSTART](./DOCKER-QUICKSTART.md) to run everything inside Docker containers.
 * The samples load a fictional security policy that correspond with another fortress sample called the [rbac-abac-sample](https://github.com/shawnmckinney/rbac-abac-sample).
 * Once system is setup, test services using curl, find out how here: [README-TESTING](README-TESTING.md)
-------------------------------------------------------------------------------
## Table of Contents
 * Prerequisites
 * SECTION 1. Prepare an LDAP Server
 * SECTION 2. Prepare Tomcat for Java EE Security
 * SECTION 3. Prepare apache-fortress-quickstart package
 * SECTION 4. Configure Apache Tomcat and Deploy Apache Fortress Rest

-------------------------------------------------------------------------------
## Prerequisites
1. Java 8++
2. Apache Maven 3++, to run the fortress load utility, to bootstrap server data.
3. Apache Tomcat 7++, to host the services.
4. Docker, to host the LDAP server.
5. Curl, to invoke/test fortress.

-------------------------------------------------------------------------------
## SECTION 1. Prepare an LDAP Server

 You may use the ApacheFortress Docker images for either OpenLDAP or ApacheDS:

 Option A: Pull and run the Symas OpenLDAP 2.5 prebuilt image:

 ```
 docker pull shawnmckinney/iamfortress:symas-openldap
 docker run  --name=openldap-fortress -d -p 32768:389 -P shawnmckinney/iamfortress:symas-openldap
 ```

 Option B: Pull and run the ApacheDS prebuilt image:

 ```
 docker pull apachedirectory/apacheds-for-apache-fortress-tests
 docker run --name=apacheds-fortress -d -p 32768:10389 -P apachedirectory/apacheds-for-apache-fortress-tests  
 ```

 *depending on your docker setup may need to run as root or sudo priv's.

-------------------------------------------------------------------------------
## SECTION 2. Prepare Tomcat for Java EE Security

Apache Fortress Rest uses Java EE security for basic authentication and coarse-grained authorization.

#### 1. Download the fortress realm proxy jar into tomcat/lib folder:

  ```bash
  wget https://repo.maven.apache.org/maven2/org/apache/directory/fortress/fortress-realm-proxy/[VERSION]/fortress-realm-proxy-[VERSION].jar -P $TOMCAT_HOME/lib
  ```

 * Where *$TOMCAT_HOME* points to the execution and *[VERSION]* is current version of Fortress Realm component, as of today, *2.0.5*.

#### 2. Restart tomcat so it can pick up the new jar file on its system classpath.

-------------------------------------------------------------------------------
## SECTION 3. Prepare apache-fortress-quickstart package

#### 1. Stage the project.

 a. Download and extract from Github:

 ```bash
 wget https://github.com/shawnmckinney/apache-fortress-quickstart/archive/master.zip
 ```

 -- Or --

 b. Or `git clone` locally:

 ```git
 git clone https://github.com/shawnmckinney/apache-fortress-quickstart.git
 ```

#### 2. Change directory into it:

 ```bash
 cd apache-fortress-quickstart
 ```

#### 3. Enable an LDAP server:

 a. Copy the example:

 ```bash
 cp src/main/resources/fortress.properties.example src/main/resources/fortress.properties
 ```

 b. Edit the file:

 ```bash
 vi src/main/resources/fortress.properties
 ```

 Pick either Apache Directory or OpenLDAP server:

 c. Prepare fortress for OpenLDAP usage:

 ```properties
 # This param tells fortress what type of ldap server in use:
 ldap.server.type=openldap

 # Use value from [Set Hostname Entry]:
 host=localhost

 # OpenLDAP defaults to this, natively:
 # port=389
 # OpenLDAP in Docker uses this:
 port=32768

 # These credentials are used for read/write access to all nodes under suffix:
 admin.user=cn=Manager,dc=example,dc=com
 admin.pw=secret
 ```

  -- Or --

 d. Prepare fortress for ApacheDS usage:

 ```properties
 # This param tells fortress what type of ldap server in use:
 ldap.server.type=apacheds

 # Use value from [Set Hostname Entry]:
 host=localhost

 # ApacheDS in Docker uses this:
 port=32768

 # These credentials are used for read/write access to all nodes under suffix:
 admin.user=uid=admin,ou=system
 admin.pw=secret
 ```

 * These values will work with the defaults, set within the Docker images.  You may need to change the port, to match what's currently being used.
 * If pointing to an existing LDAP server impl, change the coordinates accordingly.

#### 4. Verify the java and maven home env variables are set.

 ```maven
 mvn -version
 ```

 This sample requires Java 8 and Maven 3 to be setup within the execution env.

#### 5. Load security policy and configuration data into LDAP for Quickstart testing:

 a. Fortress Bootstrap creates the Directory Information Tree (DIT) structure and adds configuration parameters:

  ```maven
 mvn install -Dload.file=./src/main/resources/FortressBootstrap.xml
  ```

 b. The Fortress Rest Server Policy sets up a service account to have access to Apache Fortress Rest component:

  ```maven
 mvn install -Dload.file=./src/main/resources/FortressRestServerPolicy.xml
  ```

 Build Notes:
 * `-Dload.file` loads this file's data, [FortressRestServerPolicy](src/main/resources/FortressRestServerPolicy.xml), into ldap.
 * `-Dtenenat` can be used to specifies a tenant (subtree) being processed.

___________________________________________________________________________________
## SECTION 4. Configure Apache Tomcat and Deploy Apache Fortress Rest

Set the java system properties in tomcat with the target ldap server's coordinates.

#### 1. Edit the startup script for Tomcat

#### 2. Set the java opts

 a. For OpenLDAP:

 ```
 JAVA_OPTS="-Dfortress.host=localhost -Dfortress.port=32768 -Dfortress.admin.user=cn=manager,dc=example,dc=com -Dfortress.admin.pw=secret -Dfortress.min.admin.conn=1 -Dfortress.max.admin.conn=10 -Dfortress.ldap.server.type=openldap -Dfortress.enable.ldap.ssl=false -Dfortress.config.realm=DEFAULT -Dfortress.config.root=ou=config,dc=example,dc=com"
 ```

 b. For ApacheDS:

 ```
 JAVA_OPTS="-Dfortress.host=$HOSTNAME -Dfortress.port=32768 -Dfortress.admin.user=uid=admin,ou=system -Dfortress.admin.pw=secret -Dfortress.min.admin.conn=1 -Dfortress.max.admin.conn=10 -Dfortress.ldap.server.type=apacheds -Dfortress.enable.ldap.ssl=false -Dfortress.config.realm=DEFAULT -Dfortress.config.root=ou=config,dc=example,dc=com"
 ```

##### Notes on JAVA_OPTS
 * The prepacked .war pull down from maven uses java options to point to a particular Apache Fortress LDAP server.
 * These values will work with the defaults, set within the Docker images.  You may need to change the port, to match what's currently being used.
 * SECTION 4 Fortress Configuration Overrides contains an external property listing: [README-CONFIG](https://github.com/apache/directory-fortress-core/blob/master/README-CONFIG.md)

#### 3. Verify these settings match your target LDAP server.

#### 4. Download the fortress rest war into tomcat/webapps folder:

  ```bash
  wget https://repo.maven.apache.org/maven2/org/apache/directory/fortress/fortress-rest/[VERSION]/fortress-rest-[VERSION].war -P $TOMCAT_HOME/webapps
  ```

  * Where *TOMCAT_HOME* matches your target env and *[VERSION]* is latest Fortress Rest Component, as of today *2.0.6*.
