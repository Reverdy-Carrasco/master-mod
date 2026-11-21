#include "build_m1_card.h"

// Sidechain's signal-flow screen drawer — weak optional import.
// Verified via `check` on sidechain.pack 0.12: sidechain offers
// op1f_duck_block_gains, op1f_duck_detect, op1f_duck_gain, op1f_duck_screen,
// op1f_art_sidechain. We pick op1f_duck_screen: its presence means sidechain's
// own signal-flow page is loaded and should serve the signalflow.svg picture.
extern "C" void __attribute__((weak)) op1f_duck_screen(void*) asm("op1f_duck_screen");

// Declaration first (OP1F_NAMED carries the asm-rename and must be on the
// declaration, not the definition).
extern "C" const char* master_mod_pick(const char* name) OP1F_NAMED("master_mod_pick");

// Tiny constant-time string equal — pack code can't call strcmp.
static int streq(const char* a, const char* b) {
    while (*a && *a == *b) { a++; b++; }
    return *a == *b;
}

// Picture picker. Called by base every time the firmware asks for a picture.
// Returns the name we serve, or 0 to let another pack (or stock) serve it.
extern "C" const char* master_mod_pick(const char* name) {
    if (!name) return (const char*)0;
    if (streq(name, "master.svg"))     return "master.svg";
    if (streq(name, "signalflow.svg")) {
        if (&op1f_duck_screen != 0) return (const char*)0;  // sidechain present -> let it serve
        return "signalflow.svg";                             // sidechain absent -> serve ours
    }
    return (const char*)0;
}
