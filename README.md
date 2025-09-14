# guix-channel

My (WIP) Guix channel for packages and services I use that aren't available in other Guix
channels.

## Installation

Add this channel to your `/etc/guix/channels.scm` or `~/.config/guix/channels.scm`:

```
(channel
  (name 'cottoncammy)
  (url "https://github.com/cottoncammy/guix-channel")
  (branch "main")
  (introduction
    (make-channel-introduction
      "d688f4faf092ecf9e89cde82adc760225a772a3a"
      (openpgp-fingerprint
        "246D A2B4 3BD4 D61B 0C91  1CCE C96F 79D9 D5B9 819D"))))
```

Then run `guix pull`.
