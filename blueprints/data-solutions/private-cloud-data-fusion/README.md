# Google Cloud Private Data Fusion

This repository contains Terraform sample code to deploy Cloud Data Fusion and Cloud SQL private instances, and establish communication between them.

Resources created
- VPC
- Compute Engine VM
- Cloud SQL for MySQL
- Cloud Data Fusion

This blueprint uses Cloud Build to deploy the stack and Cloud Storage to persist the terraform state in your project.

You can see the state files by running the command `gsutil ls gs://<PROJECT_ID>-tf-state`.
And you can see the deploy history on [Build history](https://console.cloud.google.com/cloud-build/builds).

## Arquitecture
![diagram](diagram.png)

## Deploy

1. Click on Open in Google Cloud Shell button below.
<a href="https://ssh.cloud.google.com/cloudshell/editor?shellonly=true&cloudshell_git_repo=https://github.com/GoogleCloudPlatform/cloud-foundation-fabric" target="_new">
    <img alt="Open in Cloud Shell" src="https://gstatic.com/cloudssh/images/open-btn.svg">
</a>

2. Run the `cloudbuild.sh` script
```
sh blueprints/data-solutions/private-cloud-data-fusion/cloudbuild.sh
```

After you created the resources, you can use the Cloud SQL Proxy VM's internal IP to connect from Cloud Data Fusion to Cloud SQL. Before you can connect to the MySQL instance from the Cloud Data Fusion instance, install the MySQL JDBC driver from the Cloud Data Fusion Hub.

For more information on how to setup this connection, please refer to [this link](https://cloud.google.com/data-fusion/docs/how-to/connect-to-cloud-sql-source).

## Destroy

Run the `cloudbuild.sh` script with the `destroy` argument.
```
sh blueprints/data-solutions/private-cloud-data-fusion/cloudbuild.sh destroy
```

## Useful links
- [Cloud Data Fusion How-to guides](https://cloud.google.com/data-fusion/docs/how-to)
- [Cloud SQL](https://cloud.google.com/sql)
