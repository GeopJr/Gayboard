require "../functions/isadmin.cr"

module Gayboard
  module Min
    BOT.on_message_create do |payload|
      next if payload.author.bot
      # If starts with prefix
      if PREFIX.any? { |p| payload.content.starts_with?("#{p}min") }
        # Stop if its dm
        next unless guild_id = CACHE.resolve_channel(payload.channel_id).guild_id
        begin
          notAdmin = Discord::Embed.new(
            title: "You don't have the ADMINISTRATOR perm!",
            colour: 0xffff00,
          )
          # Check if they have admin perms
          next BOT.create_message(payload.channel_id, "", notAdmin) unless IsAdmin.new(BOT, CACHE.resolve_member(guild_id, payload.author.id).roles, guild_id, payload.author.id).anyTrue
          notEnoughArgs = Discord::Embed.new(
            title: "Too few args",
            colour: 0xffff00,
          )
          # Check if they provided more than 1 args
          next BOT.create_message(payload.channel_id, "", notEnoughArgs) unless payload.content.gsub(" min", "min").split(" ").size > 1
          isitaNum = payload.content.gsub(" min", "min").split(" ")[1].to_i { 0 }
          notaNum = Discord::Embed.new(
            title: "It seems that you didn't provide a positive number",
            description: "Please start over by typing `#{PREFIX[0]}min <number>`",
            colour: 0xffff00,
          )
          # Check if they provided a positive number
          next BOT.create_message(payload.channel_id, "", notaNum) unless isitaNum > 0
          # Open database
          databaseGuild = DB.open "#{MYSQLCONN}guildinfo"
          # Check if they have setted up gayboard
          hasSetuped = databaseGuild.query_one? "SELECT `min_react` FROM `#{guild_id}` LIMIT 1", as: Int32
          notSettedUp = Discord::Embed.new(
            title: "You haven't setted up Gayboard yet",
            description: "Please start by typing `#{PREFIX[0]}gayboard`",
            colour: 0xffff00,
          )
          next BOT.create_message(payload.channel_id, "", notaNum) unless !hasSetuped.is_a?(Nil)
          done = Discord::Embed.new(
            title: "Done!",
            colour: 0xffff00,
          )
          # Update db
          begin
            databaseGuild.exec "UPDATE `#{guild_id}` SET `min_react` = #{isitaNum}"
            BOT.create_message(payload.channel_id, "", done)
          rescue
            BOT.create_message(payload.channel_id, "", notSettedUp)
          end
        rescue ex
          puts "[GAYBOARD ERROR] The following error occurred in #on_message_create"
          puts ex
          puts "[GAYBOARD ERROR END]"
        ensure
          databaseGuild.close unless databaseGuild.nil?
        end
      end
    end
  end
end
