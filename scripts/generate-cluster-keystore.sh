#!/usr/bin/env bash
# Creates the keystore shared by every node. Run once, then distribute the same file.
# Usage: generate-cluster-keystore.sh <output-file> <alias>
# The store password is read from CLUSTER_KEYSTORE_PASSWORD.
set -euo pipefail

OUTPUT="${1:?output file required}"
ALIAS="${2:-liferay-cluster-cert}"
: "${CLUSTER_KEYSTORE_PASSWORD:?set CLUSTER_KEYSTORE_PASSWORD}"

if [ -e "$OUTPUT" ]; then
	echo "Refusing to overwrite $OUTPUT" >&2
	exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

keytool -genkeypair \
	-alias "$ALIAS" \
	-dname "CN=$ALIAS" \
	-keyalg RSA \
	-keysize 3072 \
	-sigalg SHA256withRSA \
	-validity 3650 \
	-storetype PKCS12 \
	-keystore "$OUTPUT" \
	-storepass:env CLUSTER_KEYSTORE_PASSWORD

chmod 600 "$OUTPUT"
echo "Keystore created: $OUTPUT"
