# Overview of the apache-fortress-quickstart CENTOS7 10 STEP GUIDE

* Shows how to install Apache Fortress Rest component and all of its dependencies onto a Centos7 machine.
* Once system is setup, test services using curl, find out how here: [README-TESTING](README-TESTING.md)

## Tutorial Prereqs

* Centos7
* 1 CPU/1GB RAM

1. Install required packages

```bash
yum install wget git java maven tomcat docker -y
```

2. Enable and Start Required Services

```bash
systemctl enable tomcat
systemctl enable docker
systemctl start docker
```

3. Pull LDAP container and start it:

```bash
docker pull apachedirectory/openldap-for-apache-fortress-tests
docker run --name=openldap-fortress -d  -p 32768:389 -P apachedirectory/openldap-for-apache-fortress-tests
```

4. Get the Fortress artifacts

```bash
wget https://repo.maven.apache.org/maven2/org/apache/directory/fortress/fortress-realm-proxy/2.0.5/fortress-realm-proxy-2.0.5.jar -P /usr/share/tomcat/lib
wget https://repo.maven.apache.org/maven2/org/apache/directory/fortress/fortress-rest/2.0.5/fortress-rest-2.0.5.war -P /usr/share/tomcat/webapps
```

5. Enable Fortress in Tomcat

```bash
echo "JAVA_OPTS=\"-Dfortress.host=localhost -Dfortress.port=32768 -Dfortress.admin.user=cn=manager,dc=example,dc=com -Dfortress.admin.pw=secret -Dfortress.min.admin.conn=1 -Dfortress.max.admin.conn=10 \
-Dfortress.ldap.server.type=openldap -Dfortress.enable.ldap.ssl=false -Dfortress.config.realm=DEFAULT -Dfortress.config.root=ou=config,dc=example,dc=com\"" >> /etc/sysconfig/tomcat
```

6. Clone Fortress Quickstart:

```bash
git clone https://github.com/shawnmckinney/apache-fortress-quickstart.git /tmp/fortress
```

7. Load the LDAP Directory with Bootstrap Data:

```bash
cp /tmp/fortress/src/main/resources/fortress.properties.example /tmp/fortress/src/main/resources/fortress.properties
mvn -f /tmp/fortress/pom.xml install -Dload.file=src/main/resources/FortressBootstrap.xml
mvn -f /tmp/fortress/pom.xml install -Dload.file=src/main/resources/FortressRestServerPolicy.xml
```

8. Add Tomcat SELinux Policy, allow access to LDAP:

```bash
echo -e "module ft-tomcat 1.0;\n\
require {\n\
    type ephemeral_port_t;\n\
    type tomcat_t;\n\
    class tcp_socket name_connect;\n\
}\n\
allow tomcat_t ephemeral_port_t:tcp_socket name_connect;" >> /tmp/fortress/ft-tomcat.te
checkmodule -M -m -o /tmp/fortress/ft-tomcat.mod /tmp/fortress/ft-tomcat.te
semodule_package -o /tmp/fortress/ft-tomcat.pp -m /tmp/fortress/ft-tomcat.mod
semodule -i /tmp/fortress/ft-tomcat.pp
```

9. Start Tomcat:

```bash
service tomcat start
```
10. Test Services:

a. Invoke with curl:

```bash
curl -X POST -u 'adminuser' -H 'Content-type: text/xml' -k -d @/tmp/fortress/src/test/resources/test-add-role-bankuser.xml http://localhost:8080/fortress-rest-2.0.5/roleAdd
curl -X POST -u 'adminuser' -H 'Content-type: text/xml' -k -d @/tmp/fortress/src/test/resources/test-search-role.xml http://localhost:8080/fortress-rest-2.0.5/roleSearch
```

b. enter password ="$3cret" at the prompt:

```bash
Enter host password for user 'adminuser':
```

c. More examples here: [README-TESTING](README-TESTING.md)

## Appendix: Troubleshooting

### SELinux

if there's not a response returning via the curl command it could be an SELinux permission violation.
A policy was created and loaded during setup.

i. You can check its log (for tomcat):

```bash
ausearch -ui tomcat
```

Which searches by the user the process is running under, in this case 'tomcat'.  If there are problems found, it will look like:

```bash
time->Thu Mar 25 17:50:29 2021
type=PROCTITLE msg=audit(1616694629.518:14124): proctitle=2F7573722F6C69622F6A766D2F6A72652F62696E2F6A617661002D44666F7274726573732E686F73743D6C6F63616C686F7374002D44666F7274726573732E706F72743D3332373638002D44666F7274726573
732E61646D696E2E757365723D636E3D6D616E616765722C64633D6578616D706C652C64633D636F6D002D4466
type=SYSCALL msg=audit(1616694629.518:14124): arch=c000003e syscall=42 success=no exit=-13 a0=85 a1=7f24e87615a0 a2=1c a3=24 items=0 ppid=1 pid=27794 auid=4294967295 uid=53 gid=53 euid=53 suid=53 fsuid=53 egid=53 sgid=53 fsg
id=53 tty=(none) ses=4294967295 comm="localhost-start" exe="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.282.b08-1.el7_9.x86_64/jre/bin/java" subj=system_u:system_r:tomcat_t:s0 key=(null)
type=AVC msg=audit(1616694629.518:14124): avc:  denied  { name_connect } for  pid=27794 comm="localhost-start" dest=32768 scontext=system_u:system_r:tomcat_t:s0 tcontext=system_u:object_r:ephemeral_port_t:s0 tclass=tcp_socke
t permissive=0
```

#### Discussion

Here we can see that SELinux is blocking the Tomcat process from accessing an ldap port, 32768 which happens to be the default port for a directory server when running inside a docker container.  
If you used the default config supplied by the quickstart, the port will be set to 32768.

We applied an SELinux policy to Tomcat to access LDAP in the setup so this 'shouldn't' happen.  But, if does you can work around it by performing the next step and then opening an issue on this project so we can update the policy.

```bash
ausearch -ui tomcat --raw | audit2allow -M my-tomcat
semodule -i my-tomcat.pp
```
 * Where -ui is the user tomcat runs under.
 * Restart tomcat server and try again 

### Tomcat or app issue

If selinux is not the culprit, you'll need to view the tomcat log and see what's going wrong. 

```
journalctl -u tomcat
```

### Access the container's file system:

```
docker exec -it fortress bash
```
