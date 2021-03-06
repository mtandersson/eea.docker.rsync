# Simple rsync container based on alpine

A simple rsync server/client Docker image to easily rsync data within Docker volumes

## Simple Usage

Get files from remote server within a `docker volume`:

    $ docker run --rm -v blobstorage:/data/ mtand/rsync \
             rsync -avzx --numeric-ids user@remote.server.domain.or.ip:/var/local/blobs/ /data/

Get files from `remote server` to a `data container`:

    $ docker run -d --name data -v /data busybox
    $ docker run --rm --volumes-from=data mtand/rsync \
             rsync -avz user@remote.server.domain.or.ip:/var/local/blobs/ /data/

## Advanced Usage

### Client setup

Start client to pack and sync every night:

    $ docker run --name=rsync_client -v client_vol_to_sync:/data \
                 -e CRON_TASK_1="0 1 * * * /data/pack-db.sh" \
                 -e CRON_TASK_2="0 3 * * * rsync -e 'ssh -p 2222' -aqx --numeric-ids root@foo.bar.com:/data/ /data/" \
             mtand/rsync client

Copy the client SSH public key printed found in console

### Server setup

Start server on `foo.bar.com`

    # docker run --name=rsync_server -d -p 2222:22 -v server_vol_to_sync:/data \
                 -e SSH_AUTH_KEY_1="<SSH KEY FROM rsync_client>" \
                 -e SSH_AUTH_KEY_n="<SSH KEY FROM rsync_client_n>" \
             mtand/rsync server

### Verify that it works

Add `test` file on server:

    $ docker exec -it rsync_server sh
      $ touch /data/test

Bring the `file` on client:

    $ docker exec -it rsync_client sh
      $ rsync -e 'ssh -p 2222' -avz root@foo.bar.com:/data/ /data/
      $ ls -l /data/


### Rsync data between containers in Rancher

0. Request TCP access to port 2222 to an accessible server of environment of the new installation from the source container host server.

1. Start **rsync client** on host from where do you want to migrate data (ex. production).

   Infrastructures -> Hosts -> Add Container

   - Select image: mtand/rsync
   - Command: sh
   - Volumes -> Volumes from: Select source container

2. Open logs from container, copy the ssh key from the message

3. Start **rsync server** on host from where do you want to migrate data (ex. devel). The destination container should be temporarily moved to an accessible server ( if it's not on one ) .

   Infrastructures -> Hosts -> Add Container

   - Select image: mtand/rsync
   - Port map -> +(add) : 2222:22
   - Command: server
   - Add environment variable: SSH_AUTH_KEY="<SSH-KEY-FROM-R-CLIENT-ABOVE>"
   - Volumes -> Volumes from: Select destination container

4. Within **rsync client** container from step 1 run:

```
  $ rsync -e 'ssh -p 2222' -avz <SOURCE_DUMP_LOCATION> root@<TARGET_HOST_IP_ON_DEVEL>:<DESTINATION_LOCATION>
```

4. The rsync servers can be deleted, and the destination container can be moved back ( if needed )
