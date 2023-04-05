# time-based-autoscaler
Autoscale kubernetes deployment at scheduled time

Some workloads/jobs run on cron schedule. As a result, we need to scale up the deployment for downstream dependencies prior to these jobs start executing. 

The effect of HPA might take sometime to take effect as a scale out of a deployment might result in cluster autoscaler. 

So this is a poor man's time-based autoscaling solution using Kubernetes CronJob. I call this a Poor man's version because projects like KEDA offer this functionality OOTB. 


## Usage
Install busybox deployment, hpa, scaleup and scaledown cronjobs. 

Cronjobs will require access to  Kubernetes APIServer to patch the hpa. 
Hence, we need to create the required serviceaccount.
```
$ make all
kubectl create namespace busybox || true
namespace/busybox created
kubectl apply -f busybox.yaml -n busybox
deployment.apps/busybox created
horizontalpodautoscaler.autoscaling/busybox created
kubectl apply -f rbac.yaml -n busybox
serviceaccount/kube-api-server-sa created
clusterrole.rbac.authorization.k8s.io/kube-api-server-cr unchanged
clusterrolebinding.rbac.authorization.k8s.io/kube-api-server-crb unchanged
kubectl apply -f scaleup-cronjob.yaml -n busybox
cronjob.batch/busybox-scale-up created
kubectl apply -f scaledown-cronjob.yaml -n busybox
cronjob.batch/busybox-scale-down created
```

```
$ kubectl get deployment -n busybox
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
busybox   1/1     1            1           42s
$ kubectl get hpa -n busybox
NAME      REFERENCE            TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
busybox   Deployment/busybox   0%/125%   1         10        1          46s
$ kubectl get cronjob -n busybox
NAME                 SCHEDULE                   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
busybox-scale-down   5,15,25,35,45,55 * * * *   False     0        43s             52s
busybox-scale-up     0,10,20,30,40,50 * * * *   False     0        <none>          53s
```

Based on the cron schedule, busybox pods will get scaled up and down as the respective cronjobs patch the HPA.


In the example, the scaling event happens every 5 mins. 
```
$ kubectl get pods -n busybox
NAME                                READY   STATUS      RESTARTS   AGE
busybox-6fdddd58dc-bpp4r            1/1     Running     0          15s
busybox-6fdddd58dc-ghn2b            1/1     Running     0          16s
busybox-6fdddd58dc-gvwhw            1/1     Running     0          5m31s
busybox-6fdddd58dc-vs25k            1/1     Running     0          16s
busybox-6fdddd58dc-x7flf            1/1     Running     0          15s
busybox-scale-down-28011215-gghxw   0/1     Completed   0          5m21s
busybox-scale-up-28011220-wrhms     0/1     Completed   0          21s

$ kubectl get hpa -n busybox
NAME      REFERENCE            TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
busybox   Deployment/busybox   0%/125%   5         10        5          6m9s
```