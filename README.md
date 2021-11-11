# Stream-Pi scripts

## Stream-Pi Client installer script for Raspberry Pi

### Quick start

Copy and paste the following command in your terminal. This will install the
client using the recommended defaults.

```sh
wget -qO - https://install.stream-pi.com/client/raspberry-pi | bash
```

### Configuration Options

View all available options with the `-h` or `--help` option.

```
Usage:  [-h | --help] [-v | --verbose]    
        [-d | --download-link] [-g | --gpu-mem]    
        [-i | --install-dir] [-c | --client-dir]
        [-s | --skip-shortcut] [-b | --backlight-no]
        [-ky | --enable-kms] [-kn | --dont-enable-kms] 
        [-z | --zip] [-p | --preserve-old-data]
        [-t | --dont-add-touch] [-at | --axel-threads]

If no arguments are provided, installation will continue using the default
values.
    -h  --help                Print this message.
    -v  --verbose             Print debug information.
    -d  --download-link       Set custom download link for Stream-Pi client.
                              Defaults to the latest stable release.
    -g  --gpu-mem             Set custom GPU memory split, defaults to 128.
    -i  --install-dir         Set custom root installation directory.
                              Defaults to user's home directory.
    -c  --client-dir          Set custom directory for the client application.
                              This will be a sub-directory under 'install-dir',
                              defaults to 'stream-pi-client/'.
    -s  --skip-shortcut       Does not create shortcut in Desktop.
    -b  --backlight-no        Does not modify Official Screen backlight persmissions.
    -ky --enable-kms          Skips user prompt and turns on KMS driver.
    -kn --dont-enable-kms     Skips user prompt and does not turn on KMS driver.
    -z  --zip-file            Use custom zip instead of downloading.
    -p  --preserve-old-data   Skips user data and preserve previous Stream-Pi data (if found).
                              Not recommended for upgrading to different versions.
    -t  --dont-add-touch      Does not add touch support. 
                              Not recommended if Client is to be used in Console mode.
    -at --axel-threads        Specify number of axel threads while downloading. Default is 4.
```

To customize your installation, pass in one or more options to the script.
The script supports both short and long-form option names (or a mix of both)
e.g. `./client-install-raspberry-pi.sh -d <download_link> --gpu-mem 256`.

Sample custom installation:

```sh
wget -qO - https://install.stream-pi.com/client/raspberry-pi | bash -s -- \
-d <custom download link> \
-g <GPU memory> \
-i <install-directory-parent-directory-path> \
-c <custom-directory-name> \
-s -b -ky -at 4
```
