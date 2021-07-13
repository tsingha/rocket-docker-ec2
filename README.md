# README.md

Hello! Welcome to my Rocket Chat Automation. This task is automatically deploy a Rocket Chat Application as a standalone docker container on a AWS EC2 Instance. The EC2 instance will be created using **Terraform** and the post configuration and docker container creation will be done by **Ansible**.

Before start create a Jump Server or Client Machine using Centos 7 and do the below task.

1.	**Install AWS CLI command utility**
    ```
    # curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

    # unzip awscliv2.zip

    # sudo ./aws/install

    # aws –version
    ```
2.	**Terraform Installation**
    ```
    # yum install -y yum-utils

    # yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

    # yum -y install terraform

    # terraform --version
    ```
3.	**Ansible Installation**
    ```
    # yum install epel-release -y

    # yum install ansible -y

    # ansible --version
    ```
4.	**Configure AWS CLI**

    To install EC2 instance using Terraform we need AWS CLI also, so we need to create a **IAM user** using below policies.

    Go to Amazon Console -> IAM -> Users -> Add User -> User Name: eksctl -> Access Type: Click on Programmatic access and AWS Management Console access -> Console password:       Autogenerated password -> Click on Require password reset -> Click on Attach existing policies directly -> select the below policies
    
    - **AmazonEC2FullAccess**
    - **IAMUserChangePassword**
    - **SystemAdministrator**
    - **AdministratorAccess**
    
    No need to give tags, its optional -> Next -> Create User.

    After these steps, AWS will provide you a **Secret Access Key and Access Key ID. Save them preciously** because this will be the only time AWS gives it to you.

    **Run the below command**
    ```
    [root@docker ~]# aws configure
    AWS Access Key ID [None]: <Provide the Access Key ID for your IAM user>
    AWS Secret Access Key [None]: <Provide the Secret Access Key for your IAM user>
    Default region name [None]:
    Default output format [None]:
    [root@docker ~]#
    
    [root@docker ~]# cat .aws/credentials
    [default]
    aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
    aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXX
    [root@docker ~]#
    ```
    **Show list of all the IAM user**
    ```
    [root@docker ~]# aws iam list-users
    ```
    **Returns details about the IAM user or role whose credentials are used to call the operation.**
    ```
    [root@docker ~]# aws sts get-caller-identity
    {
        "UserId": "XXXXXXXXXX",
        "Account": "XXXXXXXXXX",
        "Arn": "arn:aws:iam::XXXXXXXXX:user/eksctl"
    }
    [root@docker ~]#
    ```
5.	**Setup Continuous Deployment**

    **Install Jenkins:**
    ```
    # wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    # rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
    # yum upgrade
    # yum install jenkins java-11-openjdk-devel
    # systemctl daemon-reload
    ```
    **Jenkins URL:**
    > **http://<FQDN/IP>:8080**
    
    **Now do the below work,**

    1.	**Enable the Git, Github, AWS, Ansible, Terraform and Docker related plugins.**

        Go to Manage Jenkins -> Manage Plugins -> Click on Available -> Select the related plugins -> Click on Install without restart.

    2.	**Copy the AWS CLI credentials file in /var/lib/Jenkins, so jenkins user can able to use aws command.**
        ```
        # cp .aws/ /var/lib/jenkins/
        # chown -R jenkins:jenkins /var/lib/jenkins/
        # which aws
        # ln -s /usr/local/bin/aws /usr/bin/aws
        ```
    3.	**Now create a freestyle project for Rocket Chat Server Installation.**

        Go to new Item -> Select Freestyle Project -> Provide a name -> OK

        Now Open the project and Provide a description.
        > **Rocket Chat Installation as a Docker Container on EC2**

        In **Source Code Management** provide the **git repository URL**.
        
        > **https://github.com/tsingha/rocket-docker-ec2.git**

        In **Build** section choose the **Execute shell** and write down the command and click on **Save**.
        ```
        cd terraform
        chmod 400 key*
        terraform init
        terraform apply -auto-approve
        sleep 150
        cd ../ansible
        ip=`aws ec2 describe-instances --region us-east-2 --filter "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].[PublicIpAddress, Tags[?     Key=='Name'].Value|[0]]" --output text | grep Linux-Docker | awk '{ print $1 }'`
        echo "[ec2]" > inventory
        echo "$ip" >> inventory
        ansible all --list-hosts
        ansible-playbook rocket.yaml
        ```
        Now go to the project and click on **“Build Now”** to deploy.

        Once deployment done through Jenkins, login to EC2 instance and run the below command in CLI to cross check the status of the containers.
        ```
        # ssh -i <key> ec2-user@<Public IP of EC2 Instance>

        # docker ps

        # docker logs -f <Container ID>
        ```
    Now you can open a browser and type **http://< EC2 Public IP or Public DNS>** to access the Rocket Chat Application.

6.	**Delete Environment**

    Do the following task to clean up all the Environment.

    1.	**Now create a freestyle project to delete all Rocket Chat related resources.**

        Go to new Item -> Select Freestyle Project -> Provide a name -> OK
        
        Now Open the project and Provide a description.
        > **Rocket Chat Docker deletion**
        
        In **Source Code Management** provide the **git repository URL**.

        > **https://github.com/tsingha/rocket-docker-ec2.git**

        In **Build** section choose the **Execute shell** and write down the command and click on **Save**.
        ```
        cd terraform
        cp ../../rocket-chat-docker-install/terraform/terraform.tfstate .
        terraform init
        terraform destroy -auto-approve
        ```
        Now go to the project and click on **“Build Now”** to deploy.

        Once the resources deletion done through Jenkins, you can check in Amazon Console and you won’t get any resources related to Rocket Chat EC2.

    2.	Now you can delete your client server where you installed aws cli, terraform, ansible and setup Jenkins server.

