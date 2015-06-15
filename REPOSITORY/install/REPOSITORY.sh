#/* ================================================  
# *    
# * Copyright (c) 2015 Oracle and/or its affiliates.  All rights reserved.
# *
# * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# *
# * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# *
# * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# *
# * ================================================ 
# */
demohome="$(dirname "$(pwd)")"
logfilename=$demohome/install/REPOSITORY.log
echo "Log File : $logfilename"
rm $logfilename
DBA=$1
DBAPWD=$2
USER=$3
USERPWD=$4
SERVER=$5
echo "Installation Parameters for An Introduction to the Oracle XML DB Repository". > $logfilename
echo "\$DBA         : $DBA" >> $logfilename
echo "\$USER        : $USER" >> $logfilename
echo "\$SERVER      : $SERVER" >> $logfilename
echo "\$DEMOHOME    : $demohome" >> $logfilename
echo "\$ORACLE_HOME : $ORACLE_HOME" >> $logfilename
echo "\$ORACLE_SID  : $ORACLE_SID" >> $logfilename
spexe=$(which sqlplus | head -1)
echo "sqlplus      : $spexe" >> $logfilename
sqlplus -L $DBA/$DBAPWD@$ORACLE_SID @$demohome/install/sql/verifyConnection.sql
rc=$?
echo "sqlplus $DBA:$rc" >> $logfilename
if [ $rc != 2 ] 
then 
  echo "Operation Failed : Unable to connect via SQLPLUS as $DBA - Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 2
fi
sqlplus -L $USER/$USERPWD@$ORACLE_SID @$demohome/install/sql/verifyConnection.sql
rc=$?
echo "sqlplus $USER:$rc" >> $logfilename
if [ $rc != 2 ] 
then 
  echo "Operation Failed : Unable to connect via SQLPLUS as $USER - Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 3
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X GET --write-out "%{http_code}\n" -s --output /dev/null $SERVER/xdbconfig.xml | head -1)
echo "GET:$SERVER/xdbconfig.xml:$HttpStatus" >> $logfilename
if [ $HttpStatus != "200" ] 
then
  if [ $HttpStatus == "401" ] 
    then
      echo "Unable to establish HTTP connection as '$DBA'. Please note username is case sensitive with Digest Authentication">> $logfilename
      echo "Unable to establish HTTP connection as '$DBA'. Please note username is case sensitive with Digest Authentication"
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    else
      echo "Operation Failed- Installation Aborted." >> $logfilename
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  fi
  exit 4
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X GET --write-out "%{http_code}\n" -s --output /dev/null $SERVER/public | head -1)
echo "GET:$SERVER/public:$HttpStatus" >> $logfilename
if [ $HttpStatus != "200" ] 
then
  if [ $HttpStatus == "401" ] 
    then
      echo "Unable to establish HTTP connection as '$USER'. Please note username is case sensitive with Digest Authentication">> $logfilename
      echo "Unable to establish HTTP connection as '$USER'. Please note username is case sensitive with Digest Authentication"
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    else
      echo "Operation Failed- Installation Aborted." >> $logfilename
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  fi
  exit 4
fi
mkdir -p $demohome/$USER
mkdir -p $demohome/$USER/WebDAV
mkdir -p $demohome/$USER/WebDAV/ImageLibrary
mkdir -p $demohome/$USER/WebDAV/ImageCategories
mkdir -p $demohome/$USER/SampleData
mkdir -p $demohome/$USER/sql
echo "Unzipping \"$demohome/Setup/ImageLibrary.zip\" into \"$demohome/$USER/SampleData\""
unzip -o -qq "$demohome/Setup/ImageLibrary.zip" -d "$demohome/$USER/SampleData"
echo "Unzip Completed"
echo "Cloning \"$demohome/Setup/sql\" into \"$demohome/$USER/sql\""
cp -r "$demohome/Setup/sql"/* "$demohome/$USER/sql"
find "$demohome/$USER/sql" -type f -print0 | xargs -0 sed -e "s|%DESKTOP%|C:\Users\Mark D Drake\Desktop|g" -e "s|%STARTMENU%|C:\Users\Mark D Drake\AppData\Roaming\Microsoft\Windows\Start Menu|g" -e "s|%WINWORD%|C:\PROGRA~2\MICROS~2\Office12\WINWORD.EXE|g" -e "s|%EXCEL%|C:\PROGRA~2\MICROS~2\Office12\EXCEL.EXE|g" -e "s|%DEMODIRECTORY%|$demohome|g" -e "s|%DEMOFOLDERNAME%|REPOSITORY|g" -e "s|%DEMONAME%|An Introduction to the Oracle XML DB Repository|g" -e "s|%LAUNCHPAD%|Repository Features|g" -e "s|%LAUNCHPADFOLDER%|C:\Users\Mark D Drake\AppData\Roaming\Microsoft\Windows\Start Menu\Oracle XML DB Demonstrations|g" -e "s|%SHORTCUTFOLDER%|$demohome\/$USER|g" -e "s|%PUBLICFOLDER%|\/publishedContent|g" -e "s|%DEMOCOMMON%|\/publishedContent\/demonstrations\/repository|g" -e "s|%HOMEFOLDER%|\/home\/%USER%|g" -e "s|%DEMOLOCAL%|\/home\/%USER%\/demonstrations\/repository|g" -e "s|%XFILES_SCHEMA%|XFILES|g" -e "s|%XFILES_ROOT%|XFILES|g" -e "s|%SCHEMAURL%|http:\/\/xmlns.oracle.com\/demo\/imageMetadata.xsd|g" -e "s|%XFILESAPP%|\/XFILES\/Applications\/imageMetadata|g" -e "s|%METADATA_OWNER%|XDBEXT|g" -e "s|protocol|HTTP|g" -e "s|enableHTTPTrace|false|g" -e "s|%ORACLEHOME%|$ORACLE_HOME|g" -e "s|%DBA%|$DBA|g" -e "s|%DBAPASSWORD%|$DBAPWD|g" -e "s|%USER%|$USER|g" -e "s|%PASSWORD%|$USERPWD|g" -e "s|%TNSALIAS%|$ORACLE_SID|g" -e "s|%HOSTNAME%|$HOSTNAME|g" -e "s|%HTTPPORT%|$HTTP|g" -e "s|%FTPPORT%|$FTP|g" -e "s|%DRIVELETTER%||g" -e "s|%SERVERURL%|$SERVER|g" -e "s|%DBCONNECTION%|$USER\/$USERPWD@$ORACLE_SID|g" -e "s|%SQLPLUS%|sqlplus|g" -e "s|\$USER|$USER|g" -e "s|\$SERVER|$SERVER|g" -i
echo "Cloning Completed"
cp "$demohome/Setup/XML Spy Project.spp" "$demohome/$USER/1.1 Show XML Schema (XMLSPY).spp"
sed -e "s|%DESKTOP%|C:\Users\Mark D Drake\Desktop|g" -e "s|%STARTMENU%|C:\Users\Mark D Drake\AppData\Roaming\Microsoft\Windows\Start Menu|g" -e "s|%WINWORD%|C:\PROGRA~2\MICROS~2\Office12\WINWORD.EXE|g" -e "s|%EXCEL%|C:\PROGRA~2\MICROS~2\Office12\EXCEL.EXE|g" -e "s|%DEMODIRECTORY%|$demohome|g" -e "s|%DEMOFOLDERNAME%|REPOSITORY|g" -e "s|%DEMONAME%|An Introduction to the Oracle XML DB Repository|g" -e "s|%LAUNCHPAD%|Repository Features|g" -e "s|%LAUNCHPADFOLDER%|C:\Users\Mark D Drake\AppData\Roaming\Microsoft\Windows\Start Menu\Oracle XML DB Demonstrations|g" -e "s|%SHORTCUTFOLDER%|$demohome\/$USER|g" -e "s|%PUBLICFOLDER%|\/publishedContent|g" -e "s|%DEMOCOMMON%|\/publishedContent\/demonstrations\/repository|g" -e "s|%HOMEFOLDER%|\/home\/%USER%|g" -e "s|%DEMOLOCAL%|\/home\/%USER%\/demonstrations\/repository|g" -e "s|%XFILES_SCHEMA%|XFILES|g" -e "s|%XFILES_ROOT%|XFILES|g" -e "s|%SCHEMAURL%|http:\/\/xmlns.oracle.com\/demo\/imageMetadata.xsd|g" -e "s|%XFILESAPP%|\/XFILES\/Applications\/imageMetadata|g" -e "s|%METADATA_OWNER%|XDBEXT|g" -e "s|protocol|HTTP|g" -e "s|enableHTTPTrace|false|g" -e "s|%ORACLEHOME%|$ORACLE_HOME|g" -e "s|%DBA%|$DBA|g" -e "s|%DBAPASSWORD%|$DBAPWD|g" -e "s|%USER%|$USER|g" -e "s|%PASSWORD%|$USERPWD|g" -e "s|%TNSALIAS%|$ORACLE_SID|g" -e "s|%HOSTNAME%|$HOSTNAME|g" -e "s|%HTTPPORT%|$HTTP|g" -e "s|%FTPPORT%|$FTP|g" -e "s|%DRIVELETTER%||g" -e "s|%SERVERURL%|$SERVER|g" -e "s|%DBCONNECTION%|$USER\/$USERPWD@$ORACLE_SID|g" -e "s|%SQLPLUS%|sqlplus|g" -e "s|\$USER|$USER|g" -e "s|\$SERVER|$SERVER|g" -i "$demohome/$USER/1.1 Show XML Schema (XMLSPY).spp"
cp "$demohome/Setup/sqlldr/ImageList.dat" "$demohome/$USER/SampleData/ImageList.dat"
sed -e "s|%DESKTOP%|C:\Users\Mark D Drake\Desktop|g" -e "s|%STARTMENU%|C:\Users\Mark D Drake\AppData\Roaming\Microsoft\Windows\Start Menu|g" -e "s|%WINWORD%|C:\PROGRA~2\MICROS~2\Office12\WINWORD.EXE|g" -e "s|%EXCEL%|C:\PROGRA~2\MICROS~2\Office12\EXCEL.EXE|g" -e "s|%DEMODIRECTORY%|$demohome|g" -e "s|%DEMOFOLDERNAME%|REPOSITORY|g" -e "s|%DEMONAME%|An Introduction to the Oracle XML DB Repository|g" -e "s|%LAUNCHPAD%|Repository Features|g" -e "s|%LAUNCHPADFOLDER%|C:\Users\Mark D Drake\AppData\Roaming\Microsoft\Windows\Start Menu\Oracle XML DB Demonstrations|g" -e "s|%SHORTCUTFOLDER%|$demohome\/$USER|g" -e "s|%PUBLICFOLDER%|\/publishedContent|g" -e "s|%DEMOCOMMON%|\/publishedContent\/demonstrations\/repository|g" -e "s|%HOMEFOLDER%|\/home\/%USER%|g" -e "s|%DEMOLOCAL%|\/home\/%USER%\/demonstrations\/repository|g" -e "s|%XFILES_SCHEMA%|XFILES|g" -e "s|%XFILES_ROOT%|XFILES|g" -e "s|%SCHEMAURL%|http:\/\/xmlns.oracle.com\/demo\/imageMetadata.xsd|g" -e "s|%XFILESAPP%|\/XFILES\/Applications\/imageMetadata|g" -e "s|%METADATA_OWNER%|XDBEXT|g" -e "s|protocol|HTTP|g" -e "s|enableHTTPTrace|false|g" -e "s|%ORACLEHOME%|$ORACLE_HOME|g" -e "s|%DBA%|$DBA|g" -e "s|%DBAPASSWORD%|$DBAPWD|g" -e "s|%USER%|$USER|g" -e "s|%PASSWORD%|$USERPWD|g" -e "s|%TNSALIAS%|$ORACLE_SID|g" -e "s|%HOSTNAME%|$HOSTNAME|g" -e "s|%HTTPPORT%|$HTTP|g" -e "s|%FTPPORT%|$FTP|g" -e "s|%DRIVELETTER%||g" -e "s|%SERVERURL%|$SERVER|g" -e "s|%DBCONNECTION%|$USER\/$USERPWD@$ORACLE_SID|g" -e "s|%SQLPLUS%|sqlplus|g" -e "s|\$USER|$USER|g" -e "s|\$SERVER|$SERVER|g" -i "$demohome/$USER/SampleData/ImageList.dat"
cp "$demohome/Setup/sqlldr/ImageLoad.ctl" "$demohome/$USER/SampleData/ImageLoad.ctl"
sed -e "s|%DESKTOP%|C:\Users\Mark D Drake\Desktop|g" -e "s|%STARTMENU%|C:\Users\Mark D Drake\AppData\Roaming\Microsoft\Windows\Start Menu|g" -e "s|%WINWORD%|C:\PROGRA~2\MICROS~2\Office12\WINWORD.EXE|g" -e "s|%EXCEL%|C:\PROGRA~2\MICROS~2\Office12\EXCEL.EXE|g" -e "s|%DEMODIRECTORY%|$demohome|g" -e "s|%DEMOFOLDERNAME%|REPOSITORY|g" -e "s|%DEMONAME%|An Introduction to the Oracle XML DB Repository|g" -e "s|%LAUNCHPAD%|Repository Features|g" -e "s|%LAUNCHPADFOLDER%|C:\Users\Mark D Drake\AppData\Roaming\Microsoft\Windows\Start Menu\Oracle XML DB Demonstrations|g" -e "s|%SHORTCUTFOLDER%|$demohome\/$USER|g" -e "s|%PUBLICFOLDER%|\/publishedContent|g" -e "s|%DEMOCOMMON%|\/publishedContent\/demonstrations\/repository|g" -e "s|%HOMEFOLDER%|\/home\/%USER%|g" -e "s|%DEMOLOCAL%|\/home\/%USER%\/demonstrations\/repository|g" -e "s|%XFILES_SCHEMA%|XFILES|g" -e "s|%XFILES_ROOT%|XFILES|g" -e "s|%SCHEMAURL%|http:\/\/xmlns.oracle.com\/demo\/imageMetadata.xsd|g" -e "s|%XFILESAPP%|\/XFILES\/Applications\/imageMetadata|g" -e "s|%METADATA_OWNER%|XDBEXT|g" -e "s|protocol|HTTP|g" -e "s|enableHTTPTrace|false|g" -e "s|%ORACLEHOME%|$ORACLE_HOME|g" -e "s|%DBA%|$DBA|g" -e "s|%DBAPASSWORD%|$DBAPWD|g" -e "s|%USER%|$USER|g" -e "s|%PASSWORD%|$USERPWD|g" -e "s|%TNSALIAS%|$ORACLE_SID|g" -e "s|%HOSTNAME%|$HOSTNAME|g" -e "s|%HTTPPORT%|$HTTP|g" -e "s|%FTPPORT%|$FTP|g" -e "s|%DRIVELETTER%||g" -e "s|%SERVERURL%|$SERVER|g" -e "s|%DBCONNECTION%|$USER\/$USERPWD@$ORACLE_SID|g" -e "s|%SQLPLUS%|sqlplus|g" -e "s|\$USER|$USER|g" -e "s|\$SERVER|$SERVER|g" -i "$demohome/$USER/SampleData/ImageLoad.ctl"
sqlplus $DBA/$DBAPWD@$ORACLE_SID @$demohome/install/sql/grantPermissions.sql $USER
sqlplus $USER/$USERPWD@$ORACLE_SID @$demohome/install/sql/createHomeFolder.sql
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X DELETE --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository" | head -1)
echo "DELETE "$SERVER/publishedContent/demonstrations/repository":$HttpStatus" >> $logfilename
if [ $HttpStatus != "200" ] && [ $HttpStatus != "204" ] && [ $HttpStatus != "404" ] 
then
  echo "Operation Failed: Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 6
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X DELETE --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository" | head -1)
echo "DELETE "$SERVER/home/$USER/demonstrations/repository":$HttpStatus" >> $logfilename
if [ $HttpStatus != "200" ] && [ $HttpStatus != "204" ] && [ $HttpStatus != "404" ] 
then
  echo "Operation Failed: Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 6
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent" | head -1)
  echo "MKCOL "$SERVER/publishedContent":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations" | head -1)
  echo "MKCOL "$SERVER/publishedContent/demonstrations":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository" | head -1)
  echo "MKCOL "$SERVER/publishedContent/demonstrations/repository":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent" | head -1)
  echo "MKCOL "$SERVER/publishedContent":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations" | head -1)
  echo "MKCOL "$SERVER/publishedContent/demonstrations":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository" | head -1)
  echo "MKCOL "$SERVER/publishedContent/demonstrations/repository":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository/assets" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository/assets" | head -1)
  echo "MKCOL "$SERVER/publishedContent/demonstrations/repository/assets":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent" | head -1)
  echo "MKCOL "$SERVER/publishedContent":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations" | head -1)
  echo "MKCOL "$SERVER/publishedContent/demonstrations":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository" | head -1)
  echo "MKCOL "$SERVER/publishedContent/demonstrations/repository":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository/simulation" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository/simulation" | head -1)
  echo "MKCOL "$SERVER/publishedContent/demonstrations/repository/simulation":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository/assets/4.3.png" | head -1)
if [ $HttpStatus != "404" ] 
then
  if [ $HttpStatus == "200" ] 
  then
    HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X DELETE --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository/assets/4.3.png" | head -1)
    if [ $HttpStatus != "200" ] && [ $HttpStatus != "204" ]
    then
      echo "DELETE(PUT) "$SERVER/publishedContent/demonstrations/repository/assets/4.3.png":$HttpStatus - Operation Failed" >> $logfilename
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
      exit 5
    fi
  else
    echo "HEAD(PUT) "$SERVER/publishedContent/demonstrations/repository/assets/4.3.png":$HttpStatus - Operation Failed" >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 5
  fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X PUT --write-out "%{http_code}\n"  -s --output /dev/null --upload-file "$demohome/Setup/assets/4.3.png" "$SERVER/publishedContent/demonstrations/repository/assets/4.3.png" | head -1)
echo "PUT:"$demohome/Setup/assets/4.3.png" --> "$SERVER/publishedContent/demonstrations/repository/assets/4.3.png":$HttpStatus" >> $logfilename
if [ $HttpStatus != "201" ] 
then
  echo "Operation Failed: Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 5
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository/assets/6.2.png" | head -1)
if [ $HttpStatus != "404" ] 
then
  if [ $HttpStatus == "200" ] 
  then
    HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X DELETE --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository/assets/6.2.png" | head -1)
    if [ $HttpStatus != "200" ] && [ $HttpStatus != "204" ]
    then
      echo "DELETE(PUT) "$SERVER/publishedContent/demonstrations/repository/assets/6.2.png":$HttpStatus - Operation Failed" >> $logfilename
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
      exit 5
    fi
  else
    echo "HEAD(PUT) "$SERVER/publishedContent/demonstrations/repository/assets/6.2.png":$HttpStatus - Operation Failed" >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 5
  fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X PUT --write-out "%{http_code}\n"  -s --output /dev/null --upload-file "$demohome/Setup/assets/6.2.png" "$SERVER/publishedContent/demonstrations/repository/assets/6.2.png" | head -1)
echo "PUT:"$demohome/Setup/assets/6.2.png" --> "$SERVER/publishedContent/demonstrations/repository/assets/6.2.png":$HttpStatus" >> $logfilename
if [ $HttpStatus != "201" ] 
then
  echo "Operation Failed: Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 5
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository/assets/6.3.png" | head -1)
if [ $HttpStatus != "404" ] 
then
  if [ $HttpStatus == "200" ] 
  then
    HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X DELETE --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository/assets/6.3.png" | head -1)
    if [ $HttpStatus != "200" ] && [ $HttpStatus != "204" ]
    then
      echo "DELETE(PUT) "$SERVER/publishedContent/demonstrations/repository/assets/6.3.png":$HttpStatus - Operation Failed" >> $logfilename
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
      exit 5
    fi
  else
    echo "HEAD(PUT) "$SERVER/publishedContent/demonstrations/repository/assets/6.3.png":$HttpStatus - Operation Failed" >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 5
  fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X PUT --write-out "%{http_code}\n"  -s --output /dev/null --upload-file "$demohome/Setup/assets/6.3.png" "$SERVER/publishedContent/demonstrations/repository/assets/6.3.png" | head -1)
echo "PUT:"$demohome/Setup/assets/6.3.png" --> "$SERVER/publishedContent/demonstrations/repository/assets/6.3.png":$HttpStatus" >> $logfilename
if [ $HttpStatus != "201" ] 
then
  echo "Operation Failed: Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 5
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository/assets/6.4.png" | head -1)
if [ $HttpStatus != "404" ] 
then
  if [ $HttpStatus == "200" ] 
  then
    HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X DELETE --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository/assets/6.4.png" | head -1)
    if [ $HttpStatus != "200" ] && [ $HttpStatus != "204" ]
    then
      echo "DELETE(PUT) "$SERVER/publishedContent/demonstrations/repository/assets/6.4.png":$HttpStatus - Operation Failed" >> $logfilename
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
      exit 5
    fi
  else
    echo "HEAD(PUT) "$SERVER/publishedContent/demonstrations/repository/assets/6.4.png":$HttpStatus - Operation Failed" >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 5
  fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X PUT --write-out "%{http_code}\n"  -s --output /dev/null --upload-file "$demohome/Setup/assets/6.4.png" "$SERVER/publishedContent/demonstrations/repository/assets/6.4.png" | head -1)
echo "PUT:"$demohome/Setup/assets/6.4.png" --> "$SERVER/publishedContent/demonstrations/repository/assets/6.4.png":$HttpStatus" >> $logfilename
if [ $HttpStatus != "201" ] 
then
  echo "Operation Failed: Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 5
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository/simulation/ImageLibrary.zip" | head -1)
if [ $HttpStatus != "404" ] 
then
  if [ $HttpStatus == "200" ] 
  then
    HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X DELETE --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/demonstrations/repository/simulation/ImageLibrary.zip" | head -1)
    if [ $HttpStatus != "200" ] && [ $HttpStatus != "204" ]
    then
      echo "DELETE(PUT) "$SERVER/publishedContent/demonstrations/repository/simulation/ImageLibrary.zip":$HttpStatus - Operation Failed" >> $logfilename
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
      exit 5
    fi
  else
    echo "HEAD(PUT) "$SERVER/publishedContent/demonstrations/repository/simulation/ImageLibrary.zip":$HttpStatus - Operation Failed" >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 5
  fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X PUT --write-out "%{http_code}\n"  -s --output /dev/null --upload-file "$demohome/Setup/ImageLibrary.zip" "$SERVER/publishedContent/demonstrations/repository/simulation/ImageLibrary.zip" | head -1)
echo "PUT:"$demohome/Setup/ImageLibrary.zip" --> "$SERVER/publishedContent/demonstrations/repository/simulation/ImageLibrary.zip":$HttpStatus" >> $logfilename
if [ $HttpStatus != "201" ] 
then
  echo "Operation Failed: Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 5
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home" | head -1)
  echo "MKCOL "$SERVER/home":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER" | head -1)
  echo "MKCOL "$SERVER/home/$USER":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations" | head -1)
  echo "MKCOL "$SERVER/home/$USER/demonstrations":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository" | head -1)
  echo "MKCOL "$SERVER/home/$USER/demonstrations/repository":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home" | head -1)
  echo "MKCOL "$SERVER/home":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER" | head -1)
  echo "MKCOL "$SERVER/home/$USER":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations" | head -1)
  echo "MKCOL "$SERVER/home/$USER/demonstrations":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository" | head -1)
  echo "MKCOL "$SERVER/home/$USER/demonstrations/repository":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql" | head -1)
  echo "MKCOL "$SERVER/home/$USER/demonstrations/repository/sql":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql/countMetadata.sql" | head -1)
if [ $HttpStatus != "404" ] 
then
  if [ $HttpStatus == "200" ] 
  then
    HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X DELETE --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql/countMetadata.sql" | head -1)
    if [ $HttpStatus != "200" ] && [ $HttpStatus != "204" ]
    then
      echo "DELETE(PUT) "$SERVER/home/$USER/demonstrations/repository/sql/countMetadata.sql":$HttpStatus - Operation Failed" >> $logfilename
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
      exit 5
    fi
  else
    echo "HEAD(PUT) "$SERVER/home/$USER/demonstrations/repository/sql/countMetadata.sql":$HttpStatus - Operation Failed" >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 5
  fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X PUT --write-out "%{http_code}\n"  -s --output /dev/null --upload-file "$demohome/$USER/sql/countMetadata.sql" "$SERVER/home/$USER/demonstrations/repository/sql/countMetadata.sql" | head -1)
echo "PUT:"$demohome/$USER/sql/countMetadata.sql" --> "$SERVER/home/$USER/demonstrations/repository/sql/countMetadata.sql":$HttpStatus" >> $logfilename
if [ $HttpStatus != "201" ] 
then
  echo "Operation Failed: Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 5
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql/listRepositoryEvents.sql" | head -1)
if [ $HttpStatus != "404" ] 
then
  if [ $HttpStatus == "200" ] 
  then
    HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X DELETE --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql/listRepositoryEvents.sql" | head -1)
    if [ $HttpStatus != "200" ] && [ $HttpStatus != "204" ]
    then
      echo "DELETE(PUT) "$SERVER/home/$USER/demonstrations/repository/sql/listRepositoryEvents.sql":$HttpStatus - Operation Failed" >> $logfilename
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
      exit 5
    fi
  else
    echo "HEAD(PUT) "$SERVER/home/$USER/demonstrations/repository/sql/listRepositoryEvents.sql":$HttpStatus - Operation Failed" >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 5
  fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X PUT --write-out "%{http_code}\n"  -s --output /dev/null --upload-file "$demohome/$USER/sql/listRepositoryEvents.sql" "$SERVER/home/$USER/demonstrations/repository/sql/listRepositoryEvents.sql" | head -1)
echo "PUT:"$demohome/$USER/sql/listRepositoryEvents.sql" --> "$SERVER/home/$USER/demonstrations/repository/sql/listRepositoryEvents.sql":$HttpStatus" >> $logfilename
if [ $HttpStatus != "201" ] 
then
  echo "Operation Failed: Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 5
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql/resetDemo.sql" | head -1)
if [ $HttpStatus != "404" ] 
then
  if [ $HttpStatus == "200" ] 
  then
    HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X DELETE --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql/resetDemo.sql" | head -1)
    if [ $HttpStatus != "200" ] && [ $HttpStatus != "204" ]
    then
      echo "DELETE(PUT) "$SERVER/home/$USER/demonstrations/repository/sql/resetDemo.sql":$HttpStatus - Operation Failed" >> $logfilename
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
      exit 5
    fi
  else
    echo "HEAD(PUT) "$SERVER/home/$USER/demonstrations/repository/sql/resetDemo.sql":$HttpStatus - Operation Failed" >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 5
  fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X PUT --write-out "%{http_code}\n"  -s --output /dev/null --upload-file "$demohome/$USER/sql/resetDemo.sql" "$SERVER/home/$USER/demonstrations/repository/sql/resetDemo.sql" | head -1)
echo "PUT:"$demohome/$USER/sql/resetDemo.sql" --> "$SERVER/home/$USER/demonstrations/repository/sql/resetDemo.sql":$HttpStatus" >> $logfilename
if [ $HttpStatus != "201" ] 
then
  echo "Operation Failed: Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 5
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql/createDirectories.sql" | head -1)
if [ $HttpStatus != "404" ] 
then
  if [ $HttpStatus == "200" ] 
  then
    HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X DELETE --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql/createDirectories.sql" | head -1)
    if [ $HttpStatus != "200" ] && [ $HttpStatus != "204" ]
    then
      echo "DELETE(PUT) "$SERVER/home/$USER/demonstrations/repository/sql/createDirectories.sql":$HttpStatus - Operation Failed" >> $logfilename
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
      exit 5
    fi
  else
    echo "HEAD(PUT) "$SERVER/home/$USER/demonstrations/repository/sql/createDirectories.sql":$HttpStatus - Operation Failed" >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 5
  fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X PUT --write-out "%{http_code}\n"  -s --output /dev/null --upload-file "$demohome/$USER/sql/createDirectories.sql" "$SERVER/home/$USER/demonstrations/repository/sql/createDirectories.sql" | head -1)
echo "PUT:"$demohome/$USER/sql/createDirectories.sql" --> "$SERVER/home/$USER/demonstrations/repository/sql/createDirectories.sql":$HttpStatus" >> $logfilename
if [ $HttpStatus != "201" ] 
then
  echo "Operation Failed: Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 5
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql/queryMetadata.sql" | head -1)
if [ $HttpStatus != "404" ] 
then
  if [ $HttpStatus == "200" ] 
  then
    HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X DELETE --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql/queryMetadata.sql" | head -1)
    if [ $HttpStatus != "200" ] && [ $HttpStatus != "204" ]
    then
      echo "DELETE(PUT) "$SERVER/home/$USER/demonstrations/repository/sql/queryMetadata.sql":$HttpStatus - Operation Failed" >> $logfilename
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
      exit 5
    fi
  else
    echo "HEAD(PUT) "$SERVER/home/$USER/demonstrations/repository/sql/queryMetadata.sql":$HttpStatus - Operation Failed" >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 5
  fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X PUT --write-out "%{http_code}\n"  -s --output /dev/null --upload-file "$demohome/$USER/sql/queryMetadata.sql" "$SERVER/home/$USER/demonstrations/repository/sql/queryMetadata.sql" | head -1)
echo "PUT:"$demohome/$USER/sql/queryMetadata.sql" --> "$SERVER/home/$USER/demonstrations/repository/sql/queryMetadata.sql":$HttpStatus" >> $logfilename
if [ $HttpStatus != "201" ] 
then
  echo "Operation Failed: Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 5
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql/addAdditionalMetadata.sql" | head -1)
if [ $HttpStatus != "404" ] 
then
  if [ $HttpStatus == "200" ] 
  then
    HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X DELETE --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql/addAdditionalMetadata.sql" | head -1)
    if [ $HttpStatus != "200" ] && [ $HttpStatus != "204" ]
    then
      echo "DELETE(PUT) "$SERVER/home/$USER/demonstrations/repository/sql/addAdditionalMetadata.sql":$HttpStatus - Operation Failed" >> $logfilename
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
      exit 5
    fi
  else
    echo "HEAD(PUT) "$SERVER/home/$USER/demonstrations/repository/sql/addAdditionalMetadata.sql":$HttpStatus - Operation Failed" >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 5
  fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X PUT --write-out "%{http_code}\n"  -s --output /dev/null --upload-file "$demohome/$USER/sql/addAdditionalMetadata.sql" "$SERVER/home/$USER/demonstrations/repository/sql/addAdditionalMetadata.sql" | head -1)
echo "PUT:"$demohome/$USER/sql/addAdditionalMetadata.sql" --> "$SERVER/home/$USER/demonstrations/repository/sql/addAdditionalMetadata.sql":$HttpStatus" >> $logfilename
if [ $HttpStatus != "201" ] 
then
  echo "Operation Failed: Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 5
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql/simulateImageLoad.sql" | head -1)
if [ $HttpStatus != "404" ] 
then
  if [ $HttpStatus == "200" ] 
  then
    HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X DELETE --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/sql/simulateImageLoad.sql" | head -1)
    if [ $HttpStatus != "200" ] && [ $HttpStatus != "204" ]
    then
      echo "DELETE(PUT) "$SERVER/home/$USER/demonstrations/repository/sql/simulateImageLoad.sql":$HttpStatus - Operation Failed" >> $logfilename
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
      exit 5
    fi
  else
    echo "HEAD(PUT) "$SERVER/home/$USER/demonstrations/repository/sql/simulateImageLoad.sql":$HttpStatus - Operation Failed" >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 5
  fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X PUT --write-out "%{http_code}\n"  -s --output /dev/null --upload-file "$demohome/$USER/sql/simulateImageLoad.sql" "$SERVER/home/$USER/demonstrations/repository/sql/simulateImageLoad.sql" | head -1)
echo "PUT:"$demohome/$USER/sql/simulateImageLoad.sql" --> "$SERVER/home/$USER/demonstrations/repository/sql/simulateImageLoad.sql":$HttpStatus" >> $logfilename
if [ $HttpStatus != "201" ] 
then
  echo "Operation Failed: Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 5
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home" | head -1)
  echo "MKCOL "$SERVER/home":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER" | head -1)
  echo "MKCOL "$SERVER/home/$USER":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/ImageLibrary" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/ImageLibrary" | head -1)
  echo "MKCOL "$SERVER/home/$USER/ImageLibrary":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent" | head -1)
  echo "MKCOL "$SERVER/publishedContent":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/categorization" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/categorization" | head -1)
  echo "MKCOL "$SERVER/publishedContent/categorization":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/categorization/images" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $DBA:$DBAPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/publishedContent/categorization/images" | head -1)
  echo "MKCOL "$SERVER/publishedContent/categorization/images":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
# Junction Point : Location : $demohome\$USER\WebDAV\ImageLibrary. Name : ImageLibrary on $HOSTNAME. Target : \home\$USER\ImageLibrary.
# Junction Point : Location : $demohome\$USER\WebDAV\ImageCategories. Name : Image Categories on $HOSTNAME. Target : \publishedContent\categorization\images.
# Junction Point : Location : $demohome\$USER\sampleData. Name : $USER on $HOSTNAME. Target : \home\$USER.
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home" | head -1)
  echo "MKCOL "$SERVER/home":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER" | head -1)
  echo "MKCOL "$SERVER/home/$USER":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations" | head -1)
  echo "MKCOL "$SERVER/home/$USER/demonstrations":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository" | head -1)
  echo "MKCOL "$SERVER/home/$USER/demonstrations/repository":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/Links" | head -1)
if [ $HttpStatus == "404" ] 
then
  HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X MKCOL --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/Links" | head -1)
  echo "MKCOL "$SERVER/home/$USER/demonstrations/repository/Links":$HttpStatus" >> $logfilename
  if [ $HttpStatus != "201" ]
  then
    echo "Operation Failed [$HttpStatus] - Installation Aborted." >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 6
	 fi
fi
sed -e "s|%DESKTOP%|C:\Users\Mark D Drake\Desktop|g" -e "s|%STARTMENU%|C:\Users\Mark D Drake\AppData\Roaming\Microsoft\Windows\Start Menu|g" -e "s|%WINWORD%|C:\PROGRA~2\MICROS~2\Office12\WINWORD.EXE|g" -e "s|%EXCEL%|C:\PROGRA~2\MICROS~2\Office12\EXCEL.EXE|g" -e "s|%DEMODIRECTORY%|$demohome|g" -e "s|%DEMOFOLDERNAME%|REPOSITORY|g" -e "s|%DEMONAME%|An Introduction to the Oracle XML DB Repository|g" -e "s|%LAUNCHPAD%|Repository Features|g" -e "s|%LAUNCHPADFOLDER%|C:\Users\Mark D Drake\AppData\Roaming\Microsoft\Windows\Start Menu\Oracle XML DB Demonstrations|g" -e "s|%SHORTCUTFOLDER%|$demohome\/$USER|g" -e "s|%PUBLICFOLDER%|\/publishedContent|g" -e "s|%DEMOCOMMON%|\/publishedContent\/demonstrations\/repository|g" -e "s|%HOMEFOLDER%|\/home\/%USER%|g" -e "s|%DEMOLOCAL%|\/home\/%USER%\/demonstrations\/repository|g" -e "s|%XFILES_SCHEMA%|XFILES|g" -e "s|%XFILES_ROOT%|XFILES|g" -e "s|%SCHEMAURL%|http:\/\/xmlns.oracle.com\/demo\/imageMetadata.xsd|g" -e "s|%XFILESAPP%|\/XFILES\/Applications\/imageMetadata|g" -e "s|%METADATA_OWNER%|XDBEXT|g" -e "s|protocol|HTTP|g" -e "s|enableHTTPTrace|false|g" -e "s|%ORACLEHOME%|$ORACLE_HOME|g" -e "s|%DBA%|$DBA|g" -e "s|%DBAPASSWORD%|$DBAPWD|g" -e "s|%USER%|$USER|g" -e "s|%PASSWORD%|$USERPWD|g" -e "s|%TNSALIAS%|$ORACLE_SID|g" -e "s|%HOSTNAME%|$HOSTNAME|g" -e "s|%HTTPPORT%|$HTTP|g" -e "s|%FTPPORT%|$FTP|g" -e "s|%DRIVELETTER%||g" -e "s|%SERVERURL%|$SERVER|g" -e "s|%DBCONNECTION%|$USER\/$USERPWD@$ORACLE_SID|g" -e "s|%SQLPLUS%|sqlplus|g" -e "s|\$USER|$USER|g" -e "s|\$SERVER|$SERVER|g" -i $demohome/install/configuration.xml
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD --head --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/configuration.xml" | head -1)
if [ $HttpStatus != "404" ] 
then
  if [ $HttpStatus == "200" ] 
  then
    HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X DELETE --write-out "%{http_code}\n" -s --output /dev/null "$SERVER/home/$USER/demonstrations/repository/configuration.xml" | head -1)
    if [ $HttpStatus != "200" ] && [ $HttpStatus != "204" ]
    then
      echo "DELETE(PUT) "$SERVER/home/$USER/demonstrations/repository/configuration.xml":$HttpStatus - Operation Failed" >> $logfilename
      echo "Installation Failed [$HttpStatus]: See $logfilename for details."
      exit 5
    fi
  else
    echo "HEAD(PUT) "$SERVER/home/$USER/demonstrations/repository/configuration.xml":$HttpStatus - Operation Failed" >> $logfilename
    echo "Installation Failed [$HttpStatus]: See $logfilename for details."
    exit 5
  fi
fi
HttpStatus=$(curl --noproxy '*' --digest -u $USER:$USERPWD -X PUT --write-out "%{http_code}\n"  -s --output /dev/null --upload-file "$demohome/install/configuration.xml" "$SERVER/home/$USER/demonstrations/repository/configuration.xml" | head -1)
echo "PUT:"$demohome/install/configuration.xml" --> "$SERVER/home/$USER/demonstrations/repository/configuration.xml":$HttpStatus" >> $logfilename
if [ $HttpStatus != "201" ] 
then
  echo "Operation Failed: Installation Aborted." >> $logfilename
  echo "Installation Failed [$HttpStatus]: See $logfilename for details."
  exit 5
fi
sqlplus $DBA/$DBAPWD@$ORACLE_SID @$demohome/install/sql/publishDemo.sql /home/$USER/demonstrations/repository XFILES
shellscriptName="$demohome/Repository_Features.sh"
echo "Shell Script : $shellscriptName" >> $logfilename
echo "Shell Script : $shellscriptName"
echo "firefox $SERVER/home/$USER/demonstrations/repository/index.html"> $shellscriptName
echo "Installation Complete" >> $logfilename
echo "Installation Complete: See $logfilename for details."
