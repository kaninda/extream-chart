POD=$(kubectl get pods --selector=app=rabbitmq-ha -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD 15672