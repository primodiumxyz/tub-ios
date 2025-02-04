import createDebug from "debug";

export const debug = createDebug("primodiumxyz:tub");
export const error = createDebug("primodiumxyz:tub");

// Pipe debug output to stdout instead of stderr
debug.log = console.debug.bind(console);

// Pipe error output to stderr
error.log = console.error.bind(console);
