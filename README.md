Database backup tools
=====================


To launch a backup:

    ruby backup.rb '--oplog -u $MONGO_ADMIN_USER_NAME -p $MONGO_PASSWORD'
    

This script expects you to have a `amazon_s3.yml` such like this:

    backup_bucket: my-s3-backup-bucket
    dump_directory: /tmp/dump-tmp
    access_key_id: MY_AMS_ACCESS_KEY
    secret_access_key: MY_AMS_SECRET_KEY

