#!/usr/bin/env bash

help="You have to launch script with two parameters: 

      !!!
      This script can run only user with sudo permissions.
      !!!

      Usage: $0 [ OPTIONS ] VALUE

        OPTIONS := { 
              -p  -  password for artifactory admin user. }

        VALUE := Any string values like:  
            -p user_PaSsWord

      Example: sudo $0 -p New_admin_PaSsWord"

checkargs () {
if [[ $OPTARG =~ ^-[p]$ ]]
then
echo "Unknow argument $OPTARG for option $opt!"
exit 1
fi
}

if [ $# -lt 1 ]
 then
    echo "Not enough arguments provided"
exit 1
fi

while getopts "p:h" opt
  do
  case $opt in
    p) checkargs
    NEW_PASSWORD=$OPTARG;;
    h) echo "$help";;
    *) echo "Wrong parameter, please pay attention and call -h for help. "
  esac
done

if [[ "$NEW_PASSWORD" == "" ]]; then
    echo ""
        echo "ERROR: Options -p or -h require arguments." >&2
    exit 1
fi

INITIAL_LOGIN="admin"
INITIAL_PASSWORD="password"

if [ $EUID -eq 0 ]; then
  APP_LIST=(wget java-1.8.0-openjdk  java-1.8.0-openjdk-devel)
        for APP in ${!APP_LIST[*]}
        do
          yum install -y "${APP_LIST[$APP]}"
        done
  JAVA_HOME="$(set -o pipefail ; readlink -f /usr/bin/java | sed 's%/bin/java%%')"
  export JAVA_HOME
  wget https://bintray.com/jfrog/artifactory-rpms/rpm -O /etc/yum.repos.d/bintray-jfrog-artifactory-rpms.repo
  sudo yum install -y jfrog-artifactory-oss
  systemctl start artifactory 
  set -o pipefail  
  systemctl enable artifactory
    while [[ "$(curl -s -o /dev/null -L -w "%{http_code}" -X GET http://localhost:8081/artifactory/api/system/ping )" != "200" ]]; do
      echo "No Connection Yet"
    sleep 10
    done
  curl -u $INITIAL_LOGIN:$INITIAL_PASSWORD -X POST http://localhost:8081/artifactory/api/security/users/authorization/changePassword -H "Content-type: application/json" -d '{"userName" : "'"$INITIAL_LOGIN"'","oldPassword" : "'"$INITIAL_PASSWORD"'","newPassword1" : "'"$NEW_PASSWORD"'","newPassword2" : "'"$NEW_PASSWORD"'"}'
  echo "export JAVA_HOME=$(set -o pipefail ; readlink -f /usr/bin/java | sed 's%/bin/java%%')" | sudo tee -a /etc/profile
  echo "Admin user was modify. Now you can login to http://localhost:8081 with login: 
      username = $INITIAL_LOGIN
      password = $NEW_PASSWORD"

else
        echo "Only sudo/root may run this script"
        exit 2
fi
