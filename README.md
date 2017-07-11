--------------------------------------------------------------
--------------------------------------------------------------
# DECOMISSIONED for [Mubot](https://github.com/ileathan/Mubot)
--------------------------------------------------------------
--------------------------------------------------------------
# Mubot, A Marking U Bot.

### Status // Version
[![Build Status](https://travis-ci.org/ileathan/hubot-mubot.svg)](https://travis-ci.org/ileathan/hubot-mubot)
[![npm version](https://badge.fury.io/js/hubot-mubot.svg)](http://badge.fury.io/js/hubot-mubot)

### Chat
[![Join the chat at https://gitter.im/ileathan/hubot-mubot](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ileathan/hubot-mubot?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

See [`src/mubot.coffee`](src/mubot.coffee) for full documentation.

## Quick Installation

`npm install hubot-mubot --save`

This must be executed from within the directory where you installed hubot. Please read the Full instalation since you should probably edit the package.json file which is in that same directory.

## Full Instalation

If you do not already have nodejs installed do that now like so: (For trouble shooting see: [Installing node.js](https://github.com/joyent/node/wiki/installing-node.js-via-package-manager))
```bash
sudo apt-get install curl
sudo curl -sL https://deb.nodesource.com/setup | sudo bash -
sudo apt-get install -y nodejs
```

If you do not already have hubot installed do that now like so: (I entered 'irc' as my adapter NOT the default)
```bash
npm install -g hubot coffee-script yo generator-hubot
mkdir -p /path/to/mubot
cd /path/to/mubot
yo hubot
```

**-THIS STEP IS NEEDED-** From within the directory that you ran `yo hubot` run: (Inside your `/path/to/mubot`)
```bash
npm install hubot-mubot --save
````

Then edit your `external-scripts.json` file and add **hubot-mubot**. Afterwords my file looks like this.

```json
[
  "hubot-mubot",
  "hubot-diagnostics",
  "hubot-help",
  "hubot-heroku-keepalive",
  "hubot-google-images",
  "hubot-google-translate",
  "hubot-pugme",
  "hubot-maps",
  "hubot-redis-brain",
  "hubot-rules",
  "hubot-shipit",
  "hubot-youtube"
]

```

To set your initial balance see Troubleshooting.

## Starting your mubot

If during setup of your hubot you selected the irc adapter as i did then this is how you would launch your mubot:
```
HUBOT_ADAPTER=irc HUBOT_IRC_SERVER=irc.swiftirc.net HUBOT_IRC_ROOMS="#AxE" HUBOT_IRC_NICK="Mubot" HUBOT_IRC_UNFLOOD="true" bin/hubot -a irc
```
Alternatively you can add `export` statements in your `/.bashrc` file.

## Sample Interaction

```
leathan>> mubot marks
Mubot>> You have <amount> marks!
```

## Troubleshooting

Q.) I get the following error `ERROR TypeError: Cannot read property '...' of undefined`

A.) You need to set your initial balance, open the file `src/marking.coffee` and find the line:

```
    robot.brain.resetSaveInterval(1) 
```

Then add this line after the above line:

```
    robot.brain.data.credits['...'] ?= <amount>
```

For example, for me that part of `src/marking.coffee` looks like:
```
module.exports = (robot) ->
  robot.brain.on 'loaded', ->
    robot.brain.data.credits ?= {}
    credits = robot.brain.data.credits or {}
    robot.brain.resetSaveInterval(1) 
    robot.brain.data.credits['irc://leathan@irc.swiftirc.net/'] ?= 12000
```

Q.) For further questions.

A.) Visit #AxE @ irc.swiftirc.net
