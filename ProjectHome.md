The Datac application uses the microphone input of supported iOS devices as a signal input for display, filtering, and recording. It optionally provides a high-frequency output signal to drive a low-powered external device. Supports recording of the raw signal, with optional uploading to a configured Dropbox account.

There are no downloads available. The source is available, but you must get it yourself using the instructions found on the [Source](https://code.google.com/p/datac-data-acquisition/source/checkout) tab above (see Checkout).

# Usage #

The initial view is the _Input_ view that shows a trace of the audio signal seen from the iOS device's internal or external microphone. There are three indicators at the top:

  * Connection - illuminated if there is an external headphone/microphone attached
  * Record - button that starts/stops recording of the input signal
  * Power - button that toggles the emission of a high-frequency sine wave. Used to drive suitable low-power devices.

In the default mode, the _Input_ view shows audio values from -1 to +1 on the Y axis with time on the X axis. You can zoom in by pinch-expand gesture. In a zoomed state, you can pan the view around by a touch-and-drag gesture.

To freeze the view, simply tap once on it. Tap again to resume the view updates.

Some of the detection modules rely on different settings, and these settings show up as horizontal lines in various colors. For example, the simple level detection module will draw a red horizontal line at its current setting. Tapping on the line and dragging will change the level value. Alternatively, you may use the _Settings_ tab to enter a numeric value for the level value.

# Detections #

The original usage for this application was to monitor RPM signals coming from a device that hooked in to a automobile's onboard computer. The _Detections_ tab shows a graph of such signal detections. For other purposes, you are of course free to customize the view or to eliminate it entirely. Note that it does rely on the CocoaPlot package, which is an excellent means of plotting real-time data.

# Recordings #

Pressing the **Record** button in the _Input_ view will start a new recording of the raw input signal. This view shows all recordings that have been made (and not deleted). There is support for automatic uploading of recordings to a Dropbox account. Alternatively, you can access the recording files from within iTunes when the iPhone is docked to a computer.

To delete a recording, simply swipe across it horizontally and then press the **Delete** button. Alternatively, press the **Edit** button at the top-right of the screen and then press the red '-' button of the item to delete. Keep in mind that once a recording is gone it is really, really gone. There is no undo capability here.

# Settings #

There are (too) many configurable options available under the _Settings_ tab. I have tried to be self-explanatory with setting names and supplemental text, but as usual the code is the best source of explanation.