POD=$(kubectl get pods --selector=app=exstream-orchestration -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD 9999