require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  context 'unlogged user' do
    before(:each) do
      assign(:user, FactoryBot.build_stubbed(:user, name: 'Петр Петров'))
      assign(:games, FactoryBot.build_stubbed_list(:game, 2))

      render
    end
    it 'renders name' do
      expect(rendered).to match('Петр Петров')
    end
    it 'renders games' do
      expect(rendered).to have_content('в процессе')
    end
    it 'not renders change password link' do
      expect(rendered).not_to have_content('Сменить имя и пароль')
    end
  end

  context 'logged user' do
    let(:user) { FactoryBot.create(:user, name: 'Иван Иванов') }
    before(:each) do
      sign_in user
      assign(:user, user)
      assign(:games, FactoryBot.build_stubbed_list(:game, 2))

      render
    end
    it 'renders name' do
      expect(rendered).to match('Иван Иванов')
    end
    it 'renders games' do
      expect(rendered).to have_content('в процессе')
    end
    it 'render change password link' do
      expect(rendered).to match('Сменить имя и пароль')
    end
  end
end
