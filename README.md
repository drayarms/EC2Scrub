----------------------------------------------------------------
						--TABLE OF CONTENTS--
----------------------------------------------------------------

1.	Summary
2.	Infrastructure
3.	Lambda Function Deplyment Options
	A.	Bash Script/CLI
	B.	AWS Cloud Watch EventBridge
4.	Monitoring


----------------------------------------------------------------------------------
1										--SUMMARY--
----------------------------------------------------------------------------------

The goal of this project is to configure an AWS Lambda function to retrieve
all EC2 snapshots within a specified region in a VPC, automatically delte all 
snapshots older than a year, and log the actions of the Lambda function including
errors, to CloudWatch Logs.


--------------------------------------------------------------------------------------------
2									--INFRASTRUCTUE--
--------------------------------------------------------------------------------------------

The IaC tool utilized in Terraform, chosen for its declarative configuration, idempotency,
and ability to automatically manage dependencies. The architecture consists of:
-A VPC.
-An internet gateway.
-Two availability zones (us-west-1a and us-west-1c) for high availability and redundancy. 
-One public and one private subnet within each availability zone.
-A route table that links each public subnet to the internet gateway.
-A route table for each private subnet.
-A NAT gateway in each public subnet that connects the corresponding private subnet to the 
 public subnet by way of the private route table.
-A Lambda function
-An IAM role for the Lambda function with permissions to manage ENIs, retrieve EC2s within
 the VPC, list and delete EC2 snapshots, and CloudWatch logs permission for Lambda. 
-A Lambda zip file which the Lambda is created from the Python function that implements
 the Lambda handler.  
-An event bridge to trigger the Lambda function daily, alongside with permissions for the
 event bridge to invoke Lambda.

The project directory structure is as follows:
EC2Scrub
	/Application
		lambda_function.py
		invoke-ec2-scrubber-lambda.sh
	/Infrastructure
		/Backend
			main.tf
			variables.tf
			outputs.tf
		/Infrastructure
			main.tf
			variables.tf
			outputs.tf
			backend.tf
			/Modules
				/Network
					main.tf
					variables.tf
					outputs.tf
				/Compute		
					main.tf
					variables.tf
					outputs.tf
					lambda.zip

The /Infrastructure/Backend directory is responsible for setting up the backend where the S3 bucket
for storing the state file and DynamoDB table for state locking will be located. 
cd to this directory and run
terraform init
terraform plan
terraform apply
The /Infrastructure/Infrastructure directory has the configuration for the resources (VPC, subnets, 
Lambda, etc). These are defined within the modules Network(VPC, subnets, route tables, etc) and 
Compute(Lambda, permissions, etc). To deploy, cd to this directory and run
terraform init
terraform plan
terraform apply
The Lambda funtion is triggered from both private subnets via this association found in the 
/Infrastructure/Infrastructure/Modules/Compute/main.tf file.
  vpc_config {
    subnet_ids = var.aws_private_subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }  
This line, handler = var.lambda_handler points the Lambda function to the Lambda handler
implemented in /Application/lambda function.py
The zip file is automatically created from the lambda_function.py and stored as lambda.zip in 
/Infrastructure/Infrastructure/Modules/Compute


---------------------------------------------------------------------------------------------------------
3										--LAMBDA FUNCTION DEPLOYMENT--
---------------------------------------------------------------------------------------------------------

A) Bash Script/CLI
This is the preferred method for testing/troubleshooting. The bash script invoke-ec2-scrubber-lambda.sh
contains loging for setting environment variables to define the age that EC2 snapshots must be deleted
if they exceed, and logic for zipping the lambda handler into the zip file, in case it is edited, 
before the function itself is tirggered. To execute, first make the file an executable. Be sure you in
/Applicatin directory, then run
chmod 777 invoke-ec2-scrubber-lambda.sh
./invoke-ec2-scrubber-lambda.sh

B) AWS Even Bridge
This is triggered automatically everyday at 2AM as long as the infrastructure successfully deploys as 
described above. The magic suaceis this line 
schedule_expression = "cron(0 2 * * ? * )" 
found in /Infrastructure/Infrastructure/Modules/Compute/main.tf, which sets up a cron task.


-----------------------------------------------------------------------------------------------------------
4											--MONITORING--
-----------------------------------------------------------------------------------------------------------
Once Lambda is triggered, the activitiies logged can be monitored by going to AWS CloudWatch console.
In the left panel, click on "log groups". Click on the name of you log group, and in the log group page
click on "log stream". If everything was setup correctly, the log streams registered by the Lambda
function trigger should be visible, including successful and unsuccessful attemps to scrub EC2 instances,
and any other errors encountered. 





Author: Matthew Akofu 01/11/2026