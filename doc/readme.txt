Sider 5 for Pro Evolution Soccer 2019
=====================================
Copyright (C) 2018-2019 juce
Version 5.4.2



INTRODUCTION
------------

The "LiveCPK" feature makes it possible to replace game content
at run-time with content from files stored on disk, instead of
having to pack everything into CPK-archives. (This feature
is similar to Kitserver's AFS2FS and to FileLoader for earler
versions of PES).

If you know a little bit how to program, you can write your own
game logic using Sider's scripting engine, which uses Lua.
This requires some reading and understanding of how the game
works, but it's really not that hard ;-)
See scripting.txt - for detailed documentation on that.



HOW TO USE:
-----------

Run sider.exe, it will open a small window, which you can
minimize if you want, but do not close it.

Run the game.
Sider should automatically attach to the game process.

If you don't see the effects of Sider in the game, check the
sider.log file (in the same folder where sider.exe is) - it should
contain some helpful information on what went wrong.



SETTINGS (SIDER.INI)
--------------------

There are several settings you can set in sider.ini:


exe.name = "\PES2019.exe"

- this sets the pattern(s) that the Sider program will use
to identify which of the running processes is the game.
You can have multiple "exe.name" lines in your sider.ini,
which is useful, for example, if you have several exe
files with slightly different names that you use for
online/offline play.


free.side.select = 1

- enables free movement of controllers. Normally, it is
only possible in Exhibition modes, but with this setting
set to 1, you will be able to move the controllers in the
competition modes too.

The 1st controller can also be moved into the middle,
disabling it effectively. Use this carefully in the
matches: if you move 1st controller into the middle, make
sure that you have at least one other controller on the left
or on the right. Otherwise, you will lose the control of the
match. (default is: 0 - free movement disabled)


livecpk.enabled = 1

- Turns on the LiveCPK functionality of Sider. See below for a more
detailed explanation in cpk.root option section.


debug = 0

- Setting this to values > 0 will make Sider output some additional information
into the log file (sider.log). This is useful primarily for troubleshooting.
Extra logging may slow the game down, so normally you would want to keep
this setting set to 0. (Defaults to 0: some info, but no extra output)


close.on.exit = 0

- If this setting is set to 1, then Sider will close itself, when the
game exits. This can be handy, if you use a batch file to start sider
automatically right before the game is launched.
(Defaults to 0: do not close)


start.minimized = 0

- If you set this to 1, then Sider will start with a minimized window.
Again, like the previous option, this setting can be helpful, if you
use a batch file to auto-start sider, just before the game launches.
(Defaults to 0: normal window)


cpk.root = "c:\cpk-roots\balls-root"
cpk.root = "c:\cpk-roots\kits-root"
cpk.root = ".\another-root\stadiums"

- Specifies root folder (or folders), where the game files are stored that
will be used for content replacing at run-time. It works like this:
For example, the game wants to load a file that is stored in some CPK, with
the relative path of "common/render/thumbnail/ball/ball_001.dds". Sider
will intercept that action and check if one of the root folders have this
file. If so, Sider will make the game read the content from that file instead
of using game's original content. If multiple roots are specified, then
they are checked in order that they are listed in sider.ini. As soon as there
is a filename match, the lookup stops. (So, higher root will win, if both of
them have the same file). You can use either absolute paths or relative.
Relative paths will be calculated relative to the folder where sider.exe is
located.


lua.enabled = 1

- This turns on/off the scripting support. Extension modules can be
written in Lua 5.1 (LuaJIT), using a subset of standard libraries and
also objects and events provides by sider. See "scripting.txt" file for
a programmer's guide to writing lua modules for sider.


lua.module = "camera.lua"
lua.module = "kitrewrite.lua"

- Specifies the order in which the extension modules are loaded. These
modules must be in "modules" folder inside the sider root directory.


jit.enabled = 1

- Allows to enable/disable JIT (Just-In-Time compiler) for Lua.
By default, JIT is enabled - to provide performance boost for Lua modules.
To turn it off, set to 0.


lua.gc.opt = "step"

- This option allows to tweak Lua garbage collector (GC) behaviour.
Two supported values are: "step" - for incremental collection, and
"collect" - for full collection. Default is "step", and typically,
you do not need to modify this, unless you see Lua memory errors
in the log. In which case, try "collect".


overlay.enabled = 1

- This option enables an interactive overlay. The overlay can display
text that is provided by Lua modules, with one module having control
of the overlay at any given time. By pressing a hotkey (set by
overlay.vkey.next-module option) the control of the overlay can be switched
to the next module, and so on. The overlay is toggled on/off with another
hotkey, set by overlay.vkey.toggle option. When the overlay is on, the
key presses are passed on to the module that is currently in control of
the overlay. The module can handle those key events in whatever way
it needs to, or ignore them altogether. For more information, see
scripting.txt


overlay.on-from-start = 1

- If set to 1, the overlay will appear as soon as possible, after
the start of the game.
(default is 0, meaning that overlay starts hidden, until toggled on)


overlay.location = "bottom"

- two possible locations: "top" and "bottom" of the screen


overlay.font-size = 0
overlay.font = "Lucida Console"

- these two options control the font of overlay. Size 0 means that
the font-size will be calculated automatically, based on height of
the screen in pixels. Any TTF font installed on the system can be
used, but monospaced fonts are recommended for easier formatting.


overlay.vkey.toggle = 0x20
overlay.vkey.next-module = 0x31

- hot keys for toggling overlay on/off, and for switching control
of the overlay among the modules. Values must be specified in
hexadecimal format. The default ones are:
    0x20 [Space] - for toggle
    0x31 [1]     - for next-module
Full list of codes for all keys can be found here:
https://docs.microsoft.com/en-us/windows/desktop/inputdev/virtual-key-codes


overlay.background-color = "102010c0"
overlay.text-color = "80ff80c0"

- colors are specified in RRGGBBAA format (similar to how it is
done in HTML, except that you do not put '#' character in front)


overlay.image-alpha-max = 0.8

- max value for alpha channel for the image displayed in the overlay
(if there is one). This is useful, if you want the image to be slightly
translucent, as a visual hint that it is part of overlay. A value around
0.7 or 0.8 would give such effect.
Defaults to 1.0. The accepted range of values are: [0.0 - 1.0]
    0.0 : fully transparent
    1.0 : original alpha channel of the image is kept unmodified.


vkey.reload-1 = 0x10
vkey.reload-2 = 0x52

- These two settings define a hot-key combination that can be used
to reload Lua modules, without restarting the game. This is not a feature
that you would normally use during regular gameplay, but if you are
writing a module, very often you need to make a small fix or change.
Restarting the game every time can be time consuming, so this feature
allows to reload all modules that were modified since the last time
they were loaded. Default is: Shift-R  (0x10 and 0x52).


game.priority.class = "above_normal"

- This option allows to change the priority of the game process. Sometimes
this is useful, and reportedly can help to combat FPS drops. Supported values
are: "above_normal", "below_normal", "high", "idle", "normal" and "realtime".
By default, the game sets its priority to "above_normal".



CREDITS:
--------
Game research: nesa24, juce, digitalfoxx, zlac
Programming: juce
Testing: zlac, nesa24, Chuny, Hawke, sonofsam69, Cesc Fabregas
Blue Champions League ball: Hawke and digitalfoxx
Trophies: MJTS-140914

Sider uses the following 3rd-party software:
1) LuaJIT by Mike Pall (doc/license-luajit.txt)
2) Knuth-Morris-Pratt string matcher from Project Nayuki (doc/license-kmp.txt)
3) FW1FontWrapper library by Erik Rufelt
4) zlib by Jean-loup Gailly (compression) and Mark Adler (decompression).

