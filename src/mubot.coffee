# Description:
#   A Marking U Bot.
#
# Dependencies:
#   bitmarkd must be running
#   bitmark-cli must be in path
#   wallet must be funded
#
# Configuration:
#   
#
# Commands:
#   + <times> <user> <reason>        -   Marks the specified user.
#   withdraw <address> <amount>      -   withdraw to address amount.
#   deposit                          -   Display the your address.
#   marks <user>                     -   balance for a user (will be depreciated soon).
#   + <times>                        -   mark the last user with his comment as the reason.
#
# Author:
#   Project Bitmark
#


# requires
exec = require('child_process').exec;
sqlite3 = require('sqlite3').verbose();


# init
db = new sqlite3.Database('marks');

credits  = {} # simple key value store or URI / balance for now
symbol   = '₥'
last     = 'mubot'
secret   = process.env.HUBOT_DEPOSIT_SECRET

if process.env.HUBOT_ADAPTER is 'irc'
  adapter = 'irc'
  irc_server = process.env.HUBOT_IRC_SERVER
else if process.env.HUBOT_ADAPTER is 'slack'
  adapter = 'slack'
  slack_team = process.env.HUBOT_SLACK_TEAM
else if process.env.HUBOT_ADAPTER is 'shell'
  adapter = 'shell'
else
  adapter = 'irc' | throw new Error('HUBOT_ADAPTER env variable is required') 


# functions
to_URI = ( id ) ->
  id = id.toLowerCase()
  if id.indexOf(':') != -1
    id
  else if adapter is 'irc'
    'irc://' + id + '@' + irc_server + '/'
  else if adapter is 'slack'
    'https://' + slack_team + '.slack.com/team/' + id + '#this'
  else if adapter is 'shell'
    'urn:shell:' + id
  else
     id

from_URI = ( URI ) ->
  if URI.indexOf('irc://') is 0 and adapter is 'irc'
    URI.split(":")[1].substring(2).split('@')[0]
  else if URI.indexOf('https://' + slack_team + '.slack.com/team/') is 0 and URI.indexOf('#this') != -1 and adapter is 'slack'
    URI.split(":")[1].substring(2).split('/')[2].split('#')[0]
  else
    URI

#   Decommisioned
#   deposit  <user> <amount> <secret> - deposit amount using shared secret
deposit_credits = (msg, URI, amount, robot) ->
  robot.brain.data.credits[URI] ?= 0
  robot.brain.data.credits[URI] += parseFloat(amount)
  msg.send amount + symbol + ' to ' + from_URI(URI)

transfer_credits = (msg, URI, amount, robot) ->
  if robot.brain.data.credits[to_URI(msg.message.user.name)] >= parseFloat(amount)
    robot.brain.data.credits[URI] ?= 0
    robot.brain.data.credits[URI] += parseFloat(amount)
    robot.brain.data.credits[to_URI(msg.message.user.name)] -= parseFloat(amount)
    msg.send amount + symbol + ' has been awarded to ' + from_URI(URI)
  else
    msg.send 'sorry, not enough funds'


withdraw_credits = (msg, address, amount, robot) ->
  if robot.brain.data.credits[to_URI(msg.message.user.name)] >= parseFloat(amount)
    command = 'bitmark-cli sendtoaddress ' + address + ' ' + ( parseFloat(amount) / 1000.0 )
    console.log(command)
    exec command, (error, stdout, stderr) ->
      console.log(error)
      console.log(stdout)
      console.log(stderr)
      robot.brain.data.credits[to_URI(msg.message.user.name)] -= parseFloat(amount)
      msg.send stdout
  else
    msg.send 'not enough funds'


save = (robot) ->
  robot.brain.data.credits = robot.brain.data.credits


# MAIN
module.exports = (robot) ->
  robot.brain.on 'loaded', ->
    robot.brain.data.credits ?= {}
    credits = robot.brain.data.credits or {}
    robot.brain.resetSaveInterval(1)
    # SETTING INITIAL BALANCE 
    # robot.brain.data.credits[URI] ?= 0 Uncomment this line and replace URI with your usename. 
    # For example bellow is how I set my initial balance to 12000 marks:
    robot.brain.data.credits['irc://leathan@irc.swiftirc.net/'] ?= 12000
    # If I was using the slack adapter and not the irc adapter I would do:
    #   robot.brain.data.credits['https://projectbitmark.slack.com/team/leathan#this'] ?= 12000


  # DEPOSIT
  robot.hear /deposit\s+(\d+)\s+([\w\S]+)\s+([\w\S]*)$/i, (msg) ->
    if msg.match[3] is secret
      msg.send 'deposit to ' + msg.match[2] + ' ' + msg.match[1]
      deposit_credits(msg, to_URI(msg.match[2]), msg.match[1], robot)
      save(robot)
        
  # TRANSFER
  robot.hear /^(transfer|mark)\s+@?([\w\S]+)\s*(\d+)\s*$/i, (msg) ->
    transfer_credits(msg, to_URI(msg.match[2]), msg.match[3], robot)
    save(robot)

  robot.hear /^(transfer|mark)\s+@?([\w\S]+)\s*$/i, (msg) ->
    transfer_credits(msg, to_URI(msg.match[2]), 1, robot)
    save(robot)

  robot.hear /^\+(\d+)\s*$/i, (msg) ->
    plus = msg.match[1]
    if plus <= 25
      transfer_credits(msg, to_URI(last), plus, robot)
    else
      msg.send 'Max is +25'
    save(robot)

  # WITHDRAW
  robot.hear /withdraw\s+([\w\S]+)\s+(\d+)\s*$/i, (msg) ->
    destination = msg.match[1]
    if destination is 'foundation'
      destination = 'bQmnzVS5M4bBdZqBTuHrjnzxHS6oSUz6cG'
    withdraw_credits(msg, destination, msg.match[2], robot)
    save(robot)
    
  # BALANCE
  robot.hear /^balance\s+@?([\w\S]+)\s*$/i, (msg) ->
    #redis-brain.getData()
    URI = to_URI(msg.match[1])
    #msg.send('to URI is : ' + URI)
    #msg.send('from URI is : ' + from_URI(URI))
    robot.brain.data.credits[URI] ?= 0
    msg.send from_URI(URI) + ' has ' + robot.brain.data.credits[URI] + symbol

  robot.hear /^balance\s*$/i, (msg) ->
    URI = to_URI(msg.message.user.name)
    #msg.send('to URI is : ' + URI)
    #msg.send('from URI is : ' + from_URI(URI))
    robot.brain.data.credits[URI] ?= 0
    msg.send from_URI(URI) + ' has ' + robot.brain.data.credits[URI] + symbol

  # WEB
  
  robot.router.get "/marks", (req, res) ->
    res.end JSON.stringify(robot.brain.data.credits)
    
  # LISTEN
  robot.hear /.*/i, (msg) ->
    last = msg.message.user.name
    console.log("[" + (new Date).toLocaleTimeString() + "] " + msg.message.text)
