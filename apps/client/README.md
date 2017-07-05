# Client

A CLI for starting scanning tasks. It sends a request to a running DScan server (over tls) and reports progress.

## How to run the client

First, you will need to get the dependencies:

`mix deps.get`

Then you will need to create an escript:

`mix escript.build`

This should create a new `dscan` file in the directory. Now you can sent a request to a server with:

`./dscan --server 127.0.0.1:5000 --ports 80,443 1.2.3.4/24`

But before doing that, you should create needed certificate files for the tls connection with the server. You can find more information on the [server readme](../server/README.md)

