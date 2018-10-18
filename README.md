# apache-fortress-quickstart
Work-In-Progress


# Overview of the apache-fortress-quickstart README

 * This document demonstrates how to install Apache Fortress Rest component to Apache Tomcat server and connect to a properly configured LDAP server.
 * It also shows how to run services using curl.

-------------------------------------------------------------------------------
## Table of Contents
 * SECTION 1. Prerequisites
 * SECTION 2. Prepare Tomcat for Java EE Security
 * SECTION 3. Prepare apache-fortress-quickstart package
 * SECTION 4. Configure Apache Tomcat and Deploy Apache Fortress Rest
 * SECTION 5. Test Apache Fortress Rest with Curl
 * SECTION 6. Understand the security policy
 * SECTION 7. Under the Hood (Learn how it works here)

-------------------------------------------------------------------------------
## SECTION I. Prerequisites
1. Java 8
2. Apache Maven 3++
3. Apache Tomcat 7++
4. Basic LDAP server setup by completing either Quickstart
    * [OpenLDAP & Fortress QUICKSTART on DOCKER](https://github.com/apache/directory-fortress-core/blob/master/README-QUICKSTART-DOCKER-SLAPD.md)
    * [APACHEDS & Fortress QUICKSTART on DOCKER](https://github.com/apache/directory-fortress-core/blob/master/README-QUICKSTART-DOCKER-APACHEDS.md)

-------------------------------------------------------------------------------
## SECTION II. Prepare Tomcat for Java EE Security

This sample web app uses Java EE security.

#### 1. Download the fortress realm proxy jar into tomcat/lib folder:

  ```bash
  wget http://repo.maven.apache.org/maven2/org/apache/directory/fortress/fortress-realm-proxy/2.0.2/fortress-realm-proxy-2.0.2.jar -P $TOMCAT_HOME/lib
  ```

 * Where `$TOMCAT_HOME` points to the execution env.

 Note: The realm proxy enables Tomcat container-managed security functions to call back to fortress.

#### 2. Restart tomcat so it can pick up the new jar file on its system classpath.

-------------------------------------------------------------------------------
## SECTION III. Prepare apache-fortress-quickstart package

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

 c. Prepare fortress for ApacheDS usage:

 ```properties
 # This param tells fortress what type of ldap server in use:
 ldap.server.type=apacheds

 # Use value from [Set Hostname Entry]:
 host=localhost

 # ApacheDS defaults to this:
 port=10389

 # These credentials are used for read/write access to all nodes under suffix:
 admin.user=uid=admin,ou=system
 admin.pw=secret
 ```

 -- Or --

 d. Prepare fortress for OpenLDAP usage:

 ```properties
 # This param tells fortress what type of ldap server in use:
 ldap.server.type=openldap

 # Use value from [Set Hostname Entry]:
 host=localhost

 # OpenLDAP defaults to this:
 port=389

 # These credentials are used for read/write access to all nodes under suffix:
 admin.user=cn=Manager,dc=example,dc=com
 admin.pw=secret
 ```

#### 4. Verify the java and maven home env variables are set.

 ```maven
 mvn -version
 ```

 This sample requires Java 8 and Maven 3 to be setup within the execution env.

#### 5. Load security policy and configuration data into LDAP for Quickstart testing:

  ```maven
 mvn install -Dload.file=./src/main/resources/FortressRestServerPolicy.xml
  ```

 Build Notes:
 * `-Dload.file` above points to [FortressRestServerPolicy](src/main/resources/FortressRestServerPolicy.xml) data into ldap.

___________________________________________________________________________________
## SECTION IV. Configure Apache Tomcat and Deploy Apache Fortress Rest

Set the java system properties in tomcat with the target ldap server's coordinates.

#### 1. Edit the startup script for Tomcat

#### 2. Set the java opts

 a. For OpenLDAP SSL:

 ```
 JAVA_OPTS="-Dfortress.host=$HOSTNAME -Dfortress.port=636 -Dfortress.admin.user=cn=manager,dc=example,dc=com -Dfortress.admin.pw='secret' -Dfortress.min.admin.conn=1 -Dfortress.max.admin.conn=10 -Dfortress.ldap.server.type=openldap -Dfortress.enable.ldap.ssl=true -Dfortress.trust.store=mytruststore -Dfortress.trust.store.password=changeit -Dfortress.trust.store.onclasspath=true -Dfortress.config.realm=DEFAULT -Dfortress.config.root=ou=config,dc=example,dc=com"
 ```

 b. For OpenLDAP non-SSL:

 ```
 JAVA_OPTS="-Dfortress.host=$HOSTNAME -Dfortress.port=389 -Dfortress.admin.user=cn=manager,dc=example,dc=com -Dfortress.admin.pw='secret' -Dfortress.min.admin.conn=1 -Dfortress.max.admin.conn=10 -Dfortress.ldap.server.type=openldap -Dfortress.enable.ldap.ssl=false -Dfortress.config.realm=DEFAULT -Dfortress.config.root=ou=config,dc=example,dc=com"
 ```

 c. For ApacheDS SSL:

 ```
 JAVA_OPTS="-Dfortress.host=$HOSTNAME -Dfortress.port=10636 -Dfortress.admin.user=uid=admin,ou=system -Dfortress.admin.pw='secret' -Dfortress.min.admin.conn=1 -Dfortress.max.admin.conn=10 -Dfortress.ldap.server.type=apacheds -Dfortress.enable.ldap.ssl=true -Dfortress.trust.store=mytruststore -Dfortress.trust.store.password=changeit -Dfortress.trust.store.onclasspath=true -Dfortress.config.realm=DEFAULT -Dfortress.config.root=ou=config,dc=example,dc=com"
 ```

 d. For ApacheDS non-SSL:

 ```
 JAVA_OPTS="-Dfortress.host=$HOSTNAME -Dfortress.port=10389 -Dfortress.admin.user=uid=admin,ou=system -Dfortress.admin.pw='secret' -Dfortress.min.admin.conn=1 -Dfortress.max.admin.conn=10 -Dfortress.ldap.server.type=apacheds -Dfortress.enable.ldap.ssl=false -Dfortress.config.realm=DEFAULT -Dfortress.config.root=ou=config,dc=example,dc=com"
 ```

##### Notes on JAVA_OPTS
 * The prepacked .war pull down from maven uses java options to point to a particular Apache Fortress LDAP server.
 * Be sure to replace these values with the correct values corresponding with your LDAP server.
 * For example, $HOSTNAME should be replaced with localhost, if LDAP server is running locally.
 * These values can also ride inside of the fortress.properties config file.  For more info: [README-CONFIG](https://github.com/apache/directory-fortress-core/blob/master/README-CONFIG.md)

#### 3. Verify these settings match your target LDAP server.

#### 4. Download the fortress rest war into tomcat/webapps folder:

  ```
  wget http://repo.maven.apache.org/maven2/org/apache/directory/fortress/fortress-rest/2.0.2/fortress-rest-2.0.2.war -P $TOMCAT_HOME/webapps
  ```

  where *TOMCAT_HOME* matches your target env.

___________________________________________________________________________________
## SECTION V. Test Apache Fortress Rest with Curl

Run the following curl commands from src/test/resources folder, where the request xml files are located.  Use a password of 'password' for the tests.

#### 1. Add Role:

 ```
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-role-bankuser.xml http://localhost:8080/fortress-rest-2.0.2/roleAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-role-teller.xml http://localhost:8080/fortress-rest-2.0.2/roleAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-role-washer.xml http://localhost:8080/fortress-rest-2.0.2/roleAdd
 ```

##### Sample request add role bank_users
 ```:
 <FortRequest>
      <contextId>HOME</contextId>
      <entity xsi:type="role" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
         <name>Bank_Users</name>
         <description>Test Role for Bank Users in Fortress RBAC-ABAC Demo.</description>
      </entity>
 </FortRequest>
 ```

#### 2. Enable Role Constraint:

 ```
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-enable-role-tellers-constraint-locale.xml http://localhost:8080/fortress-rest-2.0.2/roleEnableConstraint
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-enable-role-washers-constraint-locale.xml http://localhost:8080/fortress-rest-2.0.2/roleEnableConstraint
 ```

##### Sample request to constrain role Tellers by locale:

 ```
 <FortRequest>
 	<contextId>HOME</contextId>
 	<entity xsi:type="role" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 		<name>tellers</name>
 	</entity>
 	<entity2 xsi:type="roleConstraint" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 		<key>locale</key>
         <type>NA</type>
 	</entity2>
 </FortRequest>
 ```

#### 3. Search Role:

 ```
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-search-role.xml http://localhost:8080/fortress-rest-2.0.2/roleSearch
 ```

##### Sample request will pull back all roles
 ```
 <FortRequest>
    <contextId>HOME</contextId>
    <value></value>
 </FortRequest>
 ```

#### 4. Add User:

 ```
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-user-curly.xml http://localhost:8080/fortress-rest-2.0.2/userAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-user-moe.xml http://localhost:8080/fortress-rest-2.0.2/userAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-user-larry.xml http://localhost:8080/fortress-rest-2.0.2/userAdd
 ```

##### Sample request add Curly:

 ```
 <FortRequest>
      <contextId>HOME</contextId>
      <entity xsi:type="user" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
         <userId>curly</userId>
         <description>curly is a test user</description>
         <ou>default</ou>
         <sn>horowitz</sn>
         <cn>curly horowitz</cn>
      </entity>
 </FortRequest>
 ```

#### 5. Search Users:

 ```
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-search-user.xml http://localhost:8080/fortress-rest-2.0.2/userSearch
 ```

##### Sample request pull back all users

 ```
 <FortRequest>
    <entity xsi:type="user" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <userId>demouser4</userId>
    </entity>
    <contextId>HOME</contextId>
 </FortRequest>
 ```

#### 6. Assign Users to Roles:

 ```
 # Curly:
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-assign-curly-bankuser.xml http://localhost:8080/fortress-rest-2.0.2/roleAsgn
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-assign-curly-teller.xml http://localhost:8080/fortress-rest-2.0.2/roleAsgn
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-assign-curly-washer.xml http://localhost:8080/fortress-rest-2.0.2/roleAsgn
 # Moe:
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-assign-moe-bankuser.xml http://localhost:8080/fortress-rest-2.0.2/roleAsgn
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-assign-moe-teller.xml http://localhost:8080/fortress-rest-2.0.2/roleAsgn
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-assign-moe-washer.xml http://localhost:8080/fortress-rest-2.0.2/roleAsgn
 # Larry:
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-assign-larry-bankuser.xml http://localhost:8080/fortress-rest-2.0.2/roleAsgn
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-assign-larry-teller.xml http://localhost:8080/fortress-rest-2.0.2/roleAsgn
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-assign-larry-washer.xml http://localhost:8080/fortress-rest-2.0.2/roleAsgn
 ```

##### Sample request to assign curly to bank_users role

 ```
 <FortRequest>
      <contextId>HOME</contextId>
      <entity xsi:type="userRole" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
         <userId>curly</userId>
         <name>bank_users</name>
      </entity>
 </FortRequest>
 ```

#### 7. Add User Role Constraint:

 ```
 # Curly:
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-userrole-constraint-curly-teller-locale-east.xml http://localhost:8080/fortress-rest-2.0.2/addRoleConstraint
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-userrole-constraint-curly-washer-locale-north.xml http://localhost:8080/fortress-rest-2.0.2/addRoleConstraint
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-userrole-constraint-curly-washer-locale-south.xml http://localhost:8080/fortress-rest-2.0.2/addRoleConstraint
 # Moe:
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-userrole-constraint-larry-teller-locale-south.xml http://localhost:8080/fortress-rest-2.0.2/addRoleConstraint
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-userrole-constraint-larry-washer-locale-east.xml http://localhost:8080/fortress-rest-2.0.2/addRoleConstraint
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-userrole-constraint-larry-washer-locale-north.xml http://localhost:8080/fortress-rest-2.0.2/addRoleConstraint
 # Larry:
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-userrole-constraint-moe-teller-locale-north.xml http://localhost:8080/fortress-rest-2.0.2/addRoleConstraint
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-userrole-constraint-moe-washer-locale-east.xml http://localhost:8080/fortress-rest-2.0.2/addRoleConstraint
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-userrole-constraint-moe-washer-locale-south.xml http://localhost:8080/fortress-rest-2.0.2/addRoleConstraint
 ```

##### Sample request to add user-role constraint

 ```
 <FortRequest>
    <contextId>HOME</contextId>
    <entity xsi:type="userRole" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <name>tellers</name>
        <userId>curly</userId>
    </entity>
    <entity2 xsi:type="roleConstraint" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <key>locale</key>
        <value>east</value>
        <type>USER</type>
    </entity2>
 </FortRequest>
 ```

#### 8. Test Add Permission Object

 ```
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-perm-object-account.xml http://localhost:8080/fortress-rest-2.0.2/objAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-perm-object-branch.xml http://localhost:8080/fortress-rest-2.0.2/objAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-perm-object-currency.xml http://localhost:8080/fortress-rest-2.0.2/objAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-perm-object-home.xml http://localhost:8080/fortress-rest-2.0.2/objAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-perm-object-teller.xml http://localhost:8080/fortress-rest-2.0.2/objAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-perm-object-washer.xml http://localhost:8080/fortress-rest-2.0.2/objAdd
 ```

##### Sample request to add a permission object for account:

 ```
 <FortRequest>
	<contextId>HOME</contextId>
	<entity xsi:type="permObj" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
		<objName>Account</objName>
		<description>Resource to control account test ops</description>
		<ou>default</ou>
	</entity>
 </FortRequest>
 ```

#### 9. Test Add Permission Operation

 ```
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-perm-operation-account-deposit.xml http://localhost:8080/fortress-rest-2.0.2/permAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-perm-operation-account-inquiry.xml http://localhost:8080/fortress-rest-2.0.2/permAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-perm-operation-account-withdrawal.xml http://localhost:8080/fortress-rest-2.0.2/permAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-perm-operation-branch-login.xml http://localhost:8080/fortress-rest-2.0.2/permAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-perm-operation-currency-dry.xml http://localhost:8080/fortress-rest-2.0.2/permAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-perm-operation-currency-rinse.xml http://localhost:8080/fortress-rest-2.0.2/permAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-perm-operation-currency-soak.xml http://localhost:8080/fortress-rest-2.0.2/permAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-perm-operation-teller-link.xml http://localhost:8080/fortress-rest-2.0.2/permAdd
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-add-perm-operation-washer-link.xml http://localhost:8080/fortress-rest-2.0.2/permAdd
 ```

##### Sample request to add permission to login to branch:

 ```
 <FortRequest>
 	<contextId>HOME</contextId>
 	<entity xsi:type="permission" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 		<objName>Branch</objName>
 		<opName>login</opName>
 	</entity>
 </FortRequest>
 ```

#### 10. Test Grant Role to Permission

 ```
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-grant-role-bankuser-perm-branch-login.xml http://localhost:8080/fortress-rest-2.0.2/roleGrant
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-grant-role-teller-perm-account-deposit.xml http://localhost:8080/fortress-rest-2.0.2/roleGrant
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-grant-role-teller-perm-account-inquiry.xml http://localhost:8080/fortress-rest-2.0.2/roleGrant
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-grant-role-teller-perm-account-withdrawal.xml http://localhost:8080/fortress-rest-2.0.2/roleGrant
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-grant-role-teller-perm-teller-link.xml http://localhost:8080/fortress-rest-2.0.2/roleGrant
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-grant-role-washer-perm-currency-dry.xml http://localhost:8080/fortress-rest-2.0.2/roleGrant
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-grant-role-washer-perm-currency-rinse.xml http://localhost:8080/fortress-rest-2.0.2/roleGrant
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-grant-role-washer-perm-currency-soak.xml http://localhost:8080/fortress-rest-2.0.2/roleGrant
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-grant-role-washer-perm-washer-link.xml http://localhost:8080/fortress-rest-2.0.2/roleGrant
 ```

##### Sample request to grant bankusers to login to branch

 ```
 <FortRequest>
 	<contextId>HOME</contextId>
 	<entity xsi:type="permGrant" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 		<objName>Branch</objName>
 		<opName>login</opName>
 		<roleNm>Bank_Users</roleNm>
 	</entity>
 </FortRequest>
 ```

#### 11. Search Permissions:

 ```
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-search-perms.xml http://localhost:8080/fortress-rest-2.0.2/permSearch
 ```

##### Sample request to pull back all Permissions

 ```
 <FortRequest>
    <contextId>HOME</contextId>
    <entity xsi:type="permGrant" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <objName></objName>
        <opName></opName>
    </entity>
 </FortRequest>
 ```

#### 12. Create Session

 ```
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-create-session-curly.xml http://localhost:8080/fortress-rest-2.0.2/rbacCreateT
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-create-session-moe.xml http://localhost:8080/fortress-rest-2.0.2/rbacCreateT
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-create-session-larry.xml http://localhost:8080/fortress-rest-2.0.2/rbacCreateT
 ```

 * Note: The role Tellers will be activated in this example, Washers will not, due to role constraints.

##### Sample request to Create Session for curly, locale=east

 ```
 <FortRequest>
      <contextId>HOME</contextId>
      <entity xsi:type="user" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
         <userId>curly</userId>
         <props><entry><key>locale</key><value>east</value></entry></props>
      </entity>
 </FortRequest>
 ```

#### 13. Test Check Access

 ```
 curl -X POST -u 'demouser4' -H 'Content-type: text/xml' -k -d @test-check-access-curly-account-withdrawal.xml http://localhost:8080/fortress-rest-2.0.2/rbacAuthZ
 ```

##### Sample request to Check Access for curly


-------------------------------------------------------------------------------
## SECTION VI. Understand the security policy

App comprised of three pages, each has buttons and links that are guarded by permissions.  The permissions are granted to a particular user via their role activations.

#### 1. User-to-Role Assignment Table

 For this app, user-to-role assignments are:

| user       | Tellers     | Washers  |
| ---------- | ----------- | -------- |
| curly      | true        | true     |
| moe        | true        | true     |
| larry      | true        | true     |

#### 2. User-to-Role Activation Table by Branch

 But we want to control role activation using attributes based on Branch location:

| user       | Tellers   | Washers       |
| ---------- | --------- | ------------- |
| curly      | East      | North, South  |
| moe        | North     | East, South   |
| larry      | South     | North, East   |

 *Even though the test users are assigned both roles, they are limited which can be activated by branch.*

#### 3. Role-to-Role Dynamic Separation of Duty Constraint Table

 Furthermore due to toxic combination, we must never let a user activate both roles simultaneously regardless of location. For that, we'll use a dynamic separation of duty policy.

| set name      | Set Members   | Cardinality   |
| ------------- | ------------- | ------------- |
| Bank Safe     | Washers       | 2             |
|               | Tellers       |               |
|               |               |               |

#### 4. Role-Permission Table Links

 The page links are guarded by RBAC permissions that dependent on which roles are active in the session.

| role       | WashersPage | TellersPage |
| ---------- | ----------- | ----------- |
| Tellers    | false       | true        |
| Washers    | true        | false       |

#### 5. Role-Permission Table Buttons

 The buttons on the page are also guarded by RBAC permissions.

| role       | Account.deposit | Account.withdrawal | Account.inquiry  | Currency.soak | Currency.rise | Currency.dry |
| ---------- | --------------- | ------------------ | ---------------- | ------------- | ------------- | ------------ |
| Tellers    | true            | true               | true             | false         | false         | false        |
| Washers    | false           | false              | false            | true          | true          | true         |


-------------------------------------------------------------------------------
## SECTION VII. Under the Hood

 How does this work?  Have a look at some code...

 Paraphrased from [WicketSampleBasePage.java](src/main/java/org/rbacabac/WicketSampleBasePage.java):

 ```java
 // Nothing new here:
  User user = new User(userId);

  // This is new:
  RoleConstraint constraint = new RoleConstraint( );

  // In practice we're not gonna pass hard-coded key-values in here, but you get the idea:
  constraint.setKey( "locale" );
  constraint.setValue( "north" );

  // This is just boilerplate goop:
  List<RoleConstraint> constraints = new ArrayList();
  constraints.add( constraint );

  try
  {
      // Now, create the RBAC session with an ABAC constraint, locale=north, asserted:
      Session session = accessMgr.createSession( user, constraints );
      ...
  }
 ```

 Pushing the **locale** attribute into the User's RBAC session the runtime will match that instance data with their stored policy.

 ![Image4](images/CurlyUser.png "View Curly Data")
 *Notice that this user has been assigned both Teller and Washer, via **ftRA** attribute, and that another attribute, **ftRC**, constrains where it can be activated.*

### How the ABAC algorithm works:
 * When the runtime iterates over assigned roles (ftRA), trying to activate them one-by-one, it matches the constraint pushed in, e.g. locale=north, with its associated role constraint (ftRC).
 * If it finds a match, the role can be activated into the session, otherwise not.

### When does it get executed:
 * During the [createSession](https://directory.apache.org/fortress/gen-docs/latest/apidocs/org/apache/directory/fortress/core/AccessMgr.html#createSession-org.apache.directory.fortress.core.model.User-boolean-) call, there's a role activation phase, where all of the constraints are applied.
 * Applying constraints is not a new concept with Fortress, check out, [What Are Temporal Constraints?](https://iamfortress.net/2015/06/11/what-are-temporal-constraints/), for more info.
 * Constraints are enabled via [fortress' configuration subsystem](https://github.com/apache/directory-fortress-core/blob/master/README-CONFIG.md).  Currently ABAC and temporal constraints are turned on by default.

### One more thing:
 * ABAC constraints work with any kind of instance data, e.g. account, organization, etc.  Let your imagination set the boundaries.
