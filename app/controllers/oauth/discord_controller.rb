# frozen_string_literal: true
class Oauth::DiscordController < ApplicationController
  before_action :verify_state_param

  def integration
    if params[:permissions] != App.discord_permission
      return redirect_to dashboard_path, alert: t('oauth.permissions_required')
    end

    TeamRegistrar.call(team_data)
    redirect_to dashboard_path, notice: t('oauth.code_grant_success_html')
  end

  private

  def verify_state_param
    return if params[:state] == current_user.reg_token
    redirect_to dashboard_path, notice: t('oauth.generic_error')
  end

  def team_data
    {
      api_key: oauth_data[:access_token], # We don't actually use this
      platform: :discord,
      rid: params[:guild_id],
      name: oauth_data[:guild][:name],
      avatar_url: avatar_url,
      owner_user_id: current_user.id
    }
  end

  def oauth_data
    @oauth_data ||= JSON[HTTP.post(oauth_url, form: oauth_params)].deep_symbolize_keys
  end

  def oauth_url
    'https://discordapp.com/api/v6/oauth2/token'
  end

  def oauth_params
    {
      client_id: ENV['DISCORD_CLIENT_ID'],
      client_secret: ENV['DISCORD_CLIENT_SECRET'],
      code: params[:code],
      grant_type: 'authorization_code',
      redirect_uri: oauth_discord_integration_url,
      scope: 'bot'
    }
  end

  def default_avatar_url
    "https://#{ENV['WEB_DOMAIN']}/static/avatars/team-default-256.webp"
  end

  def avatar_url
    return default_avatar_url if oauth_data[:guild][:icon].blank?
    "#{App.discord_cdn_base}/icons/#{params[:guild_id]}/#{oauth_data[:guild][:icon]}.png?size=256"
  end
end
