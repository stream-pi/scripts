# Stream-Pi scripts

## Stream-Pi Client installer script for Raspberry Pi

### Quick start

Copy and paste the following command in your terminal. This will install the
client using the recommended defaults.

```sh
curl -sSL https://install.stream-pi.com/client/raspberry-pi | bash
```

### Configuration Options

View all available options with the `-h` or `--help` option.

```sh
$ ./client-install-raspberry-pi.sh -h

Usage: client-install-raspberry-pi.sh [-h | --help] [-v | --verbose]    
                                      [-d | --download-link] [-g | --gpu-mem]    
                                      [-i | --install-dir] [-c | --client-dir]
                                      [-s | --skip-shortcut]

If no arguments are provided, installation will continue using the default
values.

    -h --help           Print this message
    -v --verbose        Print debug information
    -d --download-link  Set custom download link for Stream-Pi client.
                        Defaults to the latest stable release.
    -g --gpu-mem        Set custom GPU memory split, defaults to 128.
    -i --install-dir    Set custom root installation directory.
                        Defaults to user's home directory.
    -c --client-dir     Set custom directory for the client application.
                        This will be a sub-directory under 'install-dir',
                        defaults to 'stream-pi-client/'
    -s --skip-shortcut  Does not create shortcut in Desktop
```

To customize your installation, pass in one or more options to the script.
The script supports both short and long-form option names (or a mix of both)
e.g. `./client-install-raspberry-pi.sh -d <download_link> --gpu-mem 256`.

Sample custom installation:

```sh
curl -sSL https://install.stream-pi.com/client/raspberry-pi | bash -s -- \
-d <custom download link> \
-g <GPU memory> \
-i <install-directory-parent-directory-path> \
-c <custom-directory-name>
```
