require "discordcr"
require "yaml"
require "mysql"

# Requiring all the files
require "./commands/*"
require "./events/*"

# Config
CONFIG = YAML.parse(File.read("./config.yaml"))
# Check if everything required is filled in the config
raise "You didn't provide a prefix in your config" if CONFIG["prefix"].to_s == ""
raise "You didn't provide a client_id in your config" if CONFIG["client_id"].to_s == ""
raise "You didn't provide a my_id in your config" if CONFIG["my_id"].to_s == ""
raise "You didn't provide a mysql_user in your config" if CONFIG["mysql_user"].to_s == ""
raise "You didn't provide a mysql_host in your config" if CONFIG["mysql_host"].to_s == ""
# Create the mysql url based on what has been filled in the config
MYSQLCONN = if CONFIG["mysql_pass"].to_s == "" && CONFIG["mysql_port"].to_s == "" == ""
              "mysql://#{CONFIG["mysql_user"]}@#{CONFIG["mysql_host"]}/"
            elsif CONFIG["mysql_pass"].to_s == ""
              "mysql://#{CONFIG["mysql_user"]}@#{CONFIG["mysql_host"]}:#{CONFIG["mysql_port"]}/"
            elsif CONFIG["mysql_port"].to_s == ""
              "mysql://#{CONFIG["mysql_user"]}:#{CONFIG["mysql_pass"]}@#{CONFIG["mysql_host"]}/"
            else
              "mysql://#{CONFIG["mysql_user"]}:#{CONFIG["mysql_pass"]}@#{CONFIG["mysql_host"]}:#{CONFIG["mysql_port"]}/"
            end
# Prefixes
PREFIX = ["#{CONFIG["prefix"]}", "<@#{CONFIG["client_id"]}>", "<@#{CONFIG["client_id"]}> ", "<@!#{CONFIG["client_id"]}> ", "<@!#{CONFIG["client_id"]}>"]
# Uptime used for the bot's uptime on the info command
UPTIMER = Time.utc_now
# Const used in the reaction events
HEARTS = ["❤️", "🧡", "💛", "💚", "💙", "💜"]

module Gayboard
  # Initialize bot
  BOT = Discord::Client.new(token: "Bot #{CONFIG["token"]}", client_id: CONFIG["client_id"].to_s.to_u64)
  # Const cache so we don't api spam
  CACHE = Discord::Cache.new(BOT)
  # Create the databases if they don't exist
  DB.open "#{MYSQLCONN}" do |db|
    db.exec "create database if not exists guildinfo"
    db.exec "create database if not exists gayboard"
    db.exec "create database if not exists gayreactors"
  end
  # Ready event
  BOT.on_ready do |things|
    # Guild count
    servers = things.guilds.size
    # Change status every 1 min
    Discord.every(60000.milliseconds) do
      stats = [
        "discord.gg/SWEsj6q",
        "geopjr.xyz",
        "Geop crying",
      ]
      BOT.status_update("online", Discord::GamePlaying.new(name: "#{stats.sample} | #{CONFIG["prefix"]}help | #{servers} servers", type: 3_i64))
    end
  end
  BOT.run
end
