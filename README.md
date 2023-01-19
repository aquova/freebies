# Freebies

Receive notifications for free games on the Epic Game Store via ntfy.

## Usage

Only requires the Nim compiler, no external libraries are used. Build with:

`nim c -d:ssl freebies.nim`

The program can either be run with its own internal timer via `freebies`, where the program will check at 18:00 UTC whether a new game has been posted.

You can also run the program once with `freebies -c`. This is useful if you instead want to run the program via a cronjob.

Subscribe to your favorite ntfy server to receive notifications. By default, this program uses the `giveaways` topic, although if you plan on using the `ntfy.sh` server, you'll likely want to be a more obscure topic.
