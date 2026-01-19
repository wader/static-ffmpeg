// test.c
#include <stdio.h>
#include <librsvg/rsvg.h>

int main() {
    RsvgHandle* h = rsvg_handle_new_from_data("", 0, NULL);
    printf("r=%p\n", h);

    return 0;
}

