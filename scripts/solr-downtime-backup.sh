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
  echo "$(date +%Y-%m-%d' '%H:%M:%S' '%Z) [DEBUG] $1" >> "${logFileLocation}"
}

# INFO logger function
function logInfo() {
  echo "$(date +%Y-%m-%d' '%H:%M:%S' '%Z) [INFO] $1" >> "${logFileLocation}"
}

# WARN logger function
function logWarn() {
  echo "$(date +%Y-%m-%d' '%H:%M:%S' '%Z) [WARN] $1" >> "${logFileLocation}"
}

# ERROR logger function
function logError() {
  echo "$(date +%Y-%m-%d' '%H:%M:%S' '%Z) [ERROR] $1" >> "${logFileLocation}"
}

# stop all solr process on each solr node specified in array above
function stopSolrNodes() {
  
}

# backup indexes on each solr node and download collection config
function backupSolrIndexes() {

}

# start all solr processes on each solr node specified in array above
function startSolrNodes() {

}

# tars the solr backup if applicable
function determineTarred() {

}

# upload solr backup if applicable
function uploadSolrBackup() {

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
  # stop solr process on each node
  logInfo "Starting solr backup with downtime"
  downtimeStart=$SECONDS
  stopSolrNodes
  
  # execute back-up steps
  backupSolrIndexes
  
  # start solr process on each node
  startSolrNodes
  elapsedDowntime=$(( SECONDS - downtimeStart ))
  
  # upload to Amazon S3 if applicable (both bucket and prefix needs to be provided)
  determineTarred
  uploadSolrBackup
  logInfo "Completed solr backup with a downtime of '${elapsedDowntime}' seconds - tarred time and AWS S3 upload time not included"
}

# print help method for outputting instructions to console
function printHelp() {

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
