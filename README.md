# AwsCli-GUI
GUI for aws-cli: https://github.com/aws/aws-cli

The program can be run without installation (if `aws-cli` is installed) or from rpm/deb packages (see Releases). Immediately after the launch, the AwsCli-GUI tries to connect to the cloud storage. To configure the connection, click the button with the `Gear` icon. Selecting several objects (except buckets) in the file manager - `Ctrl+LMouse`, canceling long copy operations - `Esc` button. Tested in Mageia-8/LUbutu-21.10.

AWS CLI Command Reference: https://awscli.amazonaws.com/v2/documentation/api/latest/reference/index.html

**Note:** For a number of objective reasons, I strongly recommend instead `aws-cli` use `s3cmd` + `S3cmd-GUI`:  
https://github.com/AKotov-dev/s3cmd-gui `S3cmd` is much faster and more reliable than `aws-cli`.
