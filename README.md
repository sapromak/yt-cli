# yt-cli

Download YouTube videos on a Mac and send them straight to an Android phone.

## Setup

A couple of tools and a one-time handshake with the phone are needed.

1. **Install the dependencies** (via Homebrew):

   ```bash
   brew install yt-dlp
   brew install --cask android-platform-tools
   ```

2. **Turn on debugging on the phone.** Open Settings → About phone and tap "Build number" seven times to unlock Developer options. Then head into Developer options and switch on **USB debugging**.

3. **Plug the phone into the Mac** with a real (data-capable) cable and run:

   ```bash
   adb devices
   ```

   The phone will ask whether to trust this computer — tick "Always allow" and accept. Running the command again should now list the device as `device`. That's it.

4. **Quick sanity check** — push any file and make sure it lands in the phone's Downloads:

   ```bash
   adb push some-file.txt /sdcard/Download/
   ```

If that file shows up on the phone, everything's good to go.
