# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BonusCalculatorService, :freeze_time do
  subject(:service) { described_class.call(args) }

  let(:team) { create(:team) }
  let(:profile1) { create(:profile, team: team) }
  let(:profile2) { create(:profile, team: team) }
  let(:args) do
    {
      team: team,
      start_date: (Time.current - 2.days).strftime('%Y-%m-%d'),
      end_date: (Time.current + 2.days).strftime('%Y-%m-%d'),
      include_streak_points: include_streak_points,
      include_imported_points: include_imported_points,
      style: style,
      pot_size: pot_size,
      dollar_per_point: dollar_per_point
    }
  end

  let(:include_streak_points) { true }
  let(:include_imported_points) { true }
  let(:pot_size) { 0 }
  let(:dollar_per_point) { 0 }

  shared_examples 'success' do
    before do
      create(:tip, from_profile: profile1, to_profile: profile2, quantity: 5)
      create(:tip, from_profile: profile2, to_profile: profile1, quantity: 2)
      allow(TeamOwnerMailer).to receive(:bonus_calculator).and_call_original
      service
    end

    it 'calls TeamOwnerMailer with expected args' do
      expect(TeamOwnerMailer).to have_received(:bonus_calculator).with(team, csv_str)
    end
  end

  xcontext 'when style is `split_pot`' do
    let(:style) { 'split_pot' }
    let(:pot_size) { 2_000 }
    let(:csv_str) do
      <<~TEXT
        TODO
      TEXT
    end

    include_examples 'success'
  end

  xcontext 'when style is `points_value`' do
    let(:style) { 'points_value' }
    let(:points_value) { 0.50 }
    let(:csv_str) do
      <<~TEXT
        TODO
      TEXT
    end

    include_examples 'success'
  end

  xcontext 'when style is `salary_percent`' do
    let(:style) { 'salary_percent' }
    let(:csv_str) do
      <<~TEXT
        TODO
      TEXT
    end

    include_examples 'success'
  end
end
