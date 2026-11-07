#!/usr/bin/env bash
# Starts a node outside the cluster, on the cluster network, and reports whether it was accepted.
# Usage: check-unauthorized-node.sh <docker-network> <stack.xml> [cluster-name] [keystore.p12] [keystore-password]
# Expected on a protected cluster: RESULT REJECTED or RESULT ALONE, never RESULT JOINED.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
NETWORK="${1:?docker network required}"
STACK="${2:?stack xml required}"
CLUSTER="${3:-liferay-channel-control}"
KEYSTORE="${4:-}"
PASSWORD="${5:-unauthorized}"

MOUNT=()
if [ -n "$KEYSTORE" ]; then
	MOUNT=(-v "$KEYSTORE:/work/keystore.p12:ro")
fi

docker run --rm --network "$NETWORK" --entrypoint bash \
	-v "$HERE:/tests:ro" -v "$STACK:/work/stack.xml:ro" "${MOUNT[@]}" \
	liferay/portal:7.4.3.132-ga132 -c "
		unzip -q -o -j /opt/liferay/osgi/portal/com.liferay.portal.cluster.multiple.jar lib/jgroups-4.1.7.Final.jar -d /tmp/jg
		java -Djava.net.preferIPv4Stack=true \
			-Dcluster.link.auth.value=$PASSWORD \
			-Dcluster.link.auth.cert.alias=liferay-cluster-cert \
			-Dcluster.link.auth.cert.password=$PASSWORD \
			-Dcluster.link.auth.cipher.type=RSA \
			-Dcluster.link.auth.keystore.password=$PASSWORD \
			-Dcluster.link.auth.keystore.path=/work/keystore.p12 \
			-Dcluster.link.auth.keystore.type=PKCS12 \
			-cp /tmp/jg/jgroups-4.1.7.Final.jar /tests/UnauthorizedNode.java /work/stack.xml $CLUSTER
	" 2>&1 | grep -E 'RESULT|VIEW|SecurityException|authentication|Authentication|rejected|denied' || true
