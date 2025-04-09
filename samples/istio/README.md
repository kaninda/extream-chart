# Service Addons for Exstream with Istio

This directory contains sample Istio virtual services for applications which integrate with Exstream but are not a part 
of the standard Exstream chart installation.

The yaml files contain a placeholder host `<host.name>` and gateway `<gateway.name>`. Hostnames and ingress gateway usage are particular to your Istio environment.

The virtual services are intended as a reference only and should be configured properly to meet production needs.

## Getting started

To create the virtual services:

```
kubectl apply -f samples/istio/virtualservice-otds.yaml
```

```
kubectl apply -f samples/istio/virtualservice-rabbitmq.yaml
```

## Virtual Services

### OTDS

Creates a virtual service `otds` which matches incoming requests against the `/otds` prefix on `<host.name>` and routes to service name `exstreamecf-otdsws` on port `80`.

### RabbitMQ

Creates a virtual service `rabbitmq` which matches incoming requests against the `/rabbitmq` prefix on `<host.name>` and routes to service name `exstreamecf-rabbitmq` on port `15672`.