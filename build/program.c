#include <string.h>
#include <stdint.h>
#include "uv.h"
#include "julia.h"

#ifdef JULIA_DEFINE_FAST_TLS 
JULIA_DEFINE_FAST_TLS()
#endif

// prototype for the external main function 
extern void garamond_main();

int main(int argc, char *argv[])
{
    intptr_t v;

    // Initialize Julia
    uv_setup_args(argc, argv); // no-op on Windows
    libsupport_init();
    jl_options.image_file = "libgaramondmain";
    julia_init(JL_IMAGE_JULIA_HOME);


    // build arguments array: `String[ unsafe_string(argv[i]) for i in 1:argc ]`
    jl_array_t *ARGS = jl_alloc_array_1d(jl_apply_array_type(jl_string_type, 1), 0);
    JL_GC_PUSH1(&ARGS);
    jl_array_grow_end(ARGS, argc - 1);
    for (int i = 1; i < argc; i++) {
        jl_value_t *s = (jl_value_t*)jl_cstr_to_string(argv[i]);
        jl_arrayset(ARGS, s, i - 1);
    }

    // Do some work
    garamondmain(ARGS);
    
    JL_GC_POP();

    // Cleanup and graceful exit
    jl_atexit_hook(0);
    return 0;
}
