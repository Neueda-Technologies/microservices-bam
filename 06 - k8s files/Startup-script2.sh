#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

HOST_IP="$(hostname -I | awk '{print $1}')"

cd database
docker build -t bam-db:1.0 --build-arg DBPASSWORD='pass123!' .
docker run --restart=always -d -p3306:3306 bam-db:1.0

cd "$SCRIPT_DIR"
cd activeMQ/
docker build -t localhost:5001/bam-activemq:1.0 .
docker push localhost:5001/bam-activemq:1.0
kubectl apply -f deploy.yaml

cd "$SCRIPT_DIR"
cd apigateway/
chmod a+x mvnw
./mvnw package
docker build -t localhost:5001/bam-apigateway:1.0 .
docker push localhost:5001/bam-apigateway:1.0
kubectl apply -f deploy.yaml

cd "$SCRIPT_DIR"
cd usermanager
chmod a+x mvnw
./mvnw package
docker build -t localhost:5001/bam-user:1.0 --build-arg DBPASSWORD='pass123!' --build-arg DBHOSTNAME="$(hostname)" .
docker push localhost:5001/bam-user:1.0
kubectl apply -f deploy.yaml

cd "$SCRIPT_DIR"
cd buildingmanager
chmod a+x mvnw
./mvnw package
docker build -t localhost:5001/bam-building:1.0 --build-arg DBPASSWORD='pass123!' --build-arg DBHOSTNAME="$(hostname)" .
docker push localhost:5001/bam-building:1.0
kubectl apply -f deploy.yaml

cd "$SCRIPT_DIR"
cd accesscontrol
chmod a+x mvnw
./mvnw package
docker build -t localhost:5001/bam-access:1.0 --build-arg DBPASSWORD='pass123!' --build-arg DBHOSTNAME="$(hostname)" .
docker push localhost:5001/bam-access:1.0
kubectl apply -f deploy.yaml

cd "$SCRIPT_DIR"
cd bam-ui
npm install

sed -i "s#http://localhost:8080#http://${HOST_IP}:8081#g" src/data/accessRestFunctions.js src/data/buildingRestFunctions.js src/data/userRestFunctions.js

npm run build
docker build -t localhost:5001/bam-ui:1.0 .
docker push localhost:5001/bam-ui:1.0
kubectl apply -f deploy.yaml

echo "Setup complete"

kubectl port-forward svc/bam-ui 8100:80 --address 0.0.0.0 &
kubectl port-forward svc/bam-apigateway 8081:8080 --address 0.0.0.0 &
