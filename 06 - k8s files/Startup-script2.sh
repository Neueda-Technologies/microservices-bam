cd microservices-bam/06\ -\ k8s\ files/

cd database
#docker build -t localhost:5001/bam-db:1.0 --build-arg DBPASSWORD=pass123! .
#docker push localhost:5001/bam-db:1.0
#kubectl apply -f deploy.yaml
docker build -t bam-db:1.0 --build-arg DBPASSWORD=pass123! .
docker run --restart=always -d -p3306:3306 bam-db:1.0

cd ..
cd activeMQ/
docker build -t localhost:5001/bam-activemq:1.0 .
docker push localhost:5001/bam-activemq:1.0
kubectl apply -f deploy.yaml

cd ..
cd apigateway/
chmod a+x mvnw
./mvnw package
docker build -t localhost:5001/bam-apigateway:1.0 .
docker push localhost:5001/bam-apigateway:1.0
kubectl apply -f deploy.yaml

cd ..
cd usermanager
chmod a+x mvnw
./mvnw package
docker build -t localhost:5001/bam-user:1.0 --build-arg DBPASSWORD=pass123! --build-arg DBHOSTNAME="$(hostname)" .
docker push localhost:5001/bam-user:1.0 
kubectl apply -f deploy.yaml

cd ..
cd buildingmanager
chmod a+x mvnw
./mvnw package
docker build -t localhost:5001/bam-building:1.0 --build-arg DBPASSWORD=pass123! --build-arg DBHOSTNAME="$(hostname)" .
docker push localhost:5001/bam-building:1.0 
kubectl apply -f deploy.yaml

cd ..
cd accesscontrol
chmod a+x mvnw
./mvnw package
docker build -t localhost:5001/bam-access:1.0 --build-arg DBPASSWORD=pass123! --build-arg DBHOSTNAME="$(hostname)" .
docker push localhost:5001/bam-access:1.0 
kubectl apply -f deploy.yaml

cd ..
cd bam-ui
nvm install node
npm install

grep -rl "http://localhost:8080" src/data | xargs sed -i "s#http://localhost:8080#http://$(curl -s ifconfig.me):8081#g"

npm run build
docker build -t localhost:5001/bam-ui:1.0  .
docker push localhost:5001/bam-ui:1.0
kubectl apply -f deploy.yaml

echo "Setup complete"

#kubectl port-forward svc/bam-ui 8081:80 --address 0.0.0.0 &
#kubectl port-forward svc/bam-apigateway 8100:8080 --address 0.0.0.0 &


