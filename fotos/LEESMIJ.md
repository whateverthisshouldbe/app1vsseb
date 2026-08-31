# Foto's

Zet hier per gerecht een foto neer met de receptcode als naam:

    fotos/D14.jpg     Shoarma met pita's
    fotos/L4.jpg      Skyr met muesli en fruit
    fotos/O1.jpg      Upfront Baked Oats

Draai daarna `python3 tools/build-data.py tools/Seb60dagenvoedingsschema.xlsx`.
Alleen gerechten waarvoor een bestand bestaat krijgen een foto; de rest houdt
het lege vakje. `.jpg`, liggend, 800 px breed is ruim genoeg.

`PROMPTS.md` bevat een kant-en-klare prompt per gerecht, met de porties erbij.
Regenereren kan met `python3 tools/build-fotoprompts.py`.
