#!/bin/sh
set -e

# URL for the SQLite binary
SQLITE_URL="https://raw.githubusercontent.com/brudnak/vai-test/main/sqlite3"

# Function to check if SQLite3 is installed and working
check_sqlite3() {
    if [ -x "/tmp/sqlite3" ]; then
        if /tmp/sqlite3 --version >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Check if SQLite3 is already installed and working
if ! check_sqlite3; then
    echo "Downloading SQLite binary..."
    curl -k -L $SQLITE_URL -o /tmp/sqlite3
    chmod +x /tmp/sqlite3
fi

echo "SQLite3 version:"
/tmp/sqlite3 --version

echo "Executing query:"
/tmp/sqlite3 /var/lib/rancher/informer_object_fields.db <<EOF
.headers on
.mode column
$SQL_QUERY
EOF
