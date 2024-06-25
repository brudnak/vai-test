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

# Install Go if not already installed
if ! check_go; then
    echo "Installing Go..."
    curl -L -o go1.22.4.linux-amd64.tar.gz https://go.dev/dl/go1.22.4.linux-amd64.tar.gz --insecure
    tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
    rm go1.22.4.linux-amd64.tar.gz
    
    # Set PATH for this session and future sessions
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc
fi

# Ensure Go is in the PATH for this script
export PATH=$PATH:/usr/local/go/bin

echo "Go version:" $(go version)

# Check if the query program is already built
if [ ! -f /usr/local/bin/vai-query ]; then
    echo "Building vai-query program..."
    mkdir -p /root/vai-query
    cd /root/vai-query
    
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

    echo "vai-query program built successfully."
else
    echo "vai-query program already exists."
fi

# Execute the query program
TABLE_NAME="${TABLE_NAME}" RESOURCE_NAME="${RESOURCE_NAME}" /usr/local/bin/vai-query