CONFIGURATION
-------------

In order to use the Dropbox SDK, you must register with with Dropbx to obtain
two values, a 'key' and a 'secret'. Copy the Dropbox.keys.sample file to
Dropbox.keys (or just remove the .sample extension). Edit the Dropbox.keys file
and place your values on the appropriate line. Save the file and build.

BUILD
-----

The application should build right out of the box when using Apple's Xcode 3.2
or later. All dependencies have been included.

DEPENDENCIES
------------

Included are snapshots of InAppSettingsKit, Cocoa-CorePlot, and DropboxSDK. To
upgrade InAppSettingsKit or DropboxSDK, just replace the included version with
newer ones, tweaking if necessary the Xcode project file for file changes. 
Upgrading Cocoa-CorePlot should be the same, but there may be some headaches
due to how it gets built.
