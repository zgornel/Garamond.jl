# Notes

## Multi-threading
Using multi-threading in Garamond is not recommended (as of Julia versions `v"1.0.2"` / `v"1.1-dev"`) as floating point operations are not thread-safe. If one chooses to use multi-threading i.e. through the `@threads` macro for example, the following exports: `OPENBLAS_NUM_THREADS=1` and `JULIA_NUM_THREADS=<n>` have to be performed for multi-threading to work efficiently.
