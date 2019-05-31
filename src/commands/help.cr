module Gayboard
  module Help
    BOT.on_message_create do |payload|
      next if payload.author.bot
      # If starts with prefix
      if PREFIX.any? { |p| payload.content.starts_with?("#{p}help") }
        # Stop if its dm
        next unless guild_id = CACHE.resolve_channel(payload.channel_id).guild_id
        begin
          embed = Discord::Embed.new(
            title: "Here's all my commands!",
            colour: 0xff0000,
            fields: [
              Discord::EmbedField.new(name: "#{PREFIX[0]}info", value: "**Some info about me!**"),
              Discord::EmbedField.new(name: "#{PREFIX[0]}gayboard", value: "**Used for setting up gayboard!**"),
              Discord::EmbedField.new(name: "#{PREFIX[0]}min <number>", value: "**Change min reactions!**"),
              Discord::EmbedField.new(name: "#{PREFIX[0]}stats [userID/mention]", value: "**Stats for guild or user if provided!**"),
              Discord::EmbedField.new(name: "#{PREFIX[0]}message <messageID>", value: "**Shows mentioned message!**"),
            ]
          )
          BOT.create_message(payload.channel_id, "", embed)
        rescue ex
          puts "[GAYBOARD ERROR] The following error occurred in #on_message_create"
          puts ex
          puts "[GAYBOARD ERROR END]"
        end
      end
    end
  end
end
