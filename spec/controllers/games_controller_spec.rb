require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:another_user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }
  let(:right_letter) { game_w_questions.current_game_question.correct_answer_key }


  context 'Anonymous' do
    it 'can not #show' do
      get :show, params: { id: game_w_questions.id }
      expect(response.status).not_to eq(200) # статус не 200 ОК
      expect(response).to redirect_to(new_user_session_path) # devise должен отправить на логин
      expect(flash[:alert]).to be # во flash будет ошибка
    end

    it 'can not #create' do
      generate_questions(15)
      post :create
      game = assigns(:game)
      forbidden_action_for_anonymous(game)
    end

    it 'can not #answer' do
      put :answer, params: { id: game_w_questions.id, letter: right_letter }
      game = assigns(:game)
      forbidden_action_for_anonymous(game)
    end

    it 'can not #take_money' do
      game_w_questions.update_attribute(:current_level, 2)
      put :take_money, params: { id: game_w_questions.id }
      game = assigns(:game)
      forbidden_action_for_anonymous(game)
    end

    it 'can not #help' do
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      expect(game_w_questions.audience_help_used).to be(false)
      put :help, params: { id: game_w_questions.id, help_type: :audience_help }
      game = assigns(:game)
      forbidden_action_for_anonymous(game)
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
      put :answer, params: { id: game_w_questions.id, letter: right_letter }
      game = assigns(:game)

      expect(game.finished?).to be(false)
      expect(game.current_level).to be > 0
      expect(response).to redirect_to(game_path(game))
      expect(flash.empty?).to be(true) # удачный ответ не заполняет flash
    end

    it 'answers wrong' do
      wrong_letter = right_letter == 'a' ? 'b' : 'a'
      put :answer, params: { id: game_w_questions.id, letter: wrong_letter }
      game = assigns(:game)

      expect(game.finished?).to be(true)
      expect(response).to redirect_to(user_path(user))
      expect(flash[:alert]).to be
    end

    # тест на отработку "помощи зала"
    it 'uses audience help' do
      # сперва проверяем что в подсказках текущего вопроса пусто
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      expect(game_w_questions.audience_help_used).to be(false)

      put :help, params: { id: game_w_questions.id, help_type: :audience_help }
      game = assigns(:game)

      # проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be(false)
      expect(game.audience_help_used).to be(true)
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game))
    end

    it 'uses fifty_fifty help' do
      expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
      expect(game_w_questions.audience_help_used).to be(false)

      put :help, params: { id: game_w_questions.id, help_type: :fifty_fifty }
      game = assigns(:game)
      expect(game.finished?).to be(false)
      expect(game.fifty_fifty_used ).to be(true)
      expect(game.current_game_question.help_hash[:fifty_fifty]).to be_an(Array)
      expect(game.current_game_question.help_hash[:fifty_fifty].count).to eq(2)
      expect(game.current_game_question.help_hash[:fifty_fifty]).to include(right_letter)
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

    it 'get help once' do
      %i[fifty_fifty audience_help friend_call].each_with_index do |help_type, i|
        put :help, params: { id: game_w_questions.id, help_type: help_type }
        expect(flash[:info]).to match(I18n.t('controllers.games.help_used'))
        expect(flash[:alert]).to be_nil if i.zero?
        expect(response).to redirect_to(game_path(game_w_questions))

        put :help, params: { id: game_w_questions.id, help_type: help_type }
        expect(flash[:info]).to match(I18n.t('controllers.games.help_used'))
        expect(flash[:alert]).to match(I18n.t('controllers.games.help_not_used'))
        expect(response).to redirect_to(game_path(game_w_questions))
      end
    end
  end

  def forbidden_action_for_anonymous(game)
    expect(game).to be_nil
    expect(response).to redirect_to(new_user_session_path)
    expect(flash[:alert]).to be
  end
end
