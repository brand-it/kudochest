# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LevelToKarmaService do
  subject(:call) { described_class.call(team: team, level: level) }

  let(:team) do
    create(
      :team,
      max_level: max_level,
      max_level_karma: max_level_karma,
      level_curve: curve
    )
  end
  let(:max_level) { 20 }
  let(:max_level_karma) { 500 }
  let(:level) { 13 }

  context 'with gentle curve' do
    let(:curve) { 'gentle' }

    it 'returns expected karma' do
      expect(call).to eq(251)
    end

    context 'when level is one' do
      let(:level) { 1 }

      it 'returns 0' do
        expect(call).to eq(0)
      end
    end
  end

  context 'with steep curve' do
    let(:curve) { 'steep' }

    it 'returns expected karma' do
      expect(call).to eq(191)
    end
  end

  context 'with linear curve' do
    let(:curve) { 'linear' }

    it 'returns expected karma' do
      expect(call).to eq(316)
    end
  end
end
