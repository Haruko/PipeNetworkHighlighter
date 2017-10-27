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

### Changelog

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