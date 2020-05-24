IMAGE=imemjay/resticker
ARCH=amd64

default: image push manifest

image:
		docker build --build-arg PLATFORM=${ARCH} -t ${IMAGE}:${ARCH} .

push: image
		docker push ${IMAGE}:${ARCH}

manifest: push
		manifest-tool push from-args --platforms linux/amd64,linux/arm,linux/arm64 --template ${IMAGE}:${ARCH} --target ${IMAGE}
