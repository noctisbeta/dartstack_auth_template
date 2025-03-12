#!/bin/bash

# Database configuration
DB_NAME="dartstack_auth_template"

# Text colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up dartstack_auth_template database...${NC}"

# Drop existing database if it exists
echo "Dropping existing database if it exists..."
dropdb $DB_NAME 2>/dev/null

# Create fresh database
echo "Creating new database..."
createdb $DB_NAME

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to create database${NC}"
    exit 1
fi

# Apply schema files in order
echo "Applying schema files..."
for schema_file in ../schema/*.sql; do
    echo -e "${GREEN}Applying schema: $(basename "$schema_file")${NC}"
    psql $DB_NAME -f "$schema_file"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to apply schema: $(basename "$schema_file")${NC}"
        exit 1
    fi
done

echo "Verifying database setup..."
psql $DB_NAME -c '\dt'
if [ $? -ne 0 ]; then
    echo -e "${RED}Database verification failed${NC}"
    exit 1
fi

echo -e "${GREEN}Database verification successful!${NC}"