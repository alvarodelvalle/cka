# kubectl commands
kubectl apply -f azure-vote-all-in-one-redis.yaml
kubectl get service azure-vote-front --watch
kubectl scale --replicas=5 deployment/azure-vote-front
kubectl get all # deployments, replica sets, pods

# 'run'
## no generator, will create a deployment
kubectl run <pod-name> --image=<container-image> # can apply -o yaml and/or `> filename.yml`
## Create an NGINX Pod
kubectl run --generator=run-pod/v1 nginx --image=nginx
## Generate POD manifest YAML file
kubectl run --generator=run-pod/v1 nginx --image=nginx -o yaml
## Generate POD with labels
kubectl run --generator=run-pod/v1 redis --image=redis:alpine -l tier=db
## Create a deployment and save it to a file
kubectl run --generator=deployment/v1beta1 nginx --image=nginx --replicas=4 -o yaml > file-name.yml
kubectl run --generator=deployment/v1beta1 httpd --image=httpd:2.4-alpine --replicas=3 -o yaml

# deployments
kubectl create -f deployment-file.yml
kubectl get deployments
kubectl expose deployment webapp --type=NodePort --port=8080 --name=webapp-service --dry-run -o yaml > webapp-service.yaml
kubectl edit deployment deployment_name # make note of the /tmp/filename to run apply after edits

# replicas set
kubectl create -f replicas-def.yml
kubectl get replicaset
kubectl replace -f replicas-def.yml # after updating number of replicase
kubectl delete replicaset myapp-replicaset # also deletes underlying pods
kubectl scale -replicas=6 -f replicas-def.yml # scale without modifying the file
kubectl edit replicaset new-replica-set # to make modifications to replica set
kubectl get rs name-of-rs -o yaml

# pods
kubectl describe pod webapp
kubectl delete pod webapp
kubectl get pods -o wide
kubectl get pods --selector app=app1

# namespaces
kubectl get pods # gets pods in the `default` ns
kubectl get pods --namespace=kube-system # get pods in named ns
kubectl create -f file-def.yml
kubectl create namespace dev
## setting context to a specific namespace
kubectl config set-context $(kubectl config current-context) --namespace=dev
kubectl get pods --all-namespaces

# services
kubectl create -f service-def.yml
kubectl get services
## Create a Service named redis-service of type ClusterIP to expose pod redis on port 6379
kubectl expose pod redis --port=6379 --name redis-service --dry-run -o yaml
kubectl create service clusterip redis --tcp=6379:6379 --dry-run -o yaml # assumes selector: app=redis; cannot pass selectors as option

# Create a Service named nginx of type NodePort to expose pod nginx's port 80 on port 30080 on the nodes:
kubectl expose pod nginx --port=80 --name nginx-service --dry-run -o yaml

# set autoscale
kubectl autoscale deployment azure-vote-front --cpu-percent=50 --min=3 --max=10

# see running pods per autoscale
kubectl get hpa
kubectl set image deployment azure-vote-front azure-vote-front=alvaroregistry.azurecr.io/azure-vote-front:v2
kubectl config unset clusters.varsAKSCluster
kubectl config unset contexts.varsAKSCluster
kubectl config unset users.clusterUser_TestResourceGroup_varsAKSCluster

# imperative commands using selectors
kubectl get pod --selector env=prod --selector bu=finance
kubectl get pods --selector app=app1

# taints and tolerations
kubectl taint nodes node-name key=value:taint-effect # NoSchedule | PreferNoSchedule | NoExecute
kubectl taint nodes node1 app=blue1:NoSchedule
kubectl describe node kubemaster | grep Taint

# node selectors
kubectl label nodes node-name labelkey=labelvalue

# logs
kubectl logs scheduler-name --name-space=kube-system
kubectl logs -f pod_name
kubectl logs -f pod_name container_name # if a pod definition with mulitple container names

# monitor cluster components
kubectl top node
kubectl top pod

# rollout
kubectl rollout status deployment/deployment_name
kubectl rollout history deployment/deployment_name
kubectl rollout undo deployment/deployment_name

# configmap
kubectl create configmap --from-literal=key=value --from-literal=key=value
kubectl create configmap config_name --from-file=path_to_file
kubectl get configmaps
kubectl describe configmaps

# secrets
kubectl create secret generic secret_name --from-literal=KEY=VALUE
kubectl create secret generic secret_name --from-file=filename.properties
kubectl get secrets
kubectl describe secrets

# os upgrades
kubectl drain node-name
kubectl uncordon node-name # make node schedulable
kubectl cordon node-name # marks node unschedulable

# upgrading the cluster
## master node
apt install kubeadm=1.12.0-00 # upgrade kubeadm first always
kubeadm upgrade apply v1.12.0 # upgrade cluster components
apt install kubelet=1.12.0-00 # upgrade the kubelet on the master node
## worker node
kubeadm upgrade node config --kubelet-version $(kubelet --version | cut -d ' ' -f 2)
systemctl restart kubelet

# backup and restore
kubectl get all -all-namespaces -o yaml > all-definition.yaml
## etcd
etcd.service config file --data-dir=/var/lib/etcd # backup this directory
etcdctl snapshot save etcd-snapshot.db
kubectl describe pod etcd-master -n kube-system
kubectl logs etcd-master -n kube-system

# certificates
## generate keys
openssl genrsa -out ca.key 2048
## certificate signing request
openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA" -out ca.csr
## sign certificate
openssl x509 -req -in ca.csr -signkey ca.key -out ca.crt

## keys for a user, run commands as above except for request
openssl req -new -key ca.key -subj "/CN=kube-admin/O=system:masters" -out ca.csr # must add user to group
