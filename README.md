Database backup tools
=====================


To launch a backup:

    wget ${BACKUP_REPO_URL}/${BACKUP_SCRIPT_FILE} && ruby ${BACKUP_SCRIPT_FILE} "--oplog -u $MONGOADMIN -p $MONGOPWD" >>/tmp/log_export.txt && rm ${BACKUP_SCRIPT_FILE}

