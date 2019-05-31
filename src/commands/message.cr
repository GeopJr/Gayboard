module Gayboard
  module Message
    BOT.on_message_create do |payload|
      next if payload.author.bot
      # If starts with prefix
      if PREFIX.any? { |p| payload.content.starts_with?("#{p}message") }
        # Stop if its dm
        next unless guild_id = CACHE.resolve_channel(payload.channel_id).guild_id
        begin
          notEnoughArgs = Discord::Embed.new(
            title: "Too few args",
            colour: 0xffff00,
          )
          # Stop if they gave less than 1 arg
          next BOT.create_message(payload.channel_id, "", notEnoughArgs) unless payload.content.gsub(" message", "message").split(" ").size > 1
          isitaNum = payload.content.gsub(" message", "message").split(" ")[1].to_u64 { 0 }
          notaNum = Discord::Embed.new(
            title: "It seems that you didn't provide a positive number",
            description: "Please start over by typing `#{PREFIX[0]}message <messageID>`",
            colour: 0xffff00,
          )
          # Stop if its not a number
          next BOT.create_message(payload.channel_id, "", notaNum) unless isitaNum > 0
          databaseBoard = DB.open "#{MYSQLCONN}gayboard"
          databaseGuild = DB.open "#{MYSQLCONN}guildinfo"
          hasSetuped = databaseGuild.query_one? "SELECT `min_react` FROM `#{guild_id}` LIMIT 1", as: Int32
          notSettedUp = Discord::Embed.new(
            title: "You haven't setted up Gayboard yet",
            description: "Please start by typing `#{PREFIX[0]}gayboard`",
            colour: 0xffff00,
          )
          # Stop if they haven't setted up gayboard yet
          next BOT.create_message(payload.channel_id, "", notaNum) unless !hasSetuped.is_a?(Nil)
          channel_id = databaseBoard.query_one? "SELECT channel_id FROM `#{guild_id}` WHERE message_id = '#{isitaNum}'", as: String
          notinDB = Discord::Embed.new(
            title: "#{isitaNum} is not in the DB",
            colour: 0xff0000,
          )
          # Stop if the message is not in the db
          next BOT.create_message(payload.channel_id, "", notinDB) unless !channel_id.is_a?(Nil)
          # Get it
          foundmsg = BOT.get_channel_message(channel_id.to_u64, isitaNum.to_u64)
          # Get it's reactions
          flags = databaseBoard.query_one? "SELECT `gayflags` FROM `#{guild_id}` WHERE message_id = '#{foundmsg.id}' LIMIT 1", as: Int32
          colors = ["e70000", "ff8c00", "ffef00", "00811f", "0044ff", "760089"]
          # Get it's color
          color = databaseBoard.query_one? "SELECT `color` FROM `#{guild_id}` WHERE message_id = '#{foundmsg.id}' LIMIT 1", as: Int32
          next unless !color.is_a?(Nil)
          # Regex images
          matchedRegex = foundmsg.content.match(/(http(s?):)([\/|.|\w|\s|-])*\.(?:jpg|gif|png|jpeg|webp)/i)
          if foundmsg.attachments.size > 0 && !foundmsg.attachments[0].url.match(/(http(s?):)([\/|.|\w|\s|-])*\.(?:jpg|gif|png|jpeg|webp)/i).is_a?(Nil)
            image = foundmsg.attachments[0].url
          elsif matchedRegex
            image = matchedRegex[0]
          else
            image = ""
          end

          embed = Discord::Embed.new(
            author: Discord::EmbedAuthor.new(
              name: "#{foundmsg.author.username}##{foundmsg.author.discriminator}",
              icon_url: "#{foundmsg.author.avatar_url(512)}"
            ),
            image: Discord::EmbedImage.new(
              url: "#{image}"
            ),
            fields: [
              Discord::EmbedField.new(name: "Reactions :gay_pride_flag:", value: "#{flags}", inline: true),
              Discord::EmbedField.new(name: "Channel", value: "<##{channel_id}>", inline: true),
            ],
            description: "#{foundmsg.content}",
            colour: colors[color].to_u32(16),
            timestamp: foundmsg.timestamp,
          )
          # Send the above embed
          BOT.create_message(payload.channel_id, "", embed)
        rescue ex
          puts "[GAYBOARD ERROR] The following error occurred in #on_message_create"
          puts ex
          puts "[GAYBOARD ERROR END]"
        ensure
          databaseBoard.close unless databaseBoard.nil?
          databaseGuild.close unless databaseGuild.nil?
        end
      end
    end
  end
end
