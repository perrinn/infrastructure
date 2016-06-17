# System-wide configuration file for tomcat services
# This will be sourced by tomcat and any secondary service
# Values will be overridden by service-specific configuration
# files in /etc/sysconfig
#
# Use this one to change default values for all services
# Change the service specific ones to affect only one service
# (see, for instance, /etc/sysconfig/tomcat7)
#

# Where your java installation lives
JAVA_HOME="/usr/lib/jvm/jre"

# Where your tomcat installation lives
CATALINA_BASE="/usr/share/tomcat8"
CATALINA_HOME="/usr/share/tomcat8"
JASPER_HOME="/usr/share/tomcat8"
CATALINA_TMPDIR="/var/cache/tomcat8/temp"

# You can pass some parameters to java here if you wish to
#JAVA_OPTS="-Xminf0.1 -Xmaxf0.3"

# Use JAVA_OPTS to set java.library.path for libtcnative.so
#JAVA_OPTS="-Djava.library.path=/usr/lib"

# What user should run tomcat
TOMCAT_USER="tomcat"

# You can change your tomcat locale here
#LANG="en_US"

# Run tomcat under the Java Security Manager
SECURITY_MANAGER="false"

# Maximum time to wait in seconds, before killing process
SHUTDOWN_WAIT="30"

# Maximum time to wait in seconds, after killing the tomcat process
KILL_SLEEP_WAIT="5" 

# Whether to annoy the user with "attempting to shut down" messages or not
SHUTDOWN_VERBOSE="false"

# Set the TOMCAT_PID location
CATALINA_PID="/var/run/tomcat8.pid"

# Connector port is 8080 for this tomcat instance
#CONNECTOR_PORT="8080"

# If you wish to further customize your tomcat environment,
# put your own definitions here
# (i.e. LD_LIBRARY_PATH for some jdbc drivers)

JAVA_OPTS="-server {{MEMOPT}} -javaagent:/usr/share/tomcat8/newrelic/newrelic.jar"
