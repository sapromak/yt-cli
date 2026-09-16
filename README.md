# yt-cli

A little shell script that downloads YouTube videos on a Mac and sends them
straight to an Android phone over USB. Built around
[yt-dlp](https://github.com/yt-dlp/yt-dlp) and `adb`.

Downloads land in a fresh timestamped folder under `~/Downloads`, capped at
1080p (or the best available below that), merged into `.mp4`.

## Setup

A couple of tools and a one-time handshake with the phone.

1. **Install the dependencies** (via Homebrew):

   ```bash
   brew install yt-dlp
   brew install --cask android-platform-tools
   ```

2. **Turn on USB debugging.** On the phone, open Settings → About phone and tap
   "Build number" seven times to unlock Developer options. Then, in Developer
   options, switch on **USB debugging**.

3. **Authorize the Mac.** Plug the phone in with a real (data-capable) cable and
   run `adb devices`. Accept the "Always allow" prompt on the phone. Running the
   command again should list the device as `device`.

## Install

To run the script from anywhere as `ytcli`, drop it into `~/.local/bin`:

```bash
mkdir -p ~/.local/bin
ln -s "$(pwd)/ytcli.sh" ~/.local/bin/ytcli
```

Using a symlink (`ln -s`) means `git pull` updates the installed command too.
Make sure `~/.local/bin` is on your `PATH` — if `which ytcli` prints nothing,
add this to `~/.zshrc` (or `~/.bashrc`) and restart the shell:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

```bash
ytcli              # opens an editor to paste links
ytcli --clipboard  # reads links from the clipboard instead
```

The run goes like this:

1. yt-dlp is upgraded if a newer version exists (nothing else is touched).
2. A text file opens in the default editor — paste one link per line, save, and
   press Enter back in the terminal. (`--clipboard` skips this and reads
   whatever's on the clipboard.)
3. Everything downloads into `~/Downloads/<timestamp>/`, which then opens in
   Finder.
4. A final `[Y/n]` prompt offers to push the folder to the phone's Downloads.
   Answer `n` to keep the files on the Mac only.

The link file keeps its name between runs, so a cancelled run leaves the links
intact — just clear them before pasting the next batch.
