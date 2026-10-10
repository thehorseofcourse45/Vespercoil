# Enemy and object SVG templates

AI authors: start with `art/templates/README.md` for the style contract, template
catalog, integration steps and a motif index for all 40 regional enemies.

The library has eight enemy templates and six object templates. They are editable,
self-contained 64px SVGs; no art generator or new runtime dependency is required.

Art validation (Godot 4.7.2):

```powershell
& 'C:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Godot\Vespercoil' --script res://tests/regional_art.gd
```

The redraw updates only the final two exclusive enemy portraits on each of the
20 maps. Existing scene references, stats, behaviors and roster positions are retained.
