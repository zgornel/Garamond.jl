# Remarks

## Multi-threading
If one chooses to use multi-threading i.e. through the `Threads.@threads`, `Threads.@spawn`  macros for example, export the following: `OPENBLAS_NUM_THREADS=1` and `JULIA_NUM_THREADS=<n>` where `n` is the number of threads desired.

## Unix socket tips and tricks
The examples below assume the existence of a Unix socket at the location `/tmp/<unix_socket>` (the socket name is not specified).
- To redirect a TCP socket to a UNIX socket: `socat TCP-LISTEN:<tcp_port>,reuseaddr,fork UNIX-CLIENT:/tmp/<unix_socket>` or `socat TCP-LISTEN:<tcp_port>,bind=127.0.0.1,reuseaddr,fork,su=nobody,range=127.0.0.0/8 UNIX-CLIENT:/tmp/<unix_socket>`
- To send a query to a Garamond server (no reply, for debugging purposes): `echo 'find me a needle' | socat - UNIX-CONNECT:/tmp/garamond/sockets/<unix_socket>`
- For interactive send/receive, `socat UNIX-CONNECT:/tmp/garamond/sockets/<unix_socket> STDOUT`
