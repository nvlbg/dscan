# Server

The server listens for requests from clients, performs the scan and informs the client.
If it is connected to other servers, it will distribute the work among all of them.

## Installation

### Step 1 - get the dependencies

```
mix deps.get
```

### Step 2 - set needed enviroment variables

- PUBLIC_IP - The public ip address of the node
- ERLANG_COOKIE - The erlang cookie used for distribution. All nodes that run in a cluster should have the same cookie.
- PORT - The port on which the server will listen for client connections
- KEY_PASSWORD - The password for the server certificate. Read more below.
- REPLACE_OS_VARS - This should be set to true.

For example:

```
export PUBLIC_IP='1.2.3.4'
export ERLANG_COOKIE='ilovecookies'
export PORT=5000
export KEY_PASSWORD='yourpassword'
export REPLACE_OS_VARS=true
```

### Step 3 (optional) - create nodes.txt

If you want to run a cluster of servers, create the file `priv/nodes.txt` and for each server put a line containing `server@$IP`, for example `server@1.2.3.4`.

### Step 4 - put your certificates

You will also need to put your certificates in `priv/cert.pem`, `priv/cacert.pem` and `priv/key.pem`. To see how to get such files read below.

### Step 5 - create a release

```
mix release
```

It will output something like:

```
==> Release successfully built!
    You can run it in one of the following ways:
      Interactive: .../dscan/_build/dev/rel/server/bin/server console
      Foreground: .../dscan/_build/dev/rel/server/bin/server foreground
      Daemon: .../dscan/_build/dev/rel/server/bin/server start
```

### Step 6 - run the server

Now you can start the server with one of the provided commands above.

If you want to run a cluster, you need to repeat these steps for each server.

## About the certificates

Because the server is meant to run in a cluster over internet, it is a bad idea not to use some kind of encryption and verification.
For this reason, the only way to run the cluster is over tls. To run tls, you will need a private key and a public certificate for
each server and client, as well as the public certificate of the authority, which authorises the certificates. My recommendation is
to create you own certificate authority (CA), although you can use some other CA if you want to. There are many articles on the internet 
about how to create your own CA and sign your own certificates. In the end you should end up with CA certificate file, and a pair of 
certificate and key file for each server and client.

