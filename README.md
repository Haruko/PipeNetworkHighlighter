# PipeNetworkHighlighter

This mod adds an overlay to Factorio that helps to show pipe system connectivity.

Default toggle hotkey is ' (apostrophe).

### Installation
Get newest release from [Releases](https://github.com/ZoeyBonaventura/PipeNetworkHighlighter/releases)
###### Windows 10
 - Paste ZIP file into `C:\Users\<username>\AppData\Roaming\Factorio\mods`
 - Ensure mod is enabled in Factorio's mod list.

### TODO
 - [ ] Improve speed. (Currently starts to lag a little at ~500 entities on i7-2600k)
 - [ ] Figure out a way to get around boilers not giving a full list of neighbors.
 - [ ] 1x1 pipes with the type "storage tank" are considered storage tanks when they should be pipes. Might have to make a patch for each mod for this one.

### Changelog
- #### v0.3.3
  - Fixed clipping of underground-pipe bridge entities and above ground entities.
- #### v0.3.2
  - Fixed a crash when hovering over a mining drill or pumpjack that doesn't require or produce fluid.
  - Consequently fixed a bug where assembly machines producing a fluid would not connect correctly.
- #### v0.3.1
  - Fixed a bug with underground pipes not showing their proper connections.
- #### v0.3.0
  - Complete rewrite.
  - Changed hotkey to apostrophe.
  - Expanded entity support to (hopefully) cover all mods.
  - Added highlight for large entities
  - Fixed bugs
    - Frozen entities when saving while hovering over pipe systems.
    - Pipe-to-ground connections showing as incorrect.
    - Crash when hovering over assembler.
- #### v0.2.0
  - Added hotkey to toggle overlay on and off. LSHIFT by default.
- #### v0.1.0
  - Initial commit.
  - Supports pipes, pipe-to-grounds, and basic pump support.