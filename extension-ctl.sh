#!/bin/bash
#
#
# Copyright (c) AppDynamics Inc
# All rights reserved
#
# Maintainer: David Ryder, david.ryder@appdynamics.com
#
# AppDynamics AWS Extension download and configuration tool
#
# Execute as sequence:
# 1) check
# 2) download - download the extensions
# 3) install - install the extensions
# 4) prepare - copy yaml file to local dir
# 5) Modify yaml files: metricPrefix, awsAccessKey, awsSecretKey, displayAccountName
# 6) config - deploy the configuration files from local dir to extension dirs
# 7) validate
# 8) start - Start the machine agent
#
#
# Target Directory of where the machine agent is installed
# AWS Extensions are installed the monitors directory
TARGET_MACHINE_AGENT_DIR="~/agents/mac"
#
# List of AppDynamics AWS Extensions to download, configure, install
# Validate download URLS at https://www.appdynamics.com/community/exchange/
AWS_EXTENSIONS_LIST=(\
  "AWSLambdaMonitor,config.yml,awslambdamonitor-2.0.1.zip,https://www.appdynamics.com/media/uploaded-files/1553252150" \
  "AWSSNSMonitor,conf/config.yaml,awssnsmonitor-1.0.2.zip,https://www.appdynamics.com/media/uploaded-files/1522284590" \
  "AWSSQSMonitor,conf/config.yaml,awssqsmonitor-1.0.3.zip,https://www.appdynamics.com/media/uploaded-files/1522286224" \
  "AWSS3Monitor,config.yml,awss3monitor-2.0.1.zip,https://www.appdynamics.com/media/uploaded-files/1553252907" \
  "AWSELBMonitor,config.yml,awselbmonitor-1.2.2.zip,https://www.appdynamics.com/media/uploaded-files/1564682169" \
  )
#

_parseExtensionListItem() {
  ITEM=$1
  EXT_NAME=`echo $ITEM      | cut -d ',' -f1`
  CONFIG_FILE=`echo $ITEM   | cut -d ',' -f2`
  ZIP_FILE=`echo $ITEM      | cut -d ',' -f3`
  DOWNLOAD_URL=`echo $ITEM  | cut -d ',' -f4`
}

_deployConfig() {
  EXT_NAME=$1
  EXT_TARGET=$2
  echo "Copying config to extension: $EXT_NAME"
  cp $EXT_NAME-config.yaml $TARGET_MACHINE_AGENT_DIR/monitors/$EXT_NAME/$EXT_TARGET
}

_prepareConfig() {
  # Copy to *.yaml
  EXT_NAME=$1
  EXT_SRC=$2
  echo "Copying config from extension: $EXT_NAME $EXT_SRC"
  cp $TARGET_MACHINE_AGENT_DIR/monitors/$EXT_NAME/$EXT_SRC $EXT_NAME-config.yaml
}

_validateConfig() {
  EXT_NAME=$1
  EXT_TGT=$2
  V1=`md5sum $EXT_NAME-config.yaml | cut -d ' ' -f1`
  V2=`md5sum $TARGET_MACHINE_AGENT_DIR/monitors/$EXT_NAME/$EXT_TGT | cut -d ' ' -f1`
  echo $EXT_NAME $V1 $V2
}

cmd=${1:-"unknown"}
if [ $cmd == "check" ]; then
  # Check what extensions will be downloaded and installed
  for i in "${AWS_EXTENSIONS_LIST[@]}"; do
    _parseExtensionListItem $i
    echo $EXT_NAME $CONFIG_FILE $ZIP_FILE $DOWNLOAD_URL
  done

elif [ $cmd == "download" ]; then
  # Download the extension zip files
  for i in "${AWS_EXTENSIONS_LIST[@]}"; do
    _parseExtensionListItem $i
    curl $DOWNLOAD_URL/$ZIP_FILE -o $ZIP_FILE
  done

elif [ $cmd == "install" ]; then
  # Monitoring extensions install into the the monitors directory
  for i in "${AWS_EXTENSIONS_LIST[@]}"; do
    _parseExtensionListItem $i
    unzip $ZIP_FILE -d $TARGET_MACHINE_AGENT_DIR/monitors
  done

elif [ $cmd == "prepare" ]; then
  # Copy in the config.yml files
  for i in "${AWS_EXTENSIONS_LIST[@]}"; do
    _parseExtensionListItem $i
    _prepareConfig $EXT_NAME $CONFIG_FILE
  done

elif [ $cmd == "config" ]; then
  # Copy in the config.yml files
  for i in "${AWS_EXTENSIONS_LIST[@]}"; do
    _parseExtensionListItem $i
    _deployConfig  $EXT_NAME $CONFIG_FILE
  done

elif [ $cmd == "validate" ]; then
  for i in "${AWS_EXTENSIONS_LIST[@]}"; do
    _parseExtensionListItem $i
    _validateConfig  $EXT_NAME $CONFIG_FILE
  done

elif [ $cmd == "start" ]; then
  # Stop and restart the machine agent
  pkill -f "machineagent.jar"
  sleep 2
  rm -rf $TARGET_MACHINE_AGENT_DIR/logs/*
  rm -f nohup.out
  rm $TARGET_MACHINE_AGENT_DIR/monitors/analytics-agent/analytics-agent.id
  eval MAC_AGENT_PATH=`echo $TARGET_MACHINE_AGENT_DIR/bin/machine-agent`
  echo "Running $MAC_AGENT_PATH"
  nohup $MAC_AGENT_PATH -Dad.agent.name="analytics-"`hostname`  &
  # Check that its starts
  TAIL_DURATION_SEC=60
  echo "Tailing nohup.out for $TAIL_DURATION_SEC seconds"
  sleep 5
  tail -f nohup.out &
  TAIL_PID=$!
  (sleep $TAIL_DURATION_SEC; echo "Stopping $TAIL_PID"; kill -9 $TAIL_PID; ) &

elif [ $cmd == "stop" ]; then
  # Stop machine agent
  pkill -f "machineagent.jar"

elif [ $cmd == "clean" ]; then
  # Delete all the extensions
  for i in "${AWS_EXTENSIONS_LIST[@]}"; do
    _parseExtensionListItem $i
    rm -rf $TARGET_MACHINE_AGENT_DIR/monitors/$EXT_NAME
  done

elif [ $cmd == "test1" ]; then
  echo "test1"

else
  echo "Unknown command: $cmd"
fi
