# Overview of the apache-fortress-quickstart for Docker on Linux

* Shows how to install Apache Fortress Rest component onto a Debian or Centos machine.
* Both OpenLDAP and Apache Tomcat processes run inside separate Docker containers that are connected via a bridge network.  
* Once system is setup, test services using curl, find out how here: [README-TESTING](README-TESTING.md)

## Tutorial Prereqs

* Linux machine
* 1 CPU/1GB RAM

1. Install required packages 

a. Debian

```bash
apt-get update
apt-get install wget git default-jdk maven apt-transport-https ca-certificates curl gnupg2 software-properties-common -y
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt update
apt-cache policy docker-ce
apt install docker-ce -y
```

or 

b. RHEL7/Centos7

```bash
yum install wget git java maven docker -y
```

or

c. RHEL8/Centos8

```bash
yum install -y yum-utils wget git java maven -y 
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io -y
```

2. Enable and start Docker:

```bash
systemctl enable docker
systemctl start docker
```

3. Clone Fortress Quickstart

```bash
git clone https://github.com/shawnmckinney/apache-fortress-quickstart.git /tmp/fortress
```

4. Pull LDAP container and start inside bridged network:

a. OpenLDAP 2.4

```bash
docker network create --driver bridge fortress-net
docker pull apachedirectory/openldap-for-apache-fortress-tests
docker run --name=openldap-fortress --network fortress-net -d -p 32768:389 -P apachedirectory/openldap-for-apache-fortress-tests
```

or

b. OpenLDAP 2.5 Beta

```bash
docker network create --driver bridge fortress-net
docker pull shawnmckinney/iamfortress:openldap-for-linux
docker run  --name=openldap-fortress --network fortress-net -d -p 32768:389 -P shawnmckinney/iamfortress:openldap-for-linux
```

5. Load the LDAP Directory with Bootstrap Data:

```bash
cp /tmp/fortress/src/main/resources/fortress.properties.example /tmp/fortress/src/main/resources/fortress.properties
mvn -f /tmp/fortress/pom.xml install -Dload.file=src/main/resources/FortressBootstrap.xml
mvn -f /tmp/fortress/pom.xml install -Dload.file=src/main/resources/FortressRestServerPolicy.xml
```

6. Build and run tomcat-fortress Dockerfile on target:

```bash
cd /tmp/fortress
docker build -t tomcat-fortress -f Dockerfile .
docker run --name=tomcat-fortress --network fortress-net -d -p 8080:8080 tomcat-fortress
```

7. Test Services:

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

### Access the container's file system

Connect to running containers via bash:

```
docker exec -it openldap-fortress bash
docker exec -it tomcat-fortress bash
```

### More Helpful Docker commands:

View the bridged network info:

```bash
docker network ls
docker network inspect fortress-net
```
