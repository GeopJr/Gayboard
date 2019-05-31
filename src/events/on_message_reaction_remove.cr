require "../functions/colorembed.cr"
require "../functions/cachedchannel.cr"

module Gayboard
  module Reaction_Remove
    BOT.on_message_reaction_remove do |things|
      # Stop if the reaction is not the lgbt flag
      next unless things.emoji.name == "🏳️‍🌈"
      # Stop if its dm
      next unless guild_id = CACHE.resolve_channel(things.channel_id).guild_id
      cachedID = CachedChannel.new(BOT, CACHE.channels, guild_id).id.to_u64
      # Stop if there's no gayboard channel
      next unless cachedID != 0_64
      begin
        # Get the message that got the reaction
        reactedMessage_currently = BOT.get_channel_message(things.channel_id, things.message_id)
        # If the channel that got reacted to is gayboard, get the original message it is refering to, else get the one that got the reaction
        case things.channel_id.to_u64
        when cachedID
          # If the bot is not the one who made the embed, stop
          next raise "Not my embed" unless reactedMessage_currently.author.id.to_s == "#{CONFIG["client_id"]}"
          # Regex the channel and message id from the embed
          reacted_msg_ID = reactedMessage_currently.embeds[0].footer.not_nil!.text.not_nil!.split("|")[2].match(/\d+/).not_nil![0].to_u64
          reacted_msg_channelID = reactedMessage_currently.embeds[0].description.not_nil!.split("\n").reverse[1].match(/\#(\d+)/).not_nil!.to_a[0].not_nil!.gsub("#", "").to_u64
          # Get the original message
          reactedMessage = BOT.get_channel_message(reacted_msg_channelID, reacted_msg_ID)
          reactedMessageReactions = reactedMessage.reactions
          countReactions = 0
          countReactions_new = 0
          # Count original message's reactions
          case reactedMessageReactions
          when Nil
            countReactions = 0
          else
            reactedMessageReactions.each do |react|
              next unless react.emoji.name == "🏳️‍🌈"
              countReactions = react.count
            end
          end

          reactedMessageReactions_currently = reactedMessage_currently.reactions
          # Count embed's reactions
          case reactedMessageReactions_currently
          when Nil
            countReactions_new = 0
          else
            reactedMessageReactions_currently.each do |react|
              next unless react.emoji.name == "🏳️‍🌈"
              countReactions_new = react.count
            end
          end
          # Add them
          countReactions = countReactions + countReactions_new
        else
          reacted_msg_ID = things.message_id
          reacted_msg_channelID = things.channel_id
          reactedMessage = reactedMessage_currently
          countReactions = 0
          reactedMessageReactions = reactedMessage.reactions
          # Count original message's reactions
          case reactedMessageReactions
          when Nil
            countReactions = 0
          else
            reactedMessageReactions.each do |react|
              next unless react.emoji.name == "🏳️‍🌈"
              countReactions = react.count
            end
          end
        end
        hasReacted = false
        # Connect to databases
        databaseUsers = DB.open "#{MYSQLCONN}gayreactors"
        databaseBoard = DB.open "#{MYSQLCONN}gayboard"
        databaseGuild = DB.open "#{MYSQLCONN}guildinfo"
        # Stop if the user reacted to their own message
        next if things.user_id.to_s == reactedMessage.author.id.to_s
        # Check if message already in db, if not add it
        theyReacted = databaseUsers.query_one? "select `message_id` FROM `#{things.user_id}` WHERE `message_id` = '#{reacted_msg_ID.to_s}' limit 1", as: String
        case theyReacted
        when Nil
          raise "User [#{things.user_id}]-[#{reacted_msg_ID.to_s}] is not in the database"
        else
          databaseUsers.exec "DELETE FROM `#{things.user_id}` WHERE `message_id` = '#{reacted_msg_ID.to_s}' limit 1"
          hasReacted = true
        end
        # I... don't remember/know why I put this here, and why the code still works, so I'll pretend it does something
        next unless hasReacted
        # Check if they have setted up gayboard else stop
        hasSetuped = databaseGuild.query_one? "SELECT `min_react` FROM `#{guild_id}` LIMIT 1", as: Int32
        next unless !hasSetuped.is_a?(Nil)
        min_reacts = hasSetuped
        # Check if message was found in db, if not add it, and send msg in gayboard, then stop
        found_msgID = databaseBoard.query_one? "SELECT `message_id` FROM `#{guild_id}` WHERE `message_id` = '#{reacted_msg_ID.to_s}' LIMIT 1", as: String
        next unless found_msgID
        # Check if gayboard message was found in db, if not add it, and send msg in gayboard, then stop
        gayboard_msgID = databaseBoard.query_one? "SELECT `gayboard_id` FROM `#{guild_id}` WHERE `message_id` = '#{reacted_msg_ID.to_s}' LIMIT 1", as: String
        next unless gayboard_msgID
        # Get the old embed from gayboard
        oldEmbed = BOT.get_channel_message(cachedID, gayboard_msgID.to_s.to_u64).embeds[0]
        # Claculate new color shade
        editedcolorHex = databaseBoard.query_one? "SELECT `color` FROM `#{guild_id}` WHERE `gayboard_id` = '#{gayboard_msgID.to_s}' limit 1", as: Int32
        next unless editedcolorHex
        updatedColor = ColorEmbed.new(editedcolorHex.to_s.to_i, min_reacts.to_s.to_i, countReactions).color.to_u32(16)
        # Edit embed in gayboard and update db
        editedItem = Discord::Embed.new(
          author: Discord::EmbedAuthor.new(
            name: "#{reactedMessage.author.username}##{reactedMessage.author.discriminator}",
            icon_url: "#{reactedMessage.author.avatar_url(512)}"
          ),
          footer: Discord::EmbedFooter.new(
            text: "#{HEARTS[editedcolorHex.to_s.to_i]} | #{countReactions} 🏳️‍🌈 | ID: #{reacted_msg_ID}"
          ),
          image: oldEmbed.image,
          timestamp: reactedMessage.timestamp,
          description: oldEmbed.description,
          colour: updatedColor
        )
        BOT.edit_message(cachedID, gayboard_msgID.to_s.to_u64, "", editedItem)
        databaseBoard.exec "UPDATE `#{guild_id}` SET `gayflags` = #{countReactions.to_i} WHERE `message_id` = '#{reacted_msg_ID.to_s}'"
      rescue ex
        next unless ex.message != "Not my embed"
        puts "[GAYBOARD ERROR] The following error occurred in #on_message_reaction_remove"
        puts ex
        puts "[GAYBOARD ERROR END]"
      ensure
        # Close databases, but also inform if they opened or not
        begin
          databaseUsers.not_nil!.close
          databaseBoard.not_nil!.close
          databaseGuild.not_nil!.close
        rescue
          puts "[GAYBOARD ERROR] The following error occurred in #on_message_reaction_add"
          puts "Databse never opened"
          puts "[GAYBOARD ERROR END]"
        end
      end
    end
  end
end
