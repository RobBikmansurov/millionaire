FactoryBot.define do
  factory :game do
    association :user

    current_level { 0 }
    is_failed { false }
    prize { 0 }

    factory :game_with_questions do
      after(:build) do |game|
        15.times do |i|
          q = create(:question, level: i)
          create(:game_question, game: game, question: q)
        end
      end
    end

    trait :prized do
      prize { 8000 }
      current_level { 8 }
      created_at { 59.minutes.ago}
      finished_at { 40.minutes.ago }
    end
    trait :expired do
      prize { 0 }
      current_level { 2 }
      created_at { 2.hours.ago}
      finished_at { 5.minutes.ago }
      is_failed { true }
    end
  end
end
