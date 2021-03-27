FROM tomcat:9.0-alpine
LABEL maintainer=iamfortress.net
ADD https://repo.maven.apache.org/maven2/org/apache/directory/fortress/fortress-rest/2.0.5/fortress-rest-2.0.5.war /usr/local/tomcat/webapps/
ADD https://repo.maven.apache.org/maven2/org/apache/directory/fortress/fortress-realm-proxy/2.0.5/fortress-realm-proxy-2.0.5.jar /usr/local/tomcat/lib/
ENV JAVA_OPTS="-Dfortress.host=openldap-fortress -Dfortress.port=389 -Dfortress.admin.user=cn=manager,dc=example,dc=com -Dfortress.admin.pw=secret -Dfortress.min.admin.conn=1 -Dfortress.max.admin.conn=10 -Dfortress.ldap.server.type=openldap -Dfortress.enable.ldap.ssl=false -Dfortress.config.realm=DEFAULT -Dfortress.config.root=ou=config,dc=example,dc=com"
EXPOSE 8080
