Sider 6 for Pro Evolution Soccer 2020
=====================================
Copyright (C) 2018-2019 juce
Version 6.0.0



INTRODUCTION
------------

The "LiveCPK" feature makes it possible to replace game content
at run-time with content from files stored on disk, instead of
having to pack everything into CPK-archives. (This feature
is similar to Kitserver's AFS2FS and to FileLoader for earler
versions of PES).



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


exe.name = "\PES2020.exe"

- this sets the pattern(s) that the Sider program will use
to identify which of the running processes is the game.
You can have multiple "exe.name" lines in your sider.ini,
which is useful, for example, if you have several exe
files with slightly different names that you use for
online/offline play.


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

