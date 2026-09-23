# Architecture — DataC0re Creative Lab

## Core idea

The application is a gallery hosting independent creative-coding sketches.

A sketch should focus on making visuals, not on transport/output technology.

## Planned runtime

App
├── Main
├── Gallery
├── Sketch Host
│   └── Active Sketch
└── Outputs
    ├── Window
    ├── Spout
    └── NDI

The active sketch will eventually render through a central viewport abstraction.

That common render target allows the exact same image to be:
- shown locally;
- sent through Spout;
- sent through NDI;
- captured or recorded later.

## Isolation

A broken experimental sketch must not break the gallery.

Sketches should not import each other's internal scripts.

Reusable pieces graduate into shared/ only when genuinely reused.

## Native integrations

Native integrations belong behind adapters.

Spout and NDI must never become requirements for opening the project or running ordinary sketches.
