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


# 
# requires
exec = require('child_process').exec;
# sqlite3 = require('sqlite3').verbose(); 


# init
# db = new sqlite3.Database('marks');

marks  = {} # simple key value store or URI / balance for now
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
  adapter = 'irc' or throw new Error('HUBOT_ADAPTER env variable is required') 


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
deposit_marks = (msg, URI, amount, robot) ->
  robot.brain.data.marks[URI] ?= 0
  robot.brain.data.marks[URI] += parseFloat(amount)
  msg.send amount + symbol + ' to ' + from_URI(URI)

transfer_marks = (msg, URI, amount, robot) ->
  why_context = msg.match[3] or msg.match[2]
  if !why_context?
    console.log "NOT WHY NOT WHY NOT WHY"
    console.log "NOT WHY NOT WHY NOT WHY"
    console.log "NOT WHY NOT WHY NOT WHY"
  if why_context is undefined
    console.log "11111111NOT WHY NOT WHY NOT WHY"
    console.log "11111111111NOT WHY NOT WHY NOT WHY"
    console.log "1111111111NOT WHY NOT WHY NOT WHY"
  if !why_context? or why_context is from_URI(URI)
    why_context = "N/A"
  if robot.brain.data.marks[to_URI(msg.message.user.name)] >= parseFloat(amount)
    robot.brain.data.marks[URI] ?= 0
    robot.brain.data.marks[URI] += parseFloat(amount)
    robot.brain.data.marks[to_URI(msg.message.user.name)] -= parseFloat(amount)
    msg.send msg.message.user.name + ' has marked ' + from_URI(URI) + ' ' + amount + symbol + '. ( ' + why_context + ' )'
  else
    msg.send 'Sorry, no one has marked you yet. Try the deposit command.'


withdraw_marks = (msg, address, amount, robot) ->
  if robot.brain.data.marks[to_URI(msg.message.user.name)] >= parseFloat(amount)
    command = 'bitmark-cli sendtoaddress ' + address + ' ' + ( parseFloat(amount) / 1000.0 )
    console.log(command)
    exec command, (error, stdout, stderr) ->
      console.log(error)
      console.log(stdout)
      console.log(stderr)
      robot.brain.data.marks[to_URI(msg.message.user.name)] -= parseFloat(amount)
      msg.send stdout
  else
    msg.send 'Sorry, you have not been marked that many times yet.'


save = (robot) ->
  robot.brain.data.marks = robot.brain.data.marks


# MAIN
module.exports = (robot) ->
  robot.brain.on 'loaded', ->
    robot.brain.data.marks ?= {}
    marks = robot.brain.data.marks or {}
    robot.brain.resetSaveInterval(1)
    # SETTING INITIAL BALANCE 
    # robot.brain.data.marks[URI] ?= 0 Uncomment this line and replace URI with your usename. 
    # For example bellow is how I set my initial balance to 12000 marks:
    robot.brain.data.marks['irc://leathan@irc.swiftirc.net/'] ?= 12000
    # If I was using the slack adapter and not the irc adapter I would do:
    #   robot.brain.data.marks['https://projectbitmark.slack.com/team/leathan#this'] ?= 12000


  # DEPOSIT
  robot.hear /deposit\s+(\d+)\s+([\w\S]+)\s+([\w\S]*)$/i, (msg) ->
    if msg.match[3] is secret
      msg.send 'deposit to ' + msg.match[2] + ' ' + msg.match[1]
      deposit_marks(msg, to_URI(msg.match[2]), msg.match[1], robot)
      save(robot)
        
  # TRANSFER
  robot.hear /^mark @?([\w\S]+) (\d+)$/i, (msg) ->
    transfer_marks(msg, to_URI(msg.match[1]), msg.match[2], robot)
    save(robot)

  robot.hear /^mark @?([\w\S]+)$/i, (msg) ->
    transfer_marks(msg, to_URI(msg.match[1]), 1, robot)
    save(robot)

  robot.hear /^\+(\d+)\s@?([\w\S]+) ?(.*)?$/i, (msg) ->
    console.log "MESSAGE DOT MATCH IS"
    console.log "MESSAGE DOT MATCH IS"
    console.log msg.match[3]
    plus = msg.match[1]
    if plus <= 25
      transfer_marks(msg, to_URI(msg.match[2]), plus, robot)
    else
      msg.send 'Max is +25'
    save(robot)

  robot.hear /^\+(\d+)$/i, (msg) ->
    plus = msg.match[1]
    if plus <= 25
      console.log last
      transfer_marks(msg, to_URI(last), plus, robot)
    else
      msg.send 'Max is +25'
    save(robot)

  # WITHDRAW
  robot.hear /withdraw\s+([\w\S]+)\s+(\d+)\s*$/i, (msg) ->
    destination = msg.match[1]
    if destination is 'foundation'
      destination = 'bQmnzVS5M4bBdZqBTuHrjnzxHS6oSUz6cG'
    withdraw_marks(msg, destination, msg.match[2], robot)
    save(robot)
    
  # BALANCE
  robot.hear /^balance\s+@?([\w\S]+)\s*$/i, (msg) ->
    URI = to_URI(msg.match[1])
    robot.brain.data.marks[URI] ?= 0
    msg.send from_URI(URI) + ' has ' + robot.brain.data.marks[URI] + symbol

  robot.hear /^balance\s*$/i, (msg) ->
    URI = to_URI(msg.message.user.name)
    robot.brain.data.marks[URI] ?= 0
    msg.send from_URI(URI) + ' has ' + robot.brain.data.marks[URI] + symbol + '.'

  # WEB 
  robot.router.get "/#{robot.name}/marks", (req, res) ->
    res.end JSON.stringify(robot.brain.data.marks)
    
  # LISTEN
  robot.hear /.*/i, (msg) ->
    last = msg.message.user.name
    console.log("[" + (new Date).toLocaleTimeString() + "] " + msg.message.text)