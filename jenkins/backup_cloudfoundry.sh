#!/bin/sh
#
#
# Variables:
#	DEPLOYMENT_NAME=[Deployment Name]
#	S3_BACKUP=[true|false]

set -e


###########################################################
#
# Functionality shared between all of the Jenkins deployment scripts
BASE_DIR="`dirname $0`"
CF_PREAMBLE="$BASE_DIR/cloudfoundry-preamble.sh"

if [ ! -f "$CF_PREAMBLE" ]; then
	echo "Unable to find $CF_PREAMBLE"

	exit 1
fi

"$CF_PREAMBLE"
###########################################################

# Backup CF databases
./Scripts/bin/backup_cloudfoundry-databases.sh "$DEPLOYMENT_NAME" || DATABASE_FAILED=1

if [ x"$S3_BACKUP" = x'true' ]; then
	# Backup S3 buckets
	./Scripts/bin/backup_cloudfoundry-s3.sh "$DEPLOYMENT_NAME" backup "s3://$BACKUP_BUCKET/$DEPLOYMENT_NAME/s3_backups" || S3_FAILED=1

	# Backup the branch
	./Scripts/bin/backup_cloudfoundry-branch.sh "$DEPLOYMENT_NAME" backup "s3://$BACKUP_BUCKET/$DEPLOYMENT_NAME/branch_backup" || BRANCH_FAILED=1
fi

if [ -n "$DATABASE_FAILED" -o -n "$S3_FAILED" -o -n "$BRANCH_FAILED" ]; then
	[ -n "$DATABASE_FAILED" ] && WARN 'Database backup failed'
	[ -n "$S3_FAILED" ] && WARN 'S3 backup failed'
	[ -n "$BRANCH_FAILED" ] && WARN 'Branch backup failed'

	FATAL 'Backup failed'
fi