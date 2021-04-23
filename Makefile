# Main Package Details
APP=$(subst .,-,$(subst Package: ,,$(shell grep "Package: " DESCRIPTION)))
VER=$(subst Version: ,,$(shell grep "Version: " DESCRIPTION))
GIT=$(subst https://github.com/,,$(filter https://github.com/%,$(shell grep "URL: " DESCRIPTION)))
REP=tjpalanca/apps
LAT_IMG=$(REP):$(APP)-latest
VER_IMG=$(REP):$(APP)-v$(VER)
CCH_IMG=$(REP):$(APP)-cache

# Testing Environment
BUILD_ARGS=
ENV_VARS=
TEST_PORT=3838
TEST_NAME=test
GHA_ENV_VARS= \
	--env R_CONFIG_ACTIVE="cicd" \
	--env GITHUB_ACTIONS="$(GITHUB_ACTIONS)" \
	--env GHA_JOB_ID="$(GHA_JOB_ID)" \
	--env GITHUB_RUN_ID="$(GITHUB_RUN_ID)"
NODENAME=$(shell kubectl get pod $(HOSTNAME) -o=jsonpath={'.spec.nodeName'})

# Cloud66 Redeployment Details
C66_DEPLOY_HOOK=
C66_DEPLOY_SERVICES=

# Pull the cache image
pkg-build-pull:
	-docker pull $(CCH_IMG)

# Build the image
pkg-build:
	docker build -f Dockerfile \
		--cache-from $(CCH_IMG) \
		$(BUILD_ARGS) \
		--tag $(VER_IMG) --tag $(CCH_IMG) .

# Build the image (dev)
pkg-build-dev:
	docker build -f Dockerfile \
		$(BUILD_ARGS) \
		--tag $(VER_IMG) --tag $(CCH_IMG) .

# Bash into the built image
pkg-bash:
	docker run -it --rm $(VER_IMG) bash

# Push the cache image
pkg-build-push:
	docker push $(CCH_IMG)

# Publish the image into the latest
pkg-publish:
	docker push $(VER_IMG) && \
	docker tag $(VER_IMG) $(LAT_IMG) && \
	docker push $(LAT_IMG)

# Deploy to Cloud66
pkg-deploy:
	curl -X POST $(C66_DEPLOY_HOOK)?services=$(C66_DEPLOY_SERVICES)

# Create Github Release
pkg-release:
	curl \
		-u tjpalanca:${GITHUB_PAT} \
		-X POST \
		-H "Accept: application/vnd.github.v3+json" \
  		https://api.github.com/repos/$(GIT)/releases \
  		-d '{"tag_name":"v$(VER)", "name":"$(APP) v$(VER)"}'

# Test your application on a test URL
kube-test-start:
	kubectl run $(APP) \
		--image=$(VER_IMG) \
		--port=$(TEST_PORT) \
		$(ENV_VARS) \
		--overrides='{"apiVersion": "v1", "spec": { "nodeName" : "$(NODENAME)" } }' && \
	kubectl expose pod/$(APP) \
		--name=$(TEST_NAME) \
		--port=80 \
		--target-port=$(TEST_PORT)

# Test in Kubernetes Cluster
kube-test-stop:
	kubectl delete svc/$(TEST_NAME) & \
	kubectl delete pod/$(APP)

# Restart through iterative testing
kube-test-restart:
	make kube-test-stop && \
	make pkg-build && \
	make kube-test-start

# Surface logs
kube-logs:
	kubectl logs $(APP)
