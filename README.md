# AWS_Tools

Facilitates the deployment of AppDynamics AWS Monitoring Extensions:

  - AWSLambdaMonitor
  - AWSSNSMonitor
  - AWSSQSMonitor
  - AWSS3Monitor
  - AWSELBMonitor

Additional extensions can added, or extensions removed as needed.

Use the command as follows:

Configure the environment variable TARGET_MACHINE_AGENT_DIR in the script extension-ctl.sh to point to the installed Machine Agent directory

# Validate the extensions to be downloaded and installed
./extension-ctl.sh check

# Download all of the Extensions
./extension-ctl.sh download

# Install the Extensions
./extension-ctl.sh install

# Prepare the Extensions configuration
Copies the individual extension config files to this directory

./extension-ctl.sh prepare

# Edit the individual extensions configuration files .yaml
Modify the following sections of .yaml files
* accounts:
  + awsAccessKey: "ACCESSS-KEY"
  + awsSecretKey: "SECRET-KEY""
  + displayAccountName: "APPD-AWS"
* metricPrefix: "Custom Metrics|EXTENSION-NAME|"

# Configure the Extensions
Copies the modifed configuration files back to each extension install dir

./extension-ctl.sh config

# Validate Extensions configurations
./extension-ctl.sh validate

# Restart the Machine agent
./extension-ctl.sh start

# Review the Machine Agent logs
tail -f logs/machine-agent.log
