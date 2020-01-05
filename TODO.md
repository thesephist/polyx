# Todos

## General
- In every Polyx app, anytime there's network activity going on, we should have an indicator so even on slow networks there's always feedback if network activity / fetch is going on.

## Fortress
- Fortress should include and expose a web GUI that I can use to monitor service availability and resource usage from anywhere, not just the command line.
    - We shouldn't expose any controls through the public web (if anything needs attention, we can SSH in)
    - Shows resource usage from `/proc/pid/status` in addition to literal systemd output and last little bit of tailed logs.

## Sigil
- Two-phase commit for completing tasks, so we don't accidentally check something off.
