# Auto Craft Companion - A fully AFK Crafting Macro for FFXIV

An automated auto crafting macro that will repeat your crafts and reapply food and potion buffs as needed!

![Preview](https://github.com/CommanderTrip/ffxiv-autocraftcompanion/blob/main/bin/assets/example.png)

## How to Use it

This application is intended to be used as a true "AFK" macro so you can step away from FFXIV, play another game, or watch movies while your crafts get completed! This program **will not** determine your crafting rotations; it simply reruns your crafting rotations so you can bulk craft high quality recipes and collectables.

1. Set up your macros (and food/pot if needed) on a hotbar with keybinds.
2. Use `Ctrl + K` to start the GUI.
3. Set up your profile on the Auto Craft Companion to the right buttons to click for your macros, food, and potions.
4. Make sure the recipe you want to bulk craft is in your favorites list.
5. Stand in the *starting position*: be standing with the right job for the craft, your crafting window open on your favorites list, and click on the recipe you want to craft.
   - Note: if you need to add HQ materials for your craft, add it in the craft window **then click again on the recipe so it's the last thing you clicked**.
6. Set FFXIV to windowed mode and move it to another monitor/to the side
   - Do _NOT_ interact with the Macro window or FFXIV while the macro is going. Interacting with either will affect timings or inputs to start the next craft.
   - If you do interact with the windows after starting, restarting the craft **will likely fail**, so you'll want to stop/finish the automated craft and restart the setup.
7. Click "Start Autocraft" and enjoy the free time to do your chores!

## Notes

- Only for Windows since this system was built using [Auto Hotkey](https://www.autohotkey.com/docs/v2/).
  - There are plans to redo this project in Rust and Tauri.
- The inputs follow Auto Hotkey's hotkey commands which is why the `System CloseUI Keybind` is `{Esc}`. Check out the docs for more information https://www.autohotkey.com/docs/v2/lib/Send.htm#keynames .

## Known Issues

- Completion Time is not accurate.
