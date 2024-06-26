#!/bin/sh
set -e

# URL for the SQLite binary
SQLITE_URL="https://raw.githubusercontent.com/brudnak/vai-test/main/sqlite3"

# Download SQLite binary
curl -L $SQLITE_URL -o /tmp/sqlite3
chmod +x /tmp/sqlite3

echo "SQLite3 version:"
/tmp/sqlite3 --version

echo "Querying for secret:"
/tmp/sqlite3 /var/lib/rancher/informer_object_fields.db \
"SELECT metadata.name FROM _v1_Secret_fields WHERE metadata.name = '$SECRET_NAME';"

echo "Listing all tables:"
/tmp/sqlite3 /var/lib/rancher/informer_object_fields.db \
"SELECT name FROM sqlite_master WHERE type='table';"

echo "Listing all secrets:"
/tmp/sqlite3 /var/lib/rancher/informer_object_fields.db \
"SELECT metadata.name FROM _v1_Secret_fields LIMIT 10;"

# Add any other queries you want to run here