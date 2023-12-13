#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found!"
    exit 1
fi


# Get current date in YYYYMMDD format
DATE=$(date +"%Y%m%d")

EMAIL_SUBJECT="Database Backup Report - $DATE"
EMAIL_BODY="Backup Report for databases:\n\n"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_BASE_DIR"

# Backup each database
for DB in $(mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql)"); do
    # Create database backup directory
    BACKUP_DIR="$BACKUP_BASE_DIR/$DB"
    mkdir -p "$BACKUP_DIR"

    # Backup file name with date
    BACKUP_FILE="$BACKUP_DIR/$DB-$DATE.sql.gz"

    # Perform the backup
    mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" "$DB" | gzip > "$BACKUP_FILE"

    # Remove older backups, keeping the last 3
    ls -t "$BACKUP_DIR/$DB"* | tail -n +4 | xargs rm -f

    # Update email report
    EMAIL_BODY+="Database: $DB\nBackup File: $BACKUP_FILE\n\n"
done

# Send email report
echo -e "$EMAIL_BODY" | mail -s "$EMAIL_SUBJECT" "$EMAIL_RECIPIENT"
