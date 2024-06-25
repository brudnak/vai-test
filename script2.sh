#!/bin/sh
set -e

echo "Starting script execution..."

# Function to check if Go is installed and working
check_go() {
    if /usr/local/go/bin/go version >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Install Go if not already installed
if ! check_go; then
    echo "Go not found. Installing Go..."
    curl -L -o go1.22.4.linux-amd64.tar.gz https://go.dev/dl/go1.22.4.linux-amd64.tar.gz --insecure
    tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
    rm go1.22.4.linux-amd64.tar.gz
    echo "Go installed successfully."
else
    echo "Go is already installed."
fi

# Always set the PATH to include Go
export PATH=$PATH:/usr/local/go/bin

echo "Checking Go version:"
go version

echo "Removing old vai-query if it exists..."
rm -f /usr/local/bin/vai-query

echo "Building vai-query program..."
mkdir -p /root/vai-query
cd /root/vai-query

# Initialize Go module
echo "Initializing Go module..."
go mod init vai-query

echo "Creating main.go..."
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

echo "Adding SQLite driver to go.mod..."
go get github.com/mattn/go-sqlite3

echo "Building the program with CGO enabled..."
CGO_ENABLED=1 go build -o /usr/local/bin/vai-query main.go

echo "vai-query program built successfully."

echo "Executing the query program..."
CGO_ENABLED=1 TABLE_NAME="${TABLE_NAME}" RESOURCE_NAME="${RESOURCE_NAME}" /usr/local/bin/vai-query

echo "Script execution completed."