#!/bin/bash

# Define temporary file path with process ID for uniqueness
TEMP_IDENTITY="temp_identity_$$.json"
GPG_FILE="identity.json.gpg"

# Check if GPG file exists
if [ ! -f "$GPG_FILE" ]; then
    echo "Error: $GPG_FILE not found"
    exit 1
fi

# Prompt user for password with hidden input and decrypt the file
echo "Please enter GPG password to decrypt identity.json: "
read -s PASSWORD
echo "$PASSWORD" | gpg --batch --yes --passphrase-fd 0 --output "$TEMP_IDENTITY" --decrypt "$GPG_FILE" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Decryption failed, please check your password"
    exit 1
fi

# Verify temporary file was created successfully
if [ ! -f "$TEMP_IDENTITY" ]; then
    echo "Error: Failed to create temporary identity.json file"
    exit 1
fi

# Start the validator node
exec nohup ../tachyon/target/release/tachyon-validator \
    --identity "$TEMP_IDENTITY" \
    --vote-account REPLACED_WITH_YOUR_VOTE_PUBKEY \
    --known-validator Abt4r6uhFs7yPwR3jT5qbnLjBtasgHkRVAd1W6H5yonT \
    --known-validator 5NfpgFCwrYzcgJkda9bRJvccycLUo3dvVQsVAK2W43Um \
    --known-validator FcrZRBfVk2h634L9yvkysJdmvdAprq1NM4u263NuR6LC \
    --only-known-rpc \
    --log - \
    --ledger ./ledger \
    --rpc-port 8899 \
    --full-rpc-api \
    --private-rpc \
    --dynamic-port-range 8000-8020 \
    --entrypoint entrypoint1.testnet.x1.xyz:8001 \
    --entrypoint entrypoint2.testnet.x1.xyz:8000 \
    --entrypoint entrypoint3.testnet.x1.xyz:8000 \
    --wal-recovery-mode skip_any_corrupted_record \
    --limit-ledger-size 50000000 \
    --enable-rpc-transaction-history \
    --enable-extended-tx-metadata-storage \
    --rpc-pubsub-enable-block-subscription \
    --full-snapshot-interval-slots 5000 \
    --maximum-incremental-snapshots-to-retain 10 \
    --maximum-full-snapshots-to-retain 50 \
    &

# Get the process ID
VALIDATOR_PID=$!

# Wait briefly to ensure process starts
sleep 2

# Check if process is still running
if kill -0 $VALIDATOR_PID 2>/dev/null; then
    # If process started successfully, remove temporary file
    rm -f "$TEMP_IDENTITY"
    echo "Validator node started successfully, temporary identity file removed"
else
    echo "Warning: Validator node startup may have failed, keeping temporary file for inspection"
fi
