# frozen_string_literal: true
class Discord::ChannelService < Base::ChannelService
  def fetch_remote_channels
    JSON.parse(discord_channel_response, object_class: OpenStruct)
        .select { |d| d.type.zero? } # Text channels only
  end

  def base_attributes(channel)
    {
      team: team,
      rid: channel.id
    }
  end

  def syncable_attributes(channel)
    { name: channel.name }
  end

  def discord_channel_response
    Discordrb::API::Server.channels(App.discord_token, team.rid)
  end
end
