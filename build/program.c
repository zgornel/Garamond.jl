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
    jl_options.image_file = "libmain_garamond";
    julia_init(JL_IMAGE_JULIA_HOME);

    // Do some work
    main_garamond();

    // Cleanup and graceful exit
    jl_atexit_hook(0);
    return 0;
}
