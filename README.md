# nanoleaf
NanoLeaf library for LUA/gamesense

--[[ 
    API USAGE:


    main(auth_token, local_ipv4) --Setup LINK

    Effects:
        NanoLeaf.effect() --Gets all effect and current selected one.
        NanoLeaf.effect('Effect Name') --Sets lights to selected effect.

    Switch:
        NanoLeaf.switch() --Gets information if light is on or off.
        NanoLeaf.switch(true) --Turns lights on.
        NanoLeaf.switch(false) --Turns lights off.

    Color:
        NanoLeaf.color(255, 255, 255, 50) --Sets color to white with 50% brightness.
        NanoLeaf.color(255, 255, 255) --Sets color to white.

    Brightness:
        NanoLeaf.brightness()  --Gets current brightness.
        NanoLeaf.brightness(50)  --Sets brightness to 50%.

    Prints:
        NanoLeaf.print('Hello World!') --[NanoLeaf] Hello World! With green prefix.
        NanoLeaf.print('Hello World!', 1) --[NanoLeaf] Hello World! With green prefix.
        NanoLeaf.print('Hello World!', 2) --[NanoLeaf] Hello World! With red prefix.
        NanoLeaf.print('Hello World!', 3) --[NanoLeaf] Hello World! With blue prefix.
---]]
