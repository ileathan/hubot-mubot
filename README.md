# hubot-mubot

Mubot, A Marking U Bot.

See [`src/mubot.coffee`](src/mubot.coffee) for full documentation.

## Quick Installation

In hubot project repo, (the directory where hubot resides) run:

`npm install hubot-mubot --save`

Then add **hubot-mubot** to your `external-scripts.json`:

```json
["hubot-mubot"]
```

## Full Instalation

Download setup and install nodejs. (For trouble shooting see: [Installing node.js](https://github.com/joyent/node/wiki/installing-node.js-via-package-manager))
```bash
sudo apt-get install curl
curl -sL https://deb.nodesource.com/setup | bash -
sudo apt-get install -y nodejs
npm install -g hubot coffee-script yo generator-hubot
mkdir -p /path/to/mubot
cd /path/to/mubot
yo hubot
npm install hubot-mubot --save
```

Then add **hubot-mubot** to your `external-scripts.json:`

```json
["hubot-mubot"]
```

## Sample Interaction

```
leathan>> mubot marks
Mubot>> You have <amount> marks!
```
