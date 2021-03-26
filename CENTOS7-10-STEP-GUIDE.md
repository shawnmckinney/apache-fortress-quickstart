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
git clone https://github.com/shawnmckinney/apache-fortress-quickstart.git /usr/share/fortress
```

7. Load the LDAP Directory with Bootstrap Data:

```bash
cd /usr/share/fortress
cp src/main/resources/fortress.properties.example src/main/resources/fortress.properties
mvn install -Dload.file=./src/main/resources/FortressBootstrap.xml
mvn install -Dload.file=./src/main/resources/FortressRestServerPolicy.xml
```

8. Start Tomcat:

```bash
service tomcat start
```

9. Add SELinux Permissions:

```bash
ausearch -ui tomcat --raw | audit2allow -M my-tomcat
semodule -i my-tomcat.pp
```

10. Restart Tomcat:

```bash
service tomcat restart
```

## Apendix: Troubleshooting

a. selinux problem

i. if there's not a response returning via the curl command it's likely an selinux permission violation.  You can check its log (for tomcat):

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

Here we can see that selinux is blocking the tomcat process from accessing an ldap port, 32768 which happens to be the default port for a directory server when running inside a docker container.  
If you used the default config supplied by the quickstart, the port will be set to 32768.  Any port over 327, which is an ephemeral_port_t.

We can work around this by:

```bash
ausearch -ui tomcat --raw | audit2allow -M my-tomcat
semodule -i my-tomcat.pp
```

 * Where -ui is the user tomcat runs under.
 * Restart tomcat server and try again.

b. tomcat or app issue

If selinux is not the culprit, you'll need to view the tomcat log and see what's going wrong. 

```
journalctl -u tomcat
```

c. Access the container's file system:


```
docker exec -it fortress bash
```

d. more selinux breadcrumbs, notes, etc...

```
type=AVC msg=audit(1616686701.099:3630): avc:  denied  { name_connect } for  pid=10595 comm="localhost-start" dest=32768 scontext=system_u:system_r:tomcat_t:s0 tcontext=system_u:object_r:ephemeral_port_t:s0 tclass=tcp_socket permissive=0
```

ausearch -c 'tomcat' --raw | audit2allow -M my-slapd


TODO: Add this selinux policy rule for tomcat access to ephemeral_port:

```
allow tomcat_t ephemeral_port_t : tcp_socket name_bind 
```

More on ausearch:


```bash
usage: ausearch [options]
        -a,--event <Audit event id>     search based on audit event id
        --arch <CPU>                    search based on the CPU architecture
        -c,--comm  <Comm name>          search based on command line name
        --checkpoint <checkpoint file>  search from last complete event
        --debug                 Write malformed events that are skipped to stderr
        -e,--exit  <Exit code or errno> search based on syscall exit code
        -f,--file  <File name>          search based on file name
        --format [raw|default|interpret|csv|text] results format options
        -ga,--gid-all <all Group id>    search based on All group ids
        -ge,--gid-effective <effective Group id>  search based on Effective
                                        group id
        -gi,--gid <Group Id>            search based on group id
        -h,--help                       help
        -hn,--host <Host Name>          search based on remote host name
        -i,--interpret                  Interpret results to be human readable
        -if,--input <Input File name>   use this file instead of current logs
        --input-logs                    Use the logs even if stdin is a pipe
        --just-one                      Emit just one event
        -k,--key  <key string>          search based on key field
        -l, --line-buffered             Flush output on every line
        -m,--message  <Message type>    search based on message type
        -n,--node  <Node name>          search based on machine's name
        -o,--object  <SE Linux Object context> search based on context of object
        -p,--pid  <Process id>          search based on process id
        -pp,--ppid <Parent Process id>  search based on parent process id
        -r,--raw                        output is completely unformatted
        -sc,--syscall <SysCall name>    search based on syscall name or number
        -se,--context <SE Linux context> search based on either subject or
                                         object
        --session <login session id>    search based on login session id
        -su,--subject <SE Linux context> search based on context of the Subject
        -sv,--success <Success Value>   search based on syscall or event
                                        success value
        -te,--end [end date] [end time] ending date & time for search
        -ts,--start [start date] [start time]   starting data & time for search
        -tm,--terminal <TerMinal>       search based on terminal
        -ua,--uid-all <all User id>     search based on All user id's
        -ue,--uid-effective <effective User id>  search based on Effective
                                        user id
        -ui,--uid <User Id>             search based on user id
        -ul,--loginuid <login id>       search based on the User's Login id
        -uu,--uuid <guest UUID>         search for events related to the virtual
                                        machine with the given UUID.
        -v,--version                    version
        -vm,--vm-name <guest name>      search for events related to the virtual
                                        machine with the name.
        -w,--word                       string matches are whole word
        -x,--executable <executable name>  search based on executable name
```

