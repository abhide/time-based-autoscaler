NAMESPACE=busybox

create-ns:
	kubectl create namespace ${NAMESPACE} || true

deploy-busybox:
	kubectl apply -f busybox.yaml -n ${NAMESPACE}

deploy-cronjob:
	kubectl apply -f rbac.yaml -n ${NAMESPACE}
	kubectl apply -f scaleup-cronjob.yaml -n ${NAMESPACE}
	kubectl apply -f scaledown-cronjob.yaml -n ${NAMESPACE}

clean: 
	kubectl delete namespace ${NAMESPACE}

all: create-ns deploy-busybox deploy-cronjob