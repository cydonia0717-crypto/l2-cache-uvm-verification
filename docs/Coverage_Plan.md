# Coverage Plan

The initial collector samples completed or stalled interface activity rather than sequence intent.

Current coverpoints include:

- core request / response / request-stall / response-stall event types;
- port 0 / port 1;
- read / write;
- cache-line word offset classes;
- address set slices;
- memory refill / writeback;
- memory request / response stall;
- core-port × operation cross.

The second closure pass should add stateful coverage computed from monitor history:

- outstanding miss depth 1..8;
- MSHR-full stall;
- same-line vs different-line concurrent miss;
- same-bank vs different-bank concurrency;
- refill ordering distance;
- dirty eviction × memory backpressure;
- response backpressure × outstanding depth;
- replacement-way distribution;
- hit/miss classification inferred from downstream traffic.
