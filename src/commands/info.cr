module Gayboard
  module Info
    BOT.on_message_create do |payload|
      next if payload.author.bot
      # If starts with prefix
      if PREFIX.any? { |p| payload.content.starts_with?("#{p}info") }
        # Stop if its dm
        next unless guild_id = CACHE.resolve_channel(payload.channel_id).guild_id
        begin
          time = Time.now - UPTIMER
          embed = Discord::Embed.new(
            title: "Here's some info about me!",
            colour: 0xff0000,
            description: "[HOW TO USE]\n1. Set up gayboard `#{PREFIX[0]}gayboard`\n2. React to some messages with :gay_pride_flag:",
            fields: [
              Discord::EmbedField.new(name: "Prefix", value: "#{PREFIX.join(", ")}", inline: true),
              Discord::EmbedField.new(name: "Uptime", value: "#{time.hours} Hours, #{time.minutes} Minutes, #{time.seconds} Seconds", inline: true),
              Discord::EmbedField.new(name: "Lib", value: "Crystal, [discordcr](https://github.com/meew0/discordcr)", inline: true),
              Discord::EmbedField.new(name: "Creator", value: "『Geop』#4066 `216156825978929152`", inline: true),
              Discord::EmbedField.new(name: "Credits", value: "https://github.com/GeopJr/Gayboard#credits", inline: true),
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
