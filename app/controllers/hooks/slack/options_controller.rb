# frozen_string_literal: true
class Hooks::Slack::OptionsController < Hooks::Slack::BaseController
  def receiver
    render json: { options: options }
  end

  private

  def options
    (
      everyone_option +
      profile_options +
      channel_options +
      subteam_options
    ).sort_by { |opt| opt[:text][:text] }
  end

  def everyone_option
    [generic_option("#{PROF_PREFIX}everyone", 'everyone')]
  end

  def profile_options
    Profile.joins(:team)
           .where('teams.rid' => team_rid)
           .where.not('profiles.rid' => profile_rid)
           .matching(user_input)
           .map do |profile|
      generic_option("#{PROF_PREFIX}#{profile.display_name} (#{profile.real_name})", profile.rid)
    end
  end

  def channel_options
    Channel.joins(:team)
           .where('teams.rid' => team_rid)
           .matching(user_input)
           .map do |channel|
      generic_option("#{CHAN_PREFIX} #{channel.name}", channel.rid)
    end
  end

  def subteam_options
    Subteam.joins(:team)
           .where('teams.rid' => team_rid)
           .matching(user_input)
           .map do |subteam|
      generic_option("#{PROF_PREFIX}#{subteam.handle} (#{subteam.name})", subteam.rid)
    end
  end

  def generic_option(text, value)
    {
      text: {
        type: :plain_text,
        text: text
      },
      value: value
    }
  end

  def user_input
    payload['value'].gsub(/[^0-9a-z\s]/i, '')
  end

  def profile_rid
    payload['user']['id']
  end

  def team_rid
    payload['team']['id']
  end

  def payload
    @payload ||= JSON[params[:payload]]
  end
end
