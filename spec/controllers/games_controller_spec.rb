require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для игрового контроллера
# Самые важные здесь тесты:
#   1. на авторизацию (чтобы к чужим юзерам не утекли не их данные)
#   2. на четкое выполнение самых важных сценариев (требований) приложения
#   3. на передачу граничных/неправильных данных в попытке сломать контроллер
#
RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:another_user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  context 'Anonymous' do
    it 'can not #show' do
      get :show, params: { id: game_w_questions.id }

      expect(response.status).not_to eq(200) # статус не 200 ОК
      expect(response).to redirect_to(new_user_session_path) # devise должен отправить на логин
      expect(flash[:alert]).to be # во flash должен быть прописана ошибка
    end
  end

  context 'Usual user' do
    before(:each) { sign_in user } # логиним юзера user с помощью спец. Devise метода sign_in

    it 'creates game' do
      generate_questions(15)
      post :create
      game = assigns(:game) # вытаскиваем из контроллера поле @game

      expect(game.finished?).to be(false)
      expect(game.user).to eq(user)
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to be
    end

    it '#show own game' do
      get :show, params: { id: game_w_questions.id }
      game = assigns(:game) # вытаскиваем из контроллера поле @game
      expect(game.finished?).to be(false)
      expect(game.user).to eq(user)

      expect(response.status).to eq(200) # должен быть ответ HTTP 200
      expect(response).to render_template('show') # и отрендерить шаблон show
    end

    it 'can`t #show another user game' do
      sign_in another_user
      get :show, params: { id: game_w_questions.id }
      expect(response.status).to eq(302)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be
    end
    # юзер отвечает на игру корректно - игра продолжается
    it 'answers correct' do
      letter = game_w_questions.current_game_question.correct_answer_key
      put :answer, params: { id: game_w_questions.id, letter: letter }
      game = assigns(:game)

      expect(game.finished?).to be(false)
      expect(game.current_level).to be > 0
      expect(response).to redirect_to(game_path(game))
      expect(flash.empty?).to be(true) # удачный ответ не заполняет flash
    end

    # тест на отработку "помощи зала"
    it 'uses audience help' do
      # сперва проверяем что в подсказках текущего вопроса пусто
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      expect(game_w_questions.audience_help_used).to be(false)

      # фигачим запрос в контроллен с нужным типом
      put :help, params: { id: game_w_questions.id, help_type: :audience_help }
      game = assigns(:game)

      # проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be_falsey
      expect(game.audience_help_used).to be(true)
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game))
    end

    it 'takes money' do
      # вручную поднимем уровень до выигрыша 200
      game_w_questions.update_attribute(:current_level, 2)

      put :take_money, params: { id: game_w_questions.id }
      game = assigns(:game)
      expect(game.finished?).to be(true)
      expect(game.prize).to eq(200)

      user.reload
      expect(user.balance).to eq(200)

      expect(response).to redirect_to(user_path(user))
      expect(flash[:warning]).to be
    end

    it 'not create new game if previouse not finished' do
      expect(game_w_questions.finished?).to be(false) # previouse game exists
      expect { post :create }.to change(Game, :count).by(0) # try to create new game

      game = assigns(:game)
      expect(game).to be_nil
      expect(flash[:alert]).to be
      expect(response.status).to eq(302)
      expect(response).to redirect_to(game_path(game_w_questions))
    end
  end
end
