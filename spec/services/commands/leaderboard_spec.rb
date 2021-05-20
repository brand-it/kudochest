# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Commands::Leaderboard, :freeze_time do
  subject(:command) do
    described_class.call(team_rid: team.rid, profile_rid: profile.rid, text: text)
  end

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team: team) }
  let(:profile1) { create(:profile, team: team) }
  let(:profile2) { create(:profile, team: team) }
  let(:profile3) { create(:profile, team: team) }
  let(:profile4) { create(:profile, team: team) }
  let(:profiles) { [profile1, profile2, profile3, profile4] }
  let(:text) { '' }

  shared_examples 'expected response' do
    let(:response) { OpenStruct.new(mode: :public, text: text) }

    it 'returns leaderboard text' do
      expect(command).to eq(response)
    end
  end

  context 'when no karma has been given' do
    let(:text) do
      "No activity yet. The leaderboard updates every #{App.leaderboard_refresh_seconds} seconds."
    end

    include_examples 'expected response'
  end

  context 'when some karma has been given' do
    let(:text) do
      <<~TEXT.chomp
        *Top 4 Karma Earners*
        1. #{profile1.link} - 500 karma last earned less than a minute ago
        2. #{profile2.link} - 83 karma last earned about 1 hour ago
        2. #{profile3.link} - 83 karma last earned 7 days ago
        3. #{profile4.link} - 3 karma last earned 2 months ago
      TEXT
    end
    let(:mock_result) do
      OpenStruct.new(
        updated_at: Time.current,
        profiles: [
          profile_data(profile1, 1),
          profile_data(profile2, 2),
          profile_data(profile3, 2),
          profile_data(profile4, 3)
        ]
      )
    end

    before do
      profile1.update(karma: 500, last_tip_received_at: Time.current)
      profile2.update(karma: 83, last_tip_received_at: Time.current - 1.hour)
      profile3.update(karma: 83, last_tip_received_at: Time.current - 1.week)
      profile4.update(karma: 3, last_tip_received_at: Time.current - 2.months)
      team.update(karma_sent: profiles.sum(&:karma))
      allow(LeaderboardService).to receive(:call).with(
        team: team,
        givingboard: false
      ).and_return(mock_result)
    end

    include_examples 'expected response'
  end

  xcontext 'with integer and `me` given after keyword' do
  end

  xcontext 'with `givers` given after keyword' do
  end

  xcontext 'with topic keyword or emoji given after command keyword' do
  end

  def profile_data(prof, rank)
    OpenStruct.new(
      rank: rank,
      slug: prof.slug,
      link: prof.link,
      display_name: prof.display_name,
      real_name: prof.real_name,
      karma: prof.karma,
      percent_share: (prof.karma / team.karma_sent.to_f) * 100,
      last_timestamp: prof.last_tip_received_at.to_s
    )
  end
end
