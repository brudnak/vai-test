#!/bin/sh
set -e

# URL for the SQLite binary
SQLITE_URL="https://raw.githubusercontent.com/brudnak/vai-test/main/sqlite3"

echo "Downloading SQLite binary..."
curl -k -L $SQLITE_URL -o /tmp/sqlite3
chmod +x /tmp/sqlite3

echo "SQLite3 version:"
/tmp/sqlite3 --version

echo "Querying for secret:"
/tmp/sqlite3 /var/lib/rancher/informer_object_fields.db <<EOF
.headers on
.mode column
SELECT * FROM _v1_Secret_fields WHERE "metadata.name" = '$SECRET_NAME';
EOF

echo "Listing sample data from _v1_Secret_fields:"
/tmp/sqlite3 /var/lib/rancher/informer_object_fields.db <<EOF
.headers on
.mode column
SELECT * FROM _v1_Secret_fields LIMIT 5;
EOF

# Add any other investigative queries here