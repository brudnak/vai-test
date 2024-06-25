#!/bin/sh
set -e

# Function to check if Go is installed and working
check_go() {
    if command -v go >/dev/null 2>&1; then
        if go version >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Check if Go is already installed and working
if ! check_go; then
    echo "Installing Go..."
    curl -L -o go1.22.4.linux-amd64.tar.gz https://go.dev/dl/go1.22.4.linux-amd64.tar.gz --insecure
    tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    rm go1.22.4.linux-amd64.tar.gz
else
    echo "Go is already installed."
fi

echo "Go version:" $(go version)

# Check if the query program is already built
if [ ! -f /usr/local/bin/vai-query ]; then
    echo "Building vai-query program..."
    mkdir -p /tmp/vai-query
    cd /tmp/vai-query
    
    # Initialize Go module
    go mod init vai-query

    cat << EOF > main.go
package main

import (
    "database/sql"
    "fmt"
    "log"
    "os"
    _ "github.com/mattn/go-sqlite3"
)

func main() {
    db, err := sql.Open("sqlite3", "/var/lib/rancher/informer_object_fields.db")
    if err != nil {
        log.Fatal(err)
    }
    defer db.Close()

    tableName := os.Getenv("TABLE_NAME")
    resourceName := os.Getenv("RESOURCE_NAME")

    query := fmt.Sprintf("SELECT * FROM %s WHERE name = ?", tableName)
    rows, err := db.Query(query, resourceName)
    if err != nil {
        log.Fatal(err)
    }
    defer rows.Close()

    columns, err := rows.Columns()
    if err != nil {
        log.Fatal(err)
    }

    values := make([]interface{}, len(columns))
    valuePtrs := make([]interface{}, len(columns))
    for i := range columns {
        valuePtrs[i] = &values[i]
    }

    for rows.Next() {
        err := rows.Scan(valuePtrs...)
        if err != nil {
            log.Fatal(err)
        }

        for i, col := range columns {
            val := values[i]
            fmt.Printf("%s: %v\n", col, val)
        }
    }
}
EOF

    # Add SQLite driver to go.mod
    go get github.com/mattn/go-sqlite3

    # Build the program
    go build -o /usr/local/bin/vai-query main.go

    # Clean up
    cd /
    rm -rf /tmp/vai-query
else
    echo "vai-query program already exists."
fi

# Execute the query program
TABLE_NAME="${TABLE_NAME}" RESOURCE_NAME="${RESOURCE_NAME}" /usr/local/bin/vai-query