---
layout: default
title: Using Pract with Other third-party Systems
nav_order: 6
parent: Advanced Guide
permalink: advanced/externalstate
---

# Connecting External State

> Advanced guide is still a work in progress! More usage examples coming soon.

#### Up next: More coming soon?

Some personal notes for what's coming to the guide:

    - Tips on organizing Pract code, and using types? Callbacks through props, etc.
    - Refs? Is this a feature needed in Pract given what's already available?
    - Re-using input components via `Pract.combine`
        -> Bugfix/feature: If an instance is created/found in a combine children chain, it should be detected
        by other elements first, rather than ever search for the child via `FindFirstChild`!

        This behavior is important for `Pract.combine`'s use case of having multiple elements mounted to the same host.