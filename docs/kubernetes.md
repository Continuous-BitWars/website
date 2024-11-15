Kubernetes
==========

Here are some useful commands to interact with your Kubernetes pods with `kubectl`.

You can export your `kubeconfig` as environment variable, so you don't have to specify the `--kubeconfig` flag every time.

```sh
# Bash, Zsh
export KUBECONFIG=path-to-kubeconfig.yaml
# Fish
set -x KUBECONFIG path-to-kubeconfig.yaml
```

See your basic stats about your running pods:

```sh
kubectl -n NAMESPACE get pods
```

Show the logs of your pod:

```sh
kubectl -n NAMESPACE logs -f DEPLOYMENT_NAME
```

Get your configuration options:

```sh
kubectl -n NAMESPACE get deployment DEPLOYMENT_NAME -o yaml
```

Get information about your replica set (`rs`) with detailed information (`-o wide`).

```sh
kubectl -n NAMESPACE get rs -o wide
```

## Deleting a Pod Or Your Deployment

You'll probably not need this.

Delete a single pod by first settings its replicas to zero and then deleting it.

```sh
# first scale it down
kubectl -n NAMESPACE scale deployment <deployment_name> --replicas=0
kubectl -n NAMESPACE delete pods <pod_name>
```

Alternatively, you could delete the whole deployment.

```sh
kubectl -n NAMESPACE get deployments
kubectl -n NAMESPACE delete deployment DEPLOYMENT_NAME
```

