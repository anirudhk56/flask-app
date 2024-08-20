Ip- 18.233.105.154:32575(Currently instance is stopped)

Docker File For Flask-app.

# Use an official Python runtime as a parent image
FROM python:3.8-slim

# Set environment variables
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_RUN_PORT=5000

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container at /app
COPY requirement.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirement.txt

# Copy the current directory contents into the container at /app
COPY . .

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Define environment variable
ENV MONGODB_URI=mongodb://localhost:27017/

# Run app.py when the container launches
CMD ["flask", "run","--host=0.0.0.0" ]

******************************************************************************************************************************************
How to build and push the Docker image to a container registry?


Once we have created the Dockerfile, we have to Build the docker file to create the images and run to make docker images run 

Docker Build Command.
docker build -t flask-app .

Docker Run Command.
docker run -d -p 5000:5000 flask-app

Now to push this docker image to Docker Hub

Docker Login we should give our credentials
docker login


First tag the image with the your docker hub name 
docker tag flask-app:latest anirudh588/flask-app:latest

Docker Push
docker push anirudh588/flask-app:latest


********************************************************************************************************************************************

Kubernetes YAML files


flask-deployment.yaml.

apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flask-app
  template:
    metadata:
      labels:
        app: flask-app
    spec:
      containers:
      - name:  flask-app
        image: anirudh588/flask-app  # Replace with your Docker image
        ports:
        - containerPort: 5000
        env:
        - name: MONGODB_URI
          value: "mongodb://54.242.11.229:27017/"  # Update with your MongoDB URI
        resources:
          requests:
            cpu: "0.2"
            memory: "250Mi"
          limits:
            cpu: "0.5"
            memory: "500Mi"

flask-service.yaml

apiVersion: v1
kind: Service
metadata:
  name: flask-service
spec:
  selector:
    app: flask-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
  type: NodePort

mongo-statefulset.yaml

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb
spec:
  serviceName: "mongodb"
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:latest
        ports:
        - containerPort: 27017
        volumeMounts:
        - name: mongodb-data
          mountPath: /data/db
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          value: "root"
        - name: MONGO_INITDB_ROOT_PASSWORD
          value: "root-password"
        - name: MONGO_INITDB_DATABASE
          value: "your-database"

mongobd-service.yaml

apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
spec:
  selector:
    app: mongodb
  ports:
    - protocol: TCP
      port: 27017
  type: ClusterIP



mongodb-pv.yaml

apiVersion: v1
kind: PersistentVolume
metadata:
  name: mongodb-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data/mongodb

mongodb-pvc.yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi


flask-hpa.yaml

apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: flask-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: flask-app
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70





***************************************************************************************************************************************************
Detailed steps to deploy the Flask application and MongoDB on a Minikube Kubernetes cluster.(Used K3s instead of minikube)

Installing K3s And Kubectl
Kubectl

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

kubectl version --client

K3s

curl -sfL https://get.k3s.io | sh -

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

sudo systemctl status k3s

kubectl get nodes


Apply all creates Kubernetes configuration file

kubectl apply -f mongo-statefulset.yaml
kubectl apply -f mongo-service.yaml
kubectl apply -f flask-deployment.yaml
kubectl apply -f flask-service.yaml
kubectl apply -f hpa.yaml

Access the Application

kubectl get svc flask-service

******************************************************************************************************************************************************************
Includeanexplanation of how DNS resolution works within the Kubernetes cluster for inter-pod communication.

In Kubernetes cluster, DNS resolution is handled by CoreDNS, which is responsible for translating names into IP addresses for services and pods. When a pod wants to communicate with another pod or service, it sends a DNS query to CoreDNS. CoreDNS then translates service names like flask-service.default.svc.cluster.local into the service's cluster IP, which forwards the request to the appropriate pods. For direct pod-to-pod communication, Kubernetes uses DNS names in the format <pod-ip>.<namespace>.pod.cluster.local. Additionally, headless services can expose individual pod IPs directly. This DNS-based approach ensures smooth and reliable communication between pods, making it easier to manage service discovery and interactions within the cluster.


*******************************************************************************************************************************************************************
Includeanexplanation of resource requests and limits in Kubernetes.

In Kubernetes, managing CPU and memory for containers involves setting resource requests and limits. Resource requests indicate the minimum amount of CPU and memory a container needs, helping Kubernetes decide where to place pods so they get the resources they require. For example, a container might request 500m of CPU and 256Mi of memory. Resource limits, however, set a cap on how much CPU and memory a container can use, preventing it from hogging resources and impacting other containers. So, if a container has a CPU limit of 1 and a memory limit of 512Mi, it won’t be allowed to exceed these amounts. By using both requests and limits, Kubernetes ensures that resources are used efficiently and that all containers have a fair share, maintaining overall cluster stability.


*********************************************************************************************************************************************************************

 DesignChoices:

I used K3s instead of minikube because my machine didn't have enough space for minikube(20gb ideal) . K3s is lightweight 

Deployed with 2 replicas
Running multiple replicas ensures high availability and load balancing, which improves the reliability and performance of the application. If one pod fails, others can continue serving requests.
Alternative: Could use a single replica for simplicity, but this would be less resilient to failures and may not handle traffic spikes effectively.

NodePort service
Exposes the Flask application to external traffic. NodePort is straightforward and allows access to the application from outside the cluster.
Alternative: LoadBalancer service could be used for a more production-ready setup, providing a public IP and load balancing, but it may be more complex and costly, especially in local environments or on some cloud providers. And also this was not production level project.


***********************************************************************************************************************************************************************

Cookie Points: Can you explain the benefits of using a virtual environment for python applications

Isolation: They keep dependencies separate for each project, preventing conflicts and ensuring that each project has the exact versions of libraries it needs.

Version Control: They allow you to specify and lock exact versions of packages, maintaining consistency and avoiding issues from updates.

Clean Setup: They provide a clean workspace with only the libraries you install, avoiding clutter and potential conflicts.

Reproducibility: They make it easy to recreate the same environment on different machines, ensuring consistent behavior across development and production setups.



***************************************************************************************************************************************************************************

Cookiepoint: Testing Scenarios: Detail how you tested autoscaling and database interactions, including simulating high traffic. Provide
results and any issues encountered during testing


1. Autoscaling Testing

Scenario: Simulate high traffic to test the autoscaling of the Flask application.

Setup: Configured Horizontal Pod Autoscaler (HPA) to scale the Flask application based on CPU usage.
Monitoring: Monitored CPU usage and HPA metrics using Kubernetes Dashboard and kubectl top pods to ensure scaling triggers correctly.
Results:

Successful Scaling: Observed the HPA scaling up the number of pods as CPU usage exceeded 70%, with the application scaling from 2 to 5 replicas.
Response Times: Initial response times were stable, but as load increased, some latency was observed, which improved after additional pods were deployed.
Issues: Encountered some delay in scaling actions, likely due to the time required for new pods to start and stabilize.


2. Database Interaction Testing

Scenario: Test interactions between the Flask application and MongoDB under normal and high-load conditions.

Setup: Deployed MongoDB with authentication and configured the Flask application to use it.
Load Testing: Simulated traffic to the /data endpoint, performing both read and write operations.
Monitoring: Monitored MongoDB performance metrics using mongostat and mongotop to assess impact under load.
Results:

Data Handling: Both read and write operations were successful under normal traffic conditions. MongoDB handled the requests effectively with acceptable performance.
High Load Impact: Under high load, write operations experienced some delays, but MongoDB continued to function. Read operations were less impacted.
Issues: Noted increased latency for write operations under heavy load, suggesting a potential need for optimization or scaling of MongoDB.
