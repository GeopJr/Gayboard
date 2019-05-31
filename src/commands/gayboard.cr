require "../functions/awaitmanager.cr"

module Gayboard
  module Gayboard
    # New await manager
    await_manager = AwaitManager.new(BOT)
    BOT.on_message_create do |payload|
      next if payload.author.bot
      # If starts with prefix
      if PREFIX.any? { |p| payload.content.starts_with?("#{p}gayboard") }
        begin
          # Stop if its dm
          next unless guild_id = CACHE.resolve_channel(payload.channel_id).guild_id
          notAdmin = Discord::Embed.new(
            title: "You don't have the ADMINISTRATOR perm!",
            colour: 0xffff00,
          )
          # Stop if they don't have admin perm
          next BOT.create_message(payload.channel_id, "", notAdmin) unless IsAdmin.new(BOT, CACHE.resolve_member(guild_id, payload.author.id).roles, guild_id, payload.author.id).anyTrue
          # Embeds
          initialEmbed = Discord::Embed.new(
            title: "Hi!, this is the gayboard setup!",
            description: "Could you reply with the amount of `🏳️‍🌈` a message needs to get on the board?\n(Numbers only)",
            colour: 0xffff00,
          )
          BOT.create_message(payload.channel_id, "", initialEmbed)
          tooLate = Discord::Embed.new(
            title: "Sorry, you took too long to reply!",
            description: "Please start over by typing `#{PREFIX[0]}gayboard`",
            colour: 0xffff00,
          )
          # Start await manager for author and for 30 seconds
          response = await_manager.await_user(payload.author.id, 30.seconds)
          case response
          when Discord::Message
            # Check if they provided a number
            isitaNum = response.content.to_i { 0 }
            if isitaNum > 0
              channelEmbed = Discord::Embed.new(
                title: "Great Job! Min reactions got set to #{response.content}!",
                description: "Now, about the channel, do you want me to create it?\n**(Reply with `Yes`)**\n\nOr would you like to do it yourself?\n**(Reply with anything but `Yes`)**\n\nThe channel name must start with `gayboard`. Ideally, users shouldn't be able to send messages in that channel.",
                colour: 0xffff00,
              )
              BOT.create_message(payload.channel_id, "", channelEmbed)
              # Start another await manager
              secondResponse = await_manager.await_user(payload.author.id, 30.seconds)
            else
              notaNum = Discord::Embed.new(
                title: "It seems that you didn't provide a positive number",
                description: "Please start over by typing `#{PREFIX[0]}gayboard`",
                colour: 0xffff00,
              )
              BOT.create_message(payload.channel_id, "", notaNum)
            end
            case secondResponse
            when Discord::Message
              # Connect to db
              DB.open "#{MYSQLCONN}guildinfo" do |db|
                db.exec "drop table if exists `#{guild_id}`"
                db.exec "create table `#{guild_id}` (min_react int)"
                db.exec "insert into `#{guild_id}` values (?)", isitaNum
              end
              # Acceptable responses
              responses = ["ye", "y", "yes"]
              # If their respond was one of the above
              if responses.any? { |k| k == secondResponse.content.downcase }
                begin
                  # Create channel and edit its perms
                  createdChan = BOT.create_guild_channel(guild_id.to_u64, "gayboard🌈", Discord::ChannelType::GuildText, nil, nil)
                  BOT.edit_channel_permissions(createdChan.id, guild_id, "role", Discord::Permissions::ReadMessages, Discord::Permissions::SendMessages)
                  chanCreated = Discord::Embed.new(
                    title: "Thank you for using Gayboard!",
                    description: "Everything should be working now!\nGo react to some messages!",
                    colour: 0xffff00,
                  )
                  BOT.create_message(payload.channel_id, "", chanCreated)
                rescue
                  notEnoughPerms = Discord::Embed.new(
                    title: "I can't create a channel!",
                    description: "I might be missing the `Manage Channels` and/or the `Manage Roles` perms!\nPlease start over by typing `#{PREFIX[0]}gayboard`",
                    colour: 0xffff00,
                  )
                  BOT.create_message(payload.channel_id, "", notEnoughPerms)
                end
              else
                chanNotCreated = Discord::Embed.new(
                  title: "Thank you for using Gayboard!",
                  description: "Everything should be working when you manually create the gayboard channel!",
                  colour: 0xffff00,
                )
                BOT.create_message(payload.channel_id, "", chanNotCreated)
              end
            when AwaitManager::Timeout
              BOT.create_message(payload.channel_id, "", tooLate)
            end
          when AwaitManager::Timeout
            BOT.create_message(payload.channel_id, "", tooLate)
          end
        rescue ex
          puts "[GAYBOARD ERROR] The following error occurred in #on_message_create"
          puts ex
          puts "[GAYBOARD ERROR END]"
        end
      end
    end
  end
end
