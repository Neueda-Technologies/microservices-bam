# Deploy the microservices on a linux server

## Step 1 - clone the repo
```
git clone https://github.com/vppmatt/microservices-bam.git
cd microservices-bam/03\ -\ docker\ versions/
```

## Step 2 - build and run the database
```
cd database
docker build -t bam-db:1.0 --build-arg DBPASSWORD=pass123! .
docker network create bam
docker run -d --name bam-db --network bam bam-db:1.0
```

## Step 3 - build and run the messaging server
```
cd ..
cd activeMQ/
docker build -t bam-activemq:1.0 .
docker run -d --name bam-activemq --network bam bam-activemq:1.0
```

## Step 4 - build and run the api gateway
```
cd ..
cd apigateway/
chmod a+x mvnw
./mvnw package
docker build -t bam-apigateway:1.0 .
docker run -d --name bam-apigateway -p8081:8080  --network bam bam-apigateway:1.0
```

## Step 5 - build and run the user manager
```
cd ..
cd usermanager
chmod a+x mvnw
./mvnw package
docker build -t bam-user:1.0 --build-arg DBPASSWORD=pass123! .
docker run -d --name bam-user --network bam bam-user:1.0
```

## Step 6 - build and run the building manager
```
cd ..
cd buildingmanager
chmod a+x mvnw
./mvnw package
docker build -t bam-building:1.0 --build-arg DBPASSWORD=pass123! .
docker run -d --name bam-building --network bam bam-building:1.0
```

# Step 7 - build and run the access control server
```
cd ..
cd accesscontrol
chmod a+x mvnw
./mvnw package
docker build -t bam-access:1.0 --build-arg DBPASSWORD=pass123! .
docker run -d --name bam-access --network bam bam-access:1.0
```

# Step 8 - build and run the front end

```
cd ..
cd bam-ui
nvm install --lts
npm install
```

Next we need to edit the files in the `src/data` folder to set the URL of the api gateway. For example if your linux server is called server1.neueda.com, set this line in each of the files:

`const serverUrl = "http://server1.neueda.com:8081"`

**take care to change the port number not just the domain name**

You can try running this command to automate this:

```
grep -rl "http://localhost:8080" src/data | xargs sed -i "s#http://localhost:8080#http://$(curl -s ifconfig.me):8100#g"
```

Or edit the files manually!


Then we can continue the process:
```
npm run build
docker build -t bam-ui:1.0  .
docker run -d --name bam-ui --network bam -p8100:80 bam-ui:1.0
```

## Step 9 - test
Visit the url - we have exposed port 8100, so if your server is server1.neueda.com, then visit:

http://server1.neueda.com:8100
