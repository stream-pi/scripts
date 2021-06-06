# Stream-Pi scripts

## Stream-Pi Client installer script for Raspberry Pi

Copy and paste the following command in your terminal.
This will install the client in the current user's home directory (`$HOME`).

```sh
curl -sSL https://install.stream-pi.com/client/raspberry-pi | bash
```

To use a custom installation directory, pass the path to the installer script. You can also specify a custom zip (structure should be similar to default zip)

```sh
curl -sSL https://install.stream-pi.com/client/raspberry-pi | bash -s -- path/to/your/dir https://custom-url/stream-pi.zip
```
