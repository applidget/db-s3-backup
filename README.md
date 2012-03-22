Database backup tools
=====================


To launch a backup:

    ruby backup.rb '--oplog -u $AMAZON_SECRET_KEY -p $MONGOPWD'
    

This script expects you to have a `amazon_s3.yml` such like this:

    backup_bucket: my-s3-backup-bucket
    dump_directory: /tmp/dump-tmp
    access_key_id: MY_AMS_ACCESS_KEY
    secret_access_key: MY_AMS_SECRET_KEY
    
Using in a crontab would look the following for example:

    0 23 * * * . /home/ubuntu/.env_vars &&  /usr/bin/wget https://raw.github.com/applidget/db-s3-backup/master/mongo/backup.rb && /usr/local/bin/ruby backup.rb '--oplog -u $MONGOADMIN -p $MONGOPWD' >> /tmp/backup.log 2>&1 && rm -f backup.rb
    
Where `.env_vars` is just a script exporting the appropriate environments variables that are:

- `MONGOADMIN`: you amazon aws secret key
- `MONGOPWD`: you amazon aws secret key


