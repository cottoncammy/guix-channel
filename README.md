# guix-channel

My (WIP) Guix channel for packages and services I use that aren't available in other Guix
channels.

## Installation

Add the following channel to your `/etc/guix/channels.scm` or
`~/.config/guix/channels.scm`:

```
(channel
  (name 'cottoncammy)
  (url "https://github.com/cottoncammy/guix-channel")
  (branch "main"))
```

Then run `guix pull --disable-authentication`.
