# Notes

## Multi-threading
Using multi-threading in Garamond is not recommended as the feature is still experimental. If one chooses to use multi-threading i.e. through the `@threads` macro for example, the following steps need to be taken:
 - export the following: `OPENBLAS_NUM_THREADS=1` and `JULIA_NUM_THREADS=<n>` where `n` is the number of threads desired
 - add the statement `Threads.@threads` in front of the main `for` loop of the top search function in `src/search.jl` (see appropriate comment in the code)

!!! warning

    Using multi-threading might result in errors and other types of instable behavior.
    As of the current date (January 2019) seems to be safe. Please make sure you properly
    check the search behavior prior to running.

## Unix socket tips and tricks
The examples below assume the existence of a Unix socket at the location `/tmp/<unix_socket>` (the socket name is not specified).
- To redirect a TCP socket to a UNIX socket: `socat TCP-LISTEN:<tcp_port>,reuseaddr,fork UNIX-CLIENT:/tmp/<unix_socket>` or `socat TCP-LISTEN:<tcp_port>,bind=127.0.0.1,reuseaddr,fork,su=nobody,range=127.0.0.0/8 UNIX-CLIENT:/tmp/<unix_socket>`
- To send a query to a Garamond server (no reply, for debugging purposes): `echo 'find me a needle' | socat - UNIX-CONNECT:/tmp/garamond/sockets/<unix_socket>`
- For interactive send/receive, `socat UNIX-CONNECT:/tmp/garamond/sockets/<unix_socket> STDOUT`
