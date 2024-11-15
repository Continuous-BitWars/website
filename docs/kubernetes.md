# Kubernetes

Here are some useful commands to interact with your Kubernetes pods with `kubectl`.

## Alias `kubectl` And Type Less

You can export the path to your `kubeconfig` as environment variable,
so you don't have to specify the `--kubeconfig` flag every time.

```sh
# Bash, Zsh
export KUBECONFIG=path/to/kubeconfig.yaml
# Fish
set -x KUBECONFIG path/to/kubeconfig.yaml
```

Additionally, you can alias the `kubectl` command to include your namespace.
You could only specify the configuration file this way.

```sh
alias kubectl='kubectl -n NAMESPACE'
# or 
alias kubectl='kubectl -n NAMESPACE --kubeconfig=path/to/your/kubeconfig.yaml'
```

The following commands assume that the namespace with `-n` and the kubeconfig with `--kubeconfig` is set.

## Show Logs of Your Current Pod

See your basic stats about your running pods:

```sh
$ kubectl get pods
NAME                             READY   STATUS    RESTARTS   AGE
test-player-5cff749fd7-lrtv5     1/1     Running   0          9h
```

Show and follow the logs of your pod:

```sh
kubectl logs -f test-player-5cff749fd7-lrtv5
```

Get your configuration options:

```sh
kubectl get deployment test-player -o yaml
```

Get information about your replica set (`rs`) with detailed information (`-o wide`).

```sh
kubectl get rs -o wide
```

## Deleting a Pod Or Your Deployment

Most likely you will not need this.

Delete a single pod by first settings its replicas to zero and then deleting it.
The `DEPLOYMENT_NAME` is your team name prefixed to `-player` (you set that in GitHub as variable `TEAMNAME`).

**Example:**
Your team name is `test-team`, then the deployment name is `test-team-player`.
You can also get your current deployments with `kubectl get deployments`.

```sh
# first scale it down
kubectl scale deployment DEPLOYMENT_NAME --replicas=0
# get the name with: kubectl get pods
kubectl delete pods POD_NAME
```

Alternatively, you could delete the whole deployment.

```sh
kubectl get deployments
kubectl delete deployment DEPLOYMENT_NAME
```
