module Gayboard
  module Stats
    BOT.on_message_create do |payload|
      next if payload.author.bot
      # If starts with prefix
      if PREFIX.any? { |p| payload.content.starts_with?("#{p}stats") }
        # Stop if its dm
        next unless guild_id = CACHE.resolve_channel(payload.channel_id).guild_id
        begin
          # Open databases
          databaseUsers = DB.open "#{MYSQLCONN}gayreactors"
          databaseBoard = DB.open "#{MYSQLCONN}gayboard"
          databaseGuild = DB.open "#{MYSQLCONN}guildinfo"
          # Check if they have setted up gayboard
          hasSetuped = databaseGuild.query_one? "SELECT `min_react` FROM `#{guild_id}` LIMIT 1", as: Int32
          notSettedUp = Discord::Embed.new(
            title: "You haven't setted up Gayboard yet",
            description: "Please start by typing `#{PREFIX[0]}gayboard`",
            colour: 0xffff00,
          )
          next BOT.create_message(payload.channel_id, "", notSettedUp) unless !hasSetuped.is_a?(Nil)
          contentArray = payload.content.gsub(" stats", "stats").split(" ")
          memberID = 0
          # Check if they provided any args or mentions
          if contentArray.size > 1
            if payload.mentions.size > 0
              begin
                memberID = CACHE.resolve_member(guild_id, payload.mentions[0].id).user.id
              rescue
              end
            elsif contentArray[1].to_u64 { 0 } > 0
              begin
                memberID = CACHE.resolve_member(guild_id, contentArray[1].to_u64).user.id
              rescue
              end
            end
          end
          fields = [] of Discord::EmbedField
          top3msgesValue = [] of String
          # If they provided any args or mentions
          if contentArray.size > 1 && memberID.to_u64 > 0_64
            # Get the amount of messages mention user has reacted to
            amountMsgs = databaseUsers.query_one? "SELECT count(id) c FROM `#{memberID}` WHERE guild_id = '#{guild_id}' group BY guild_id order by c DESC LIMIT 1", as: Int64
            # Get the amount of messages mention user has made and got into gayboard
            amountMsgsAppeared = databaseBoard.query_one? "SELECT count(id) c FROM `#{guild_id}` WHERE author = '#{memberID}' group BY author order by c DESC LIMIT 1", as: Int64

            flags = 0
            # Get most reactions mentioned user got
            mostFlags = databaseBoard.query_all "SELECT gayflags FROM `#{guild_id}` WHERE `author` = '#{memberID}'", as: Int32
            mostFlags.each do |flag|
              flags = flags + flag
            end
            # Get their top 3 messages
            top3msges = databaseBoard.query_all "select message_id,gayflags from `#{guild_id}` WHERE `author` = '#{memberID}' order by gayflags desc limit 3", as: {String, Int32}
            top3msges.each do |tuple|
              top3msgesValue << "`#{tuple[0]}` | `#{tuple[1]}` :gay_pride_flag:"
            end
            if top3msgesValue.size > 0
              top3msgesString = top3msgesValue.join("\n")
            else
              top3msgesString = "0 :gay_pride_flag:"
            end
            # Put them into embed fields and send it
            fields << Discord::EmbedField.new(name: "**Amount of :gay_pride_flag: given**", value: "**#{amountMsgs || "0"} :gay_pride_flag:**", inline: true)
            fields << Discord::EmbedField.new(name: "**Amount of :gay_pride_flag: received**", value: "**#{flags || "0"} :gay_pride_flag:**", inline: true)
            fields << Discord::EmbedField.new(name: "**Amount of messages appeared on :gay_pride_flag:**", value: "**#{amountMsgsAppeared || "0"} Messages**", inline: true)
            fields << Discord::EmbedField.new(name: "**Top #{top3msges.size} most :gay_pride_flag: messages**", value: "**#{top3msgesString}**", inline: true)

            embed = Discord::Embed.new(
              title: "Stats for #{memberID}!",
              colour: 0xffff00,
              fields: fields
            )
            BOT.create_message(payload.channel_id, "", embed)
          else
            top3usersReceivedValue = [] of String
            top3usersWentValue = [] of String
            top3amountofMsgs = {} of String => Int64
            top3amountofMsgsSorted = [] of String
            # Get top 3 messages with most reactions
            top3msges = databaseBoard.query_all "select message_id,gayflags from `#{guild_id}` order by gayflags desc limit 3", as: {String, Int32}
            top3msges.each do |tuple|
              top3msgesValue << "`#{tuple[0]}` | `#{tuple[1]}` :gay_pride_flag:"
            end
            # Get most reactions received each author and their most reacted msgs
            groupedAuthors = databaseBoard.query_all "SELECT author, count(author) c FROM `#{guild_id}` group by author order by c DESC LIMIT 3", as: {String, Int64}
            groupedAuthors.each do |tuple|
              flags = 0
              mostFlags = databaseBoard.query_all "SELECT gayflags FROM `#{guild_id}` WHERE `author` = '#{tuple[0]}'", as: Int32
              mostFlags.each do |flag|
                flags = flags + flag
              end
              top3usersReceivedValue << "<@#{tuple[0]}> | `#{flags}` :gay_pride_flag:"
              top3usersWentValue << "<@#{tuple[0]}> | `#{tuple[1]}` :gay_pride_flag:"
            end
            # Iterate over every user that has reacted and count to how many msgs the have reacted to
            eachUser = databaseUsers.query_all "SHOW TABLES", as: String
            eachUser.each do |userid|
              amountMsgs = databaseUsers.query_one? "SELECT count(id) c FROM `#{userid}` WHERE guild_id = '#{guild_id}' group BY guild_id order by c DESC LIMIT 1", as: Int64
              next unless !amountMsgs.is_a?(Nil)
              top3amountofMsgs[userid] = amountMsgs
            end
            # Sort authors and their most reacted msgs
            top3amountofMsgs.to_a.sort_by { |key, value| value }.each do |tuple|
              top3amountofMsgsSorted << "<@#{tuple[0]}> | `#{tuple[1]}` :gay_pride_flag:"
            end
            # Put them into embed fields and send it
            fields << Discord::EmbedField.new(name: "**Top #{top3msges.size} most :gay_pride_flag: messages**", value: "**#{top3msgesValue.join("\n")}**", inline: true)
            fields << Discord::EmbedField.new(name: "**Top #{top3usersReceivedValue.size} most :gay_pride_flag: users received**", value: "**#{top3usersReceivedValue.join("\n")}**", inline: true)
            fields << Discord::EmbedField.new(name: "**Top #{top3usersWentValue.size} most appeared users**", value: "**#{top3usersWentValue.join("\n")}**", inline: true)
            fields << Discord::EmbedField.new(name: "**Top #{top3amountofMsgsSorted.size} most :gay_pride_flag: users gave**", value: "**#{top3amountofMsgsSorted.reverse.join("\n")}**", inline: true)

            embed = Discord::Embed.new(
              title: "Stats for this guild!",
              colour: 0xffff00,
              fields: fields
            )
            BOT.create_message(payload.channel_id, "", embed)
          end
        rescue ex
          embed = Discord::Embed.new(
            title: "It appears that I don't have enough info for this guild or user!",
            colour: 0xff0000
          )
          BOT.create_message(payload.channel_id, "", embed)
        ensure
          databaseUsers.close unless databaseUsers.nil?
          databaseBoard.close unless databaseBoard.nil?
          databaseGuild.close unless databaseGuild.nil?
        end
      end
    end
  end
end
