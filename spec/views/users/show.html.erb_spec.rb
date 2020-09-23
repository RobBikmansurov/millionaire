require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let(:logged_user) { FactoryBot.create(:user, name: 'Иван Иванов') }
  before(:each) do
    assign(:user, logged_user)
    assign(:games, [FactoryBot.build_stubbed(:game),
                    FactoryBot.build_stubbed(:game)] )

    render
  end

  it 'renders name' do
    expect(rendered).to match('Иван Ивано')
  end

  it 'render games' do
    expect(rendered).to have_content('в процессе')
  end

  context 'logged user' do
    it 'render change password if logged user' do
      sign_in logged_user
      @user = logged_user

      render
      expect(rendered).to match('пароль')
    end
  end
end
