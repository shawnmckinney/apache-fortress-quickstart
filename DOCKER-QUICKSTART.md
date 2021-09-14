# Overview of the docker-quickstart

* Shows how to install Apache Fortress Rest component onto a Debian or Centos machine.
* Both OpenLDAP 2.5 and Apache Tomcat processes run inside Docker containers connected via a bridge network.  
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

4. Pull Symas OpenLDAP 2.5 container and run inside a bridged network:

```bash
docker network create --driver bridge fortress-net
docker pull shawnmckinney/iamfortress:symas-openldap
docker run  --name=openldap-fortress --network fortress-net -d -p 32768:389 -P shawnmckinney/iamfortress:symas-openldap
```

5. Load the LDAP Directory with Bootstrap Data:

```bash
cp /tmp/fortress/src/main/resources/fortress.properties.example /tmp/fortress/src/main/resources/fortress.properties
mvn -f /tmp/fortress/pom.xml install -Dload.file=src/main/resources/FortressBootstrap.xml
mvn -f /tmp/fortress/pom.xml install -Dload.file=src/main/resources/FortressRestServerPolicy.xml
```

6. Pull tomcat-fortress container and run inside a bridged network:

```bash
docker pull shawnmckinney/iamfortress:tomcat-fortress
docker run --name=tomcat-fortress --network fortress-net -d -p 8080:8080 shawnmckinney/iamfortress:tomcat-fortress
```

7. Test Apache Fortress REST Services:

a. Invoke with curl:

```bash
curl -X POST -u 'adminuser' -H 'Content-type: text/xml' -k -d @/tmp/fortress/src/test/resources/test-add-role-bankuser.xml http://localhost:8080/fortress-rest-2.0.6/roleAdd
curl -X POST -u 'adminuser' -H 'Content-type: text/xml' -k -d @/tmp/fortress/src/test/resources/test-search-role.xml http://localhost:8080/fortress-rest-2.0.6/roleSearch
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

View the logs:

```bash
docker logs openldap-fortress
docker logs tomcat-fortress
```

View the bridged network info:

```bash
docker network ls
docker network inspect fortress-net
```
