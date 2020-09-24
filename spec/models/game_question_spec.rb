require 'rails_helper'

RSpec.describe GameQuestion, type: :model do
  let(:game_question) { FactoryBot.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  context 'game status' do
    # тест на правильную генерацию хэша с вариантами
    it 'correct .variants' do
      expect(game_question.variants).to eq(
        'a' => game_question.question.answer2,
        'b' => game_question.question.answer1,
        'c' => game_question.question.answer4,
        'd' => game_question.question.answer3
      )
    end

    it 'correct .answer_correct?' do
      # именно под буквой b в тесте мы спрятали указатель на верный ответ
      expect(game_question.answer_correct?('b')).to be_truthy
    end
  end

  # help_hash у нас имеет такой формат:
  # {
  #   fifty_fifty: ['a', 'b'], # При использовании подсказки остались варианты a и b
  #   audience_help: {'a' => 42, 'c' => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #   friend_call: 'Василий Петрович считает, что правильный ответ A'
  # }
  #

  context 'user helpers' do
    it { expect(game_question.help_hash).to be_empty }
    it '.fifty_fifty' do
      game_question.add_fifty_fifty
      expect(game_question.help_hash).to have_key(:fifty_fifty)
      fifty_fifty = game_question.help_hash[:fifty_fifty]
      expect(fifty_fifty.count).to eq(2)
      expect(fifty_fifty).to be_an(Array)
    end
    it '.audience_help' do
      game_question.add_audience_help
      expect(game_question.help_hash).to have_key(:audience_help)
      audience_help = game_question.help_hash[:audience_help]
      expect(audience_help.keys).to contain_exactly('a', 'b', 'c', 'd')
    end
    it '.add_friend_call' do
      game_question.add_friend_call
      expect(game_question.help_hash).to have_key(:friend_call)
      friend_call = game_question.help_hash[:friend_call]
      expect(friend_call).to match(/считает, что это вариант/)
    end
  end

  it 'correct .level & .text delegates' do
    expect(game_question.text).to eq(game_question.question.text)
    expect(game_question.level).to eq(game_question.question.level)
  end

  context 'game logic' do
    it '.correct_answer_key returns b' do
      expect(game_question.correct_answer_key).to eq('b')
    end
  end
end
