require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

RSpec.describe Game, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # генерим 60 вопросов с 4х запасом по полю level,
      # чтобы проверить работу RANDOM при создании игры
      generate_questions(60)

      game = nil
      # создaли игру, обернули в блок, на который накладываем проверки
      expect do
        game = Game.create_game_for_user!(user)
      end.to change(Game, :count).by(1).and( # проверка: Game.count изменился на 1 (создали в базе 1 игру)
        change(GameQuestion, :count).by(15).and( # GameQuestion.count +15
          change(Question, :count).by(0) # Game.count не должен измениться
        )
      )
      # проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      # проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # тесты на основную игровую логику
  context 'game mechanics' do
    # правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)
      # ранее текущий вопрос стал предыдущим
      expect(game_w_questions.previous_game_question).to eq(q)
      expect(game_w_questions.current_game_question).not_to eq(q)
      # игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end
  end

  it 'take_money! finishes the game' do
    # берем игру и отвечаем на текущий вопрос
    q = game_w_questions.current_game_question
    game_w_questions.answer_current_question!(q.correct_answer_key)

    # взяли деньги
    game_w_questions.take_money!

    prize = game_w_questions.prize
    expect(prize).to be > 0

    # проверяем что закончилась игра и пришли деньги игроку
    expect(game_w_questions.status).to eq :money
    expect(game_w_questions.finished?).to be_truthy
    expect(user.balance).to eq prize
  end

  # группа тестов на проверку статуса игры
  context '.status' do
    # перед каждым тестом "завершаем игру"
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it ':won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it ':fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it ':timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it ':money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end

  context 'game logic' do
    it '.previous_level = -1 for new game' do
      expect(game_w_questions.previous_level).to eq(-1)
    end

    it '.current_game_question returns first game_question' do
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions.first)
    end
  end

  context '.answer_current_question!' do
    let(:question) { game_w_questions.current_game_question }
    it 'correct answer - returns true' do
      expect(game_w_questions.answer_current_question!(question.correct_answer_key)).to be(true)
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be(false)
    end
    it 'wrong answer - returns false' do
      expect(game_w_questions.answer_current_question!('a')).to eq(false)
      expect(game_w_questions.status).to eq(:fail)
      expect(game_w_questions.finished?).to be(true)
    end
    it 'expired game - returns false' do
      game_w_questions.created_at = Game::TIME_LIMIT.ago
      expect(game_w_questions.answer_current_question!(question.correct_answer_key)).to be(false)
      expect(game_w_questions.status).to eq(:timeout)
      expect(game_w_questions.finished?).to be(true)
    end
    it 'finished game - returns false' do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.answer_current_question!(question.correct_answer_key)).to be(false)
      expect(game_w_questions.finished?).to be(true)
    end
    it 'on last correct question - returns true' do
      game_w_questions.current_level = 14
      expect(game_w_questions.answer_current_question!(question.correct_answer_key)).to be(true)
      expect(game_w_questions.finished?).to be(true)
      expect(user.balance).to eq game_w_questions.prize
      expect(game_w_questions.status).to eq(:won)
      expect(game_w_questions.finished?).to be(true)
    end
  end
end
