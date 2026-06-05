# Lab: Setting up a Jenkins CI/CD Pipeline

## What you'll learn

In this lab you will set up a Jenkins pipeline that automatically builds, tests, and deploys a microservice to your Kubernetes cluster. By the end you will understand:

- How Jenkins connects to your source code repository
- How credentials (passwords, config files) are stored securely in Jenkins
- How a Jenkinsfile defines the stages of a CI/CD pipeline
- How to trigger a build and verify the deployment

## Prerequisites

Before starting this lab, make sure you have:

- The microservices application deployed and running (completed the k8s deployment from `06 - k8s files`)
- Kubernetes cluster running — verify with `kubectl get nodes`
- Docker running — verify with `docker ps`
- The local Docker registry running on port 5001 — verify with `curl -s http://localhost:5001/v2/_catalog`
- Jenkins installed on your Linux server

## Step 1 — Start Jenkins

From the Linux command line, start Jenkins:

```bash
sudo systemctl start jenkins
```

Verify it's running:

```bash
sudo systemctl status jenkins
```

You should see `active (running)` in the output. If not, ask your instructor for help.

## Step 2 — Log in to Jenkins

1. Open a browser and go to `http://<your-linux-server-ip>:8080`
2. Log in with username `admin` and the password provided by your instructor

You should see the Jenkins dashboard.

## Step 3 — Store the database password in Jenkins

Passwords should never be hardcoded in source files. Jenkins has a built-in credentials store that lets us securely pass secrets to our pipeline at build time.

1. Click the **Manage Jenkins** icon (gear/cog) in the left sidebar
2. In the **Security** section, click **Credentials**
3. Click **(global)** in the Domains column
4. Click the **+ Add Credentials** button
5. Fill in the form:
   - **Kind:** Secret text
   - **Scope:** Global
   - **Secret:** `pass123!` (your database password)
   - **ID:** `DBPASSWORD`
6. Click **Create**

## Step 4 — Store the Kubernetes config in Jenkins

Jenkins needs access to your Kubernetes cluster to deploy containers. We'll upload your kubeconfig file as a credential.

1. In your terminal, run:

```bash
cat ~/.kube/config
```

2. Copy the entire output and save it to a file called `kubeconfig.txt` on your local machine
3. Back in Jenkins, go to **Manage Jenkins** > **Credentials** > **(global)** > **+ Add Credentials**
4. Fill in the form:
   - **Kind:** Secret file
   - **File:** upload `kubeconfig.txt`
   - **ID:** `kubeconfig`
5. Click **Create**

## Step 5 — Create the pipeline

Now we'll create a pipeline job that points to the Jenkinsfile in our repository.

1. Click the **Jenkins** logo (top left) to go to the dashboard
2. Click **New Item** (or "Create a job")
3. Enter the name `bam-building`, select **Pipeline**, and click **OK**
4. Scroll down to the **Pipeline** section
5. Change **Definition** to `Pipeline script from SCM`
6. Set **SCM** to `Git`
7. Set **Repository URL** to `https://github.com/Neueda-Technologies/microservices-bam`
8. Under **Branches to build**, set to `main`
9. Set **Script Path** to `07 - jenkins files/bam-building-jenkinsfile`
10. Click **Save**

**What just happened?** You told Jenkins: "When I trigger a build, pull the code from this Git repo, find the Jenkinsfile at this path, and execute the pipeline defined in it."

## Step 6 — Understand the Jenkinsfile

Before running the pipeline, take a moment to read through the Jenkinsfile at `07 - jenkins files/bam-building-jenkinsfile`. It defines these stages:

| Stage | What it does |
|-------|-------------|
| **GetFromGithub** | Pulls the latest code from the `main` branch |
| **Ensure Maven is runnable** | Makes the Maven wrapper script executable |
| **Maven Unit tests** | Runs the unit tests — the build fails here if any test fails |
| **Maven build** | Compiles the application and packages it as a JAR |
| **Docker image build** | Builds a Docker image tagged with the Jenkins build number |
| **Load docker image into k8s cluster** | Pushes the image to the local Docker registry |
| **Update k8s deployment** | Tells Kubernetes to update the running pod to use the new image |

## Step 7 — Run the pipeline

We'll simulate a deployment — the pipeline will pull the latest code, build a new Docker image, and deploy it.

**Tip:** Open a second terminal and run this to watch pods update in real time:

```bash
watch kubectl get po
```

1. In Jenkins, click **Build Now** in the left menu
2. A new build will appear under **Build History** (bottom left) — click the build number (e.g. `#1`)
3. Click **Console Output** in the left menu to watch the logs

Wait for the build to complete. You should see `Finished: SUCCESS` at the bottom.

If the build fails, check the console output for the error message — see the **Troubleshooting** section below.

## Step 8 — Verify the deployment

1. Check the running pods:

```bash
kubectl get po
```

2. Describe the pod to see which image version it's running:

```bash
kubectl describe po <pod-name> | grep Image:
```

The image tag should match the Jenkins build number (e.g. `bam-building:1`).

3. **Run the pipeline again** (click Build Now). After it completes, describe the pod again — the image tag should now be `bam-building:2`.

This demonstrates the CI/CD cycle: every time you trigger a build, a new version is built, tested, and deployed automatically.

## Troubleshooting

| Problem | Likely cause | Fix |
|---------|-------------|-----|
| Jenkins won't start | Service not installed or port 8080 in use | Run `sudo systemctl status jenkins` to check. If port conflict, check with `sudo lsof -i :8080` |
| "Permission denied" on mvnw | File not executable | The pipeline handles this, but you can manually run `chmod a+x mvnw` |
| Maven build fails | Missing dependencies or test failure | Read the console output — look for `BUILD FAILURE` and the error above it |
| Docker build fails | Docker daemon not running | Run `sudo systemctl start docker` |
| Docker push fails | Local registry not running on port 5001 | Verify with `curl http://localhost:5001/v2/_catalog` |
| kubectl fails | Kubeconfig credential missing or incorrect | Re-do Step 4 and make sure the ID is exactly `kubeconfig` |
| Pod stays in CrashLoopBackOff | Database not running or wrong password | Check DB is up with `docker ps`, verify the DBPASSWORD credential matches |
