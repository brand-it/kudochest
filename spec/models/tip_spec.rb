# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Tip do
  subject(:tip) { build(:tip) }

  it { is_expected.to be_a(ApplicationRecord) }

  it { is_expected.to belong_to(:from_profile).class_name('Profile').inverse_of(:tips_sent) }
  it { is_expected.to belong_to(:to_profile).class_name('Profile').inverse_of(:tips_received) }
  it { is_expected.to belong_to(:topic).optional(true) }

  it { is_expected.to validate_presence_of(:from_profile_id) }
  it { is_expected.to validate_presence_of(:to_profile_id) }
  it { is_expected.to validate_length_of(:note).is_at_most(App.max_note_length) }

  describe 'Topic presence validation' do
    subject(:tip) { build(:tip, from_profile: profile, topic: nil) }

    let(:team) { create(:team) }
    let(:profile) { create(:profile, team: team) }

    context 'when team requires it' do
      before do
        team.update(require_topic: true)
        tip.validate
      end

      it 'is invalid without a topic' do
        expect(tip.errors[:topic_id]).to eq(
          ["must be specified - use the \"topics\" command or visit #{App.base_url}/topic-list"]
        )
      end
    end

    context 'when team does not require it' do
      before do
        team.update(require_topic: false)
        tip.validate
      end

      it 'is valid without a topic' do
        expect(tip.errors[:topic_id]).to be_empty
      end
    end
  end

  describe 'scope #undoable', :freeze_time do
    let!(:tip1) { create(:tip, source: 'modal', from_profile: profile) }
    let!(:tip2) { create(:tip, source: 'plusplus', from_profile: profile) }
    let!(:tip3) { create(:tip, source: 'reply', from_profile: profile) }
    let!(:tip4) { create(:tip, source: 'streak', from_profile: profile) }
    let(:profile) { create(:profile) }

    before do
      create(:tip, source: 'auto', from_profile: profile) # wrong source
      create(:tip, source: 'modal', from_profile: profile, created_at: Time.current - 1.year) # old
    end

    it 'returns expected records' do
      expect(described_class.undoable).to match_array([tip1, tip2, tip3, tip4])
    end
  end

  describe 'scope #search_notes', :freeze_time do
    let!(:tip1) { create(:tip, note: 'Vishnu blah blah') }
    let!(:tip2) { create(:tip, note: 'something something vishnu') }

    before { create(:tip, note: 'Nothing to see here') }

    it 'returns expected records' do
      expect(described_class.search_notes('vish')).to match_array([tip1, tip2])
    end
  end

  describe 'custom validators' do
    let(:validators) { described_class.validators.map(&:class) }
    let(:expected_validators) do
      [
        QuantityValidator,
        RecipientNotABotValidator,
        RecipientNotDeletedValidator,
        RecipientNotSelfValidator
      ]
    end

    it 'validates with expected validators' do
      expect(validators).to include(*expected_validators)
    end
  end

  describe 'delete_slack_response after destroy' do
    subject(:tip) { create(:tip, response_channel_rid: channel.rid, response_ts: ts) }

    let(:ts) { Time.current.to_f.to_s }
    let(:channel) { build(:channel) }
    let(:expected_args) { { channel: channel.rid, ts: ts } }
    let(:slack_client) { instance_spy(Slack::Web::Client) }

    before do
      allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
      allow(slack_client).to receive(:chat_delete)
      tip.destroy
    end

    it 'calls Slack::SlackApi.chat_delete' do
      expect(slack_client).to have_received(:chat_delete).with(expected_args)
    end
  end

  describe 'delete_discord_response after destroy' do
    subject(:tip) do
      create(
        :tip,
        from_profile: profile,
        response_channel_rid:
        channel.rid,
        response_ts: ts
      )
    end

    let(:team) { create(:team, platform: :discord) }
    let(:profile) { create(:profile, team: team) }
    let(:ts) { Time.current.to_f.to_s }
    let(:channel) { build(:channel) }
    let(:expected_args) { { channel: channel.rid, ts: ts } }

    before do
      allow(Discordrb::API::Channel).to receive(:delete_message)
      tip.destroy
    end

    it 'calls Slack::SlackApi.chat_delete' do
      expect(Discordrb::API::Channel)
        .to have_received(:delete_message).with(App.discord_token, channel.rid, ts)
    end
  end

  describe 'callbacks' do
    let(:team) { create(:team) }
    let(:sender) { create(:profile, team: team) }
    let(:recipient) { create(:profile, team: team) }

    context 'when creating a tip' do
      before do
        create(:tip, from_profile: sender, to_profile: recipient, quantity: 2)
      end

      it 'increments sender points_sent' do
        expect(sender.reload.points_sent).to eq(2)
      end

      it 'increments recipient points_received' do
        expect(recipient.reload.points_received).to eq(2)
      end

      it 'increments the team points_sent' do
        expect(team.reload.points_sent).to eq(2)
      end
    end

    context 'when destroying a tip' do
      let!(:tip) { create(:tip, from_profile: sender, to_profile: recipient, quantity: 2) }

      describe '#delete_slack_response' do
        before do
          sender.update(points_sent: 5)
          recipient.update(points_received: 5)
          team.update(points_sent: 5)
          tip.destroy
        end

        it 'decrements sender points_sent' do
          expect(sender.reload.points_sent).to eq(3)
        end

        it 'decrements recipient points_received' do
          expect(recipient.reload.points_received).to eq(3)
        end

        it 'decrements the team points_sent' do
          expect(team.reload.points_sent).to eq(3)
        end
      end
    end
  end
end
