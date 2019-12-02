#!/usr/bin/env bash

KOPS_VER=`curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4`
curl -LO https://github.com/kubernetes/kops/releases/download/$KOPS_VER/kops-linux-amd64
chmod +x kops-linux-amd64
sudo mv kops-linux-amd64 /usr/local/bin/kops

bucket_name=omerls-for-capitolis

export KOPS_CLUSTER_NAME=omerls-for-capitolis.k8s.local
export KOPS_STATE_STORE=s3://${bucket_name}


aws s3api create-bucket \
    --bucket ${bucket_name} \
    --region us-east-1

aws s3api put-bucket-versioning \
    --bucket ${bucket_name} \
    --versioning-configuration \
    Status=Enabled

kops create cluster \
    --node-count=2 \
    --node-size=t2.micro \
    --zones=us-east-1a \
    --name=${KOPS_CLUSTER_NAME}

# kops edit cluster --name ${KOPS_CLUSTER_NAME}
kops update cluster --name ${KOPS_CLUSTER_NAME} --yes
# ADD wait command for cluster to spin up

ELB_IP=18.213.220.155


#ip-172.20.57.77.ec2.internal    master  True
#ip-172.20.42.56.ec2.internal    node    True
#ip-172.20.50.6.ec2.internal     node    True

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl proxy &

kubectl create -f zk-service.yml
kubectl create -f zk-deployment.yml

kubectl create -f kafka-deployment.yml
kubectl create -f kafka-service.yml

kubectl create -f admin_user.yml
# Get main cluster endpoint
kubectl cluster-info
# get AWS endpoint and redirect it to kubernetes.livne.me
# http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/



# Admin User Password
kops get secrets kube --type secret -oplaintext
# Admin Service Account
kops get secrets admin --type secret -oplaintext


kubectl get pod kafka-broker0
