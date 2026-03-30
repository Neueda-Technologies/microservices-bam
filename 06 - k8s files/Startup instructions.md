# Set up and deploy the microservices using Kubernetes on a linux server

## Step 1 - Install and configure Kubernetes:


```
reg_name='kind-registry'
reg_port='5001'

#install Kubernetes (Kind)
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

#install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl


#set up a local registry
docker run -d --restart=always -p "127.0.0.1:${reg_port}:5000"   --name "${reg_name}" registry:2

cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
EOF

#Add the registry config to the nodes

REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
for node in $(kind get nodes); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${reg_name}:5000"]
EOF
done

# Connect the registry to the cluster network if not already connected
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' kind-registry)" = 'null' ]; then
  docker network connect "kind" kind-registry
fi

# Document the local registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
```

## Step 2 - clone the repo
```
git clone https://github.com/Neueda-Technologies/microservices-bam.git
cd microservices-bam/06\ -\ k8s\ files/
```

## Step 3 - build and run the database

Navigate into the folder and build the docker image
```
cd database
docker build -t localhost:5001/bam-db:1.0 --build-arg DBPASSWORD=pass123! .
```

Push the docker image to the Kubernetes repository
```
docker push localhost:5001/bam-db:1.0
```

Deploy the application
```
kubectl apply -f deploy.yaml
```

Wait for the pod to become ready / watch the logs:
```
watch kubectl get po
```
and/or
```
kubectl logs -f deploy/bam-db
```

## Step 4 - build and run the messaging server
```
cd ..
cd activeMQ/
docker build -t localhost:5001/bam-activemq:1.0 .
docker push localhost:5001/bam-activemq:1.0
kubectl apply -f deploy.yaml
```


Wait for the pod to become ready / watch the logs:
```
watch kubectl get po
```
and/or
```
kubectl logs -f deploy/bam-activemq
```

## Step 5 - build and run the api gateway
```
cd ..
cd apigateway/
chmod a+x mvnw
./mvnw package
docker build -t localhost:5001/bam-apigateway:1.0 .
docker push localhost:5001/bam-apigateway:1.0
kubectl apply -f deploy.yaml
```

Because this needs to be visible outside the cluster we can first port forward and then test it with:
```
kubectl port-forward svc/bam-apigateway 8100:8080 --address 0.0.0.0 &
```
```
curl -i localhost:8100/healthz
```

Now you can visit the url in your browser (http://your-server-name:8100/healthz)

Note: this sets port forwarding to work in the background. To stop it, run the command `jobs` to get the id of the job and then `fg 1` for job number 1 to bring it into the foreground. You can then press ctrl+c to stop the job running. 

## Step 6 - build and run the user manager
```
cd ..
cd usermanager
chmod a+x mvnw
./mvnw package
docker build -t localhost:5001/bam-user:1.0 --build-arg DBPASSWORD=pass123! .
docker push localhost:5001/bam-user:1.0 
kubectl apply -f deploy.yaml
```

## Step 7 - build and run the building manager
```
cd ..
cd buildingmanager
chmod a+x mvnw
./mvnw package
docker build -t localhost:5001/bam-building:1.0 --build-arg DBPASSWORD=pass123! .
docker push localhost:5001/bam-building:1.0 
kubectl apply -f deploy.yaml
```

## Step 8 - build and run the access control application
```
cd ..
cd accesscontrol
chmod a+x mvnw
./mvnw package
docker build -t localhost:5001/bam-access:1.0 --build-arg DBPASSWORD=pass123! .
docker push localhost:5001/bam-access:1.0 
kubectl apply -f deploy.yaml
```

## Step 9 - build and run the front end

```
cd ..
cd bam-ui
nvm install node
npm install
```

Next we need to edit the files in the `src/data` folder to set the URL of the api gateway.

```
grep -rl "http://localhost:8080" src/data | xargs sed -i "s#http://localhost:8080#http://$(curl -s ifconfig.me):8100#g"
```

Now we can continue the build process:

```
npm run build
docker build -t localhost:5001/bam-ui:1.0  .
docker push localhost:5001/bam-ui:1.0
kubectl apply -f deploy.yaml
```

Because this needs to be visible outside the cluster we can first port forward and then test it with:
```
kubectl port-forward svc/bam-ui 8081:80 --address 0.0.0.0 &
curl -i localhost:8081
```

Now you can visit the url in your browser (http://your-server-name:8081)

Note: this sets port forwarding to work in the background. To stop it, run the command `jobs` to get the id of the job and then `fg 1` for job number 1 to bring it into the foreground. You can then press ctrl+c to stop the job running. 

