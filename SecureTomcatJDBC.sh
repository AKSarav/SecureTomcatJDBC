#!/bin/bash
# Author: SaravAK (aksarav@middlewareinventory.com)
#
#

BASE_DIR=`dirname $0`
LOGFILE=$BASE_DIR/SecureTomDB-Exec.log
INFOFILE=$BASE_DIR/TomcatInfo.properties
JAVA_ENC_FILE=EncDecJDBCPass.java
BAK_JAVA_ENC_FILE=EncryptJDBCPassword.java-Original
CLASS_ENC_FILE=EncDecJDBCPass.class
JAVA_DS_FILE=SecureTomcatDataSourceImpl.java
CLASS_DS_FILE=SecureTomcatDataSourceImpl.class
rm -f $INFOFILE
rm -f $BASEDIR/*.class

echo "Enter the Tomcat Instance CATALINA_HOME ( A Parent Directory of conf/ bin/ webapps/ )"
read InstanceDir

if [ -e $InstanceDir ]
then
	if [ -e $InstanceDir/bin/version.sh -a  -x $InstanceDir/bin/version.sh ]
	then
		$InstanceDir/bin/version.sh > $INFOFILE
	
	else
		echo "ERROR: Unable to find the Version.sh under $InstanceDir/bin [OR] Execute Permission is Not Set"
		exit 9
	fi
fi

cd $BASE_DIR
echo -e "\n"

if [ -e $INFOFILE -a ! -z $INFOFILE ]
then
grep -i "Server Version" $INFOFILE
grep -i "JVM Version" $INFOFILE
egrep -i "JAVA|JRE" $INFOFILE 
grep -i "CATALINA_HOME" $INFOFILE
grep -i "CLASSPATH" $INFOFILE
fi

JAVA_HOME=`egrep -i "JAVA|JRE" $INFOFILE|awk '{print $3}'`

if [ -e $JAVA_HOME/bin/javac -a -e $JAVA_HOME/bin/java -a -e $JAVA_HOME/bin/jar ]
then
	echo "INFO: Java Home Validation Successful. Good to Go"
else
	echo "ERROR: Java Home Does not seem to be having either JAVAC or JAVA or JAR command."
	echo -e "\n Trying to Obtain JAVA_HOME during runtime"
	echo "Enter the JAVA_HOME:"
	read JAVA_HOME_IN
	if [ -e $JAVA_HOME_IN/bin/javac -a -e $JAVA_HOME_IN/bin/java -a -e $JAVA_HOME_IN/bin/jar ]
	then
		echo "INFO: Java Home Validation Successful - RUNTIME. Good to Go"
	else
		echo "I am Sorry the Given JAVA_HOME does not seem to having JAVAC or JAVA or JAR command either"
		echo "If you feel there is a BUG. Please write email to my author aksarav@middlewareinventory.com"
	fi
fi
JULI_JAR_LOC=$InstanceDir/bin/tomcat-juli.jar
JDBC_JAR_LOC=$InstanceDir/lib/tomcat-jdbc.jar
echo -e "\n"
echo "INFO: Vaidating the Tomcat Juli and Tomcat JDBC Jar files availability"

if [ -e $InstanceDir/bin/tomcat-juli.jar -a -e $InstanceDir/lib/tomcat-jdbc.jar ]
then
	echo "INFO: Jar files are present. Good to Go"
else
	echo "ERROR: Unable to find the Jar files $InstanceDir/bin/tomcat-juli.jar and $InstanceDir/bin/tomcat-jdbc.jar"
	exit 10
fi

echo "Enter the Password to Encrypt"
read -s passwordtoencrypt

echo "Enter the Secret PassPhrase"
read -s secretphrase

cp $JAVA_ENC_FILE $BAK_JAVA_ENC_FILE
if [ $? -ne 0 ]
then
    echo "ERROR: failed to take backup of $JAVA_ENC_FILE"
fi

if [ $secretphrase != "" -o $passwordtoencrypt != "" ]
then

	sed -e "s/PHRASETOREPLACE/$secretphrase/" EncDecJDBCPass.java > EncDecJDBCPass_temp.java && mv EncDecJDBCPass_temp.java EncDecJDBCPass.java

else

	echo "ERROR: Either PassPhrase or the Password is Empty"

fi

echo "Creating the JAR module and Compiling the code"

$JAVA_HOME/bin/javac -cp $InstanceDir/lib/tomcat-jdbc.jar:$InstanceDir/bin/tomcat-juli.jar:. $JAVA_ENC_FILE && $JAVA_HOME/bin/javac -cp $InstanceDir/lib/tomcat-jdbc.jar:$InstanceDir/bin/tomcat-juli.jar:. $JAVA_DS_FILE

if [ $? -eq 0 ]
then
	if [ ! -e $CLASS_ENC_FILE -o ! -e $CLASS_DS_FILE ]
	then
		echo "ERROR: Classfiles are not Created. Please check manually"
	else
		echo "Class files are created. Good to Go"
	fi
else
	echo "Class Compilation Errors Found. Please check manually"
	exit 11
fi

echo "INFO: Creating a Jar file SecureTomcatJDBC.jar"
$JAVA_HOME/bin/jar -cvfM SecureTomcatJDBC.jar *.class META-INF

if [ $? -ne 0 -o ! -e SecureTomcatJDBC.jar ]
then
   echo "ERROR: Jar Creation Failed"
else
   echo "INFO: Jar file Creation Successful. Good to Go"
fi

echo -e "\nPassword Encryption Begins"
if [ `$JAVA_HOME/bin/java -jar SecureTomcatJDBC.jar|grep -i "^USAGE"|wc -l` -eq 1 ]
then
	$JAVA_HOME/bin/java -jar SecureTomcatJDBC.jar $passwordtoencrypt
else
	echo -e "ERROR: Unable to Encrypt the Password. Sorry. Please report this problem to my Creator at aksarav@middlewareinventory.com"
fi
echo -e "Password Encryption Completed. Your Encrypted Password is displayed above"

cp $BAK_JAVA_ENC_FILE $JAVA_ENC_FILE
rm -f $BAK_JAVA_ENC_FILE
rm -rf $BASE_DIR/*.class

echo -e "\nNext Steps:\n 1) Copy the Generated SecureTomcatJDBC.jar into the $InstanceDir/lib directory\n 2) Replace the Factory element in Context.xml with factory=\"SecureTomcatDataSourceImpl\"\n 3) Replace the Encrypted Password in place of Clear Text Password password=\"ENCRYPTED PASSWORD\""

echo -e "For Any Questions about this tool read the product page https://www.middlewareinventory.com/blog/secure-tomcat-jdbc/. Leave a Comment there for any help"

echo -e "\nGood Bye. Thanks for using SecureTomcatJDBC Application"


