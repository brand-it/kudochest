# frozen_string_literal: true
namespace :seeds do
  desc 'Generate seeds for testing'
  task all: :environment do
    Rake::Task['seeds:tips'].execute
    Rake::Task['seeds:loot'].execute
  end

  desc 'Generate Tips and related data for testing'
  task tips: :environment do
    include FactoryBot::Syntax::Methods

    team = Team.first

    print 'Generating topics'
    rand(5..30).times do
      create(:topic, team: team)
    end

    print 'Generating tips'
    profiles = team.profiles.active
    profiles.each do |profile|
      num = rand(20..50)
      profile.increment!(:tokens_accrued, num) # rubocop:disable Rails/SkipsModelValidations
      num.times do
        channel = team.channels.sample
        topic_id = rand(3).zero? ? nil : team.topics.sample.id
        TipFactory.call(
          topic_id: topic_id,
          from_profile: profile,
          to_entity: 'Profile',
          to_profiles: [(profiles - [profile]).sample],
          from_channel_rid: channel.rid,
          from_channel_name: channel.name,
          quantity: rand(1..3),
          note: Faker::Lorem.sentence(word_count: 4),
          event_ts: Time.current.to_f.to_s,
          channel_rid: channel.rid,
          source: 'auto',
          timestamp: Time.current
        )
      end
    end
    puts 'done'

    print 'Randomizing temporal distribution of tips'
    Tip.find_each do |tip|
      tip.update(created_at: Time.current - rand(1..20).days)
      print '.'
    end
    puts 'done'
  end

  desc 'Generate Loot for testing'
  task loot: :environment do
    prices = [50, 100, 200, 250, 500, 1_000, 1_200]
    team = Team.first
    profile1 = team.profiles.active.first
    profile2 = team.profiles.active.second
    print 'Generating rewards'
    40.times do |n|
      auto_fulfill = rand(3).to_i == 1
      fulfillment_keys = Array.new(5) { Faker::Crypto.md5 }
      quantity = n.even? ? 0 : rand(100).to_i
      reward = Reward.create(
        team: team,
        name: "Reward #{Faker::Crypto.md5.first(5)}",
        price: prices.sample,
        description: Faker::Lorem.paragraph,
        auto_fulfill: auto_fulfill,
        quantity: quantity,
        fulfillment_keys: auto_fulfill ? fulfillment_keys.join("\n") : nil,
        active: rand(3).to_i != 1
      )
      next if rand(3).to_i.positive? || ENV['SKIP_CLAIMS'].present?
      fulfilled = auto_fulfill ? true : rand(2).to_i.even?
      max_claims = auto_fulfill ? fulfillment_keys.size : quantity
      num_claims = rand(2).to_i.even? ? max_claims : rand(max_claims).to_i
      num_claims.times do |c|
        reward.claims.create(
          profile: rand(2).to_i.even? ? profile1 : profile2,
          fulfilled_at: fulfilled ? Time.current : nil,
          fulfillment_key: fulfilled ? fulfillment_keys[c] : nil,
          price: reward.price
        )
      end
    end

    puts 'done'
  end
end
