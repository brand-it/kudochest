# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RecipientNotSelfValidator do
  subject(:validate) { described_class.new.validate(tip) }

  let(:tip) { build(:tip, from_profile: from_profile, to_profile: to_profile) }
  let(:from_profile) { create(:profile) }
  let(:to_profile) { create(:profile) }

  it 'is valid when to_profile is not from_profile' do
    validate
    expect(tip.errors).to be_empty
  end

  context 'when to_profile is from_profile' do
    let(:to_profile) { from_profile }

    it 'is invalid' do
      validate
      expect(tip.errors[:base]).to eq(
        [I18n.t('activerecord.errors.models.tip.attributes.base.cannot_tip_self')]
      )
    end
  end
end
