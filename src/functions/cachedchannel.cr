# This function checks if the channel is already in cache and if it's name starts with "gayboard"
# And returns it
class CachedChannel
  def initialize(@client : Discord::Client, channels : Hash(UInt64, Discord::Channel), @guild_id : UInt64 | Discord::Snowflake)
    @id = 0_u64
    # Iterate over all channels in cache and check if any of them starts with "gayboard"
    channels.each_value do |channel|
      if channel.guild_id == guild_id && channel.name.not_nil!.downcase.starts_with?("gayboard")
        @id = "#{channel.id}".to_u64 { 0_u64 }
      end
    end
  end

  # If nothing found, make a request and return its id
  def id
    if @id == 0_u64
      secondID = 0
      @client.get_guild_channels(@guild_id).each do |channels|
        next unless channels.name.not_nil!.downcase.starts_with?("gayboard")
        secondID = "#{channels.id}".to_u64 { 0_u64 }
      end
      secondID
    else
      @id
    end
  end
end
