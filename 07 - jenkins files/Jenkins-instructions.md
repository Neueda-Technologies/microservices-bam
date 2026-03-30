# Set up a Jenkins CI pipeline

## Step 1 -Log onto Jenkins

1. Visit http://your-linux-server:8080 
2. Log in with the username admin and the password that we use for the Windows VMs.

## Step 2 - configure the database password in Jenkins

We don't want to store passwords in our files so we'll safely store this in Jenkins 

1. Click on the "manage Jenkins" cog icon at the top right of the screen
2. In the "Security" section click on "Configure credentials"
3. Click on "(global)" in the domains column
4. Click on the "+ Add Credentials" button
5. Set the Kind to "Secret text"
6. Set the Scope to "Global"
7. Set the Secret to the password for your database
8. Set the id to "DBPASSWORD"
9. Click on the "Create" button

## Step 3 - configure kubernetes in Jenkins

1. run the command cat ~/.kube/config
2. copy and paste the output and save it as a local file called kubeconfig.txt
3. Click on the "manage Jenkins" cog icon at the top right of the screen
4. In the "Security" section click on "Configure credentials"
5. Click on "(global)" in the domains column
6. Click on the "+ Add Credentials" button
7. Set the Kind to "Secret file"
8. Upload the file
9. give it a name of kubeconfig
10. click on create

## Step 4 - create a pipeline

1. Click on the Jenkins icon at the top left to get to the home page.
2. Click on "Create a job"
3. Give the job the name "bam-building" and choose "Pipeline" as the item type, then click on OK
4. Scroll down to the Pipeline section and change the Definition to "Pipeline script from SCM"
5. Set the SCM to "Git"
6. Set the repository URL to "https://github.com/Neueda-Technologies/microservices-bam"
7. Scroll down to the Branches to build section and set this to "main"
8. Scroll down to the Script Path and set this to "07 - jenkins files/bam-building-jenkinsfile"
9. Leave all other settings at the default and click on Save

## Step 5 - run the pipeline

1. Click on the Build now button on the left menu

Then to watch the logs:

2. Click on the timestamp for the build id in the builds window below the left menu
3. Click on console output from the left menu

## Step 6 - deploy the change

NOTE - before starting this section you may wish to run `watch kubectl get po` to see the new container being deployed

### get the tag number for the latest image for bam building

`docker image ls`

### implement the changed image:

`kubectl set image deployment/bam-building bam-building=bam-building:3`