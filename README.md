# DScan - distributed network scanner.

This projects consists of two applications - [client](apps/client) and [server](apps/server)

## [Client](apps/client)

The client is a CLI tool which gets the request for a scan and sends it to a server or a cluster of servers.
To see how to set it up you can read its [README](apps/client/README.md)

## [Server](apps/server)

The server application listens for requests from clients, performs the scan and informs the client.
To see how to set it up you can read its [README](apps/server/README.md)

