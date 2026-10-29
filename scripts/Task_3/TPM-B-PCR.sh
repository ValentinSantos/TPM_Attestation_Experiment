#!/bin/bash

set -u

WORKDIR="/home/srv/tpm-pcr-verification"
cd "$WORKDIR" || exit 1

echo "== TPM-B: PCR-bound signing verification =="

echo "== 1. Verify original message =="

if openssl dgst -sha256 \
    -verify pcr_rsa-public.pem \
    -signature pcr_signature.bin \
    message.txt; then
    echo "PASS: Original message signature verified."
else
    echo "FAIL: Original message signature verification failed."
    exit 1
fi

echo
echo "== 2. Verify tampered message =="

printf 'TPM exercise modified' > tampered.txt

if openssl dgst -sha256 \
    -verify pcr_rsa-public.pem \
    -signature pcr_signature.bin \
    tampered.txt; then
    echo "ERROR: Tampered message was accepted!"
    exit 1
else
    echo "PASS: Tampered message was rejected."
fi

echo
echo "== Verification experiment complete =="
