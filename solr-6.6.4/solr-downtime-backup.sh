#!/bin/bash

# replace below array with actual zookeeper nodes ip addresses (specify single node if single zookeper)
declare -r zookeeperNodes=(10.108.1.255 10.108.2.255 10.108.3.255)

# replace below port number for zookeeper if otherwise different
declare -r zookeeperPort=2181

# replace below username for zookeeper node
declare -r zookeeperUser="ec2-user"

# replace below array with actual solr nodes ip addresses
declare -r solrNodes=(10.108.0.0 10.108.0.1 10.108.0.2 10.108.0.3)

# replace below port number for solr if otherwise different
declare -r solrPort=8443

# replace below username for solr node
declare -r solrUser="ec2-user"

# replace below path with solr home directory installed on each solr node
declare -r solrHome="/home/ec2-user/solr"

# replace the below with the solr collection name that needs to be backed up
declare -r solrCollection="gettingstarted"

# replace the below with the solr configuration name pushed to zookeeper
declare -r solrConfig="config"

# replace the below with log location for this script - make sure write permissions is applicable
declare -r logFileLocation="/home/ec2-user/solr-downtime-backup.log"

# default backup location; can be changed below or via options at time of invocation
declare outputLocation="/home/ec2-user/%{solrCollection}-backup-$(date +%Y-%m-%d'T'%H:%M:%S')"

# default tarred parameter; can be changed below or via options at time of invocation
declare tarred=false

# DEBUG logger function
function logDebug() {
  echo "$(date +%Y-%m-%d' '%H:%M:%S' '%Z) [DEBUG] $1" #>> "${logFileLocation}"
}

# INFO logger function
function logInfo() {
  echo "$(date +%Y-%m-%d' '%H:%M:%S' '%Z) [INFO] $1" #>> "${logFileLocation}"
}

# WARN logger function
function logWarn() {
  echo "$(date +%Y-%m-%d' '%H:%M:%S' '%Z) [WARN] $1" #>> "${logFileLocation}"
}

# ERROR logger function
function logError() {
  echo "$(date +%Y-%m-%d' '%H:%M:%S' '%Z) [ERROR] $1" #>> "${logFileLocation}"
}

# retrieve setSolrCores() {
  solrNodeStatusUrl="https://${1}/${solrPort}/solr/admin/cores?action=STATUS&wt=json"
  logDebug "CMD: curl -w 'httpcode=%{httpcode}' --insecure \"${solrNodeStatusUrl}\" 2>/dev/null"
  
  response=$(curl -w 'httpcode=%{httpcode}' --insecure \"${solrNodeStatusUrl}\" 2>/dev/null)
  responseCode=`echo ${response} | sed -e 's/.*\httpcode=//'`
  response=`echo ${response} | sed -e "s/ httpcode=${responseCode}$//"`
  
  if [ "$responseCode" -eq 200 ]
  then
    logInfo "Response Info '${responseCode}': Retrieved status response for solr node '${1}'"
    cores=`echo ${response} | jq -r '.status[].name'`
    solrNodeCores=($cores)
    
    logDebug "Retrieved cores '${solrNodeCores[*]}' for solr node '${1}'"
  else
    logError "Response code '${responseCode}': Unable to retrieve status response for Solr node '${1}'"
  fi
}

# backup indexes on each solr node and download collection config
function backupSolrIndexes() {
  for solrNode in "${solrNodes[@]}"
  do
    logInfo "Retrieving solr cores for solr node '${solrNode}'"
    setSolrCores ${solrNode}
    
    for solrCore in "${solrNodeCores[@]}"
    do
      logInfo "Backing up solr core '${solrCore}' on solr node '${solrNode}'"
      
    done
  done
}

# tars the solr backup if applicable
function determineTarred() {
  if ${tarred}
  then
    outputDirname=$(dirname ${outputLocation})
    outputBasename=$(basename ${outputLocation})
    logInfo "Attempting to tar '${outputLocation}' to destination '${outputBasename}/${outputDirname}.tgz'"
  else 
    logDebug "Skipping tar operation due to no specification for tarring"
  fi
}

# upload solr backup if applicable
function uploadSolrBackup() {
  if [[ ! -z "${uploadBucket}" ]] && [[ ! -z "${uploadPrefix}" ]]
  then
    outputBasename=$(basename ${outputLocation})
    logInfo "Attempting to upload backup file '${outputLocation}' to 's3://${uploadBucket}/${uploadPrefix}/${outputBasename}'"
  else
    logError "Unable to upload backup to AWS due to missing bucket '${uploadBucket}' or prefix '${uploadPrefix}'"
  fi
}

# function for ssh without pem file and command
function sshCmd() {
  node=$1
  command=$2
  echo "ssh ${solrUser}:${node} '${command}'"
}

# function for ssh with pem file and command
function sshCmdWithPem() {
  node=$1
  command=$2
  echo "ssh -i ${solrPem} ${solrUser}:${node} '${command}'"
}

# main method function to execute logic
function mainMethod() {
  logInfo "Starting solr backup with downtime"
  downtimeStart=$SECONDS
  
  # execute back-up steps
  backupSolrIndexes
  elapsedDowntime=$(( SECONDS - downtimeStart ))
  
  # upload to Amazon S3 if applicable (both bucket and prefix needs to be provided)
  determineTarred
  uploadSolrBackup
  logInfo "Completed solr backup with a downtime of '${elapsedDowntime}' seconds - tarred time and AWS S3 upload time not included"
}

# print help method for outputting instructions to console
function printHelp() {
  echo -e "-output\t\tThe desired output location; default as /home/ec2-user/<solr-collection-name>-backup-<date>";
  echo -e "-tarred\t\tBoolean option for whether or not backup file should be compressed; default as true.";
  echo -e "-bucket\t\tThe upload Amazon S3 bucket name.";
  echo -e "-prefix\t\tThe upload Amazon S3 object prefix.";
  echo -e "-solrPem\t\tThe PEM file for SSH from local instance to other Solr nodes.";
  echo -e "-zooPem\t\tThe PEM file for SSH from local instance to other Zookeeper nodes.";
}

# options which can be passed when invoking script
while [ $# -gt 0 ]; do
  # switch statement operation based off value of $1
  case $1 in 
    -output)  outputLocation="$2"
              logInfo "Recieved output local location '${outputLocation}'; will be used as backup destination."
              ;;
    -tarred)  tarred=true
              logInfo "Recieved tarred option; will tar the backup file."
              ;;
    -bucket)  uploadBucket="$2"
              logInfo "Recieved upload bucket value of '${uploadBucket}'; will be used for uploading to AWS S3."
              ;;
    -prefix)  uploadPrefix="$2"
              logInfo "Recieved upload prefix value of '${uploadPrefix}'; will be used for uploading to AWS S3."
              ;;
    -solrPem) solrPemFile="$2"
              logInfo "Recieved solr SSH pem file location at '${solrPemFile}'; will be used for SSH-ing to solr nodes."
              ;;
    -zooPem)  zooPemFile="$2"
              logInfo "Recieved zookeeper SSH pem file location at '${zooPemFile}'; will be used for SSH-ing to zookeeper nodes."
              ;;
    -help)    printHelp
              exit 0
              ;;
    *)        echo "Option '$1' unknown; please enter '-help' option for assistance"
              ;;
  esac
  
  # shift index of input over
  shift
done

# invoke main method to start logic
mainMethod
