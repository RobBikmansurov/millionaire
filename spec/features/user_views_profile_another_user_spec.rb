require 'rails_helper'

RSpec.feature 'USER views profile another user', type: :feature do
  let(:user) { FactoryBot.create(:user) }
  let(:another_user) { FactoryBot.create(:user) }
  let(:game1) { FactoryBot.create(:game, :prized, user: another_user) }
  let(:game2) { FactoryBot.create(:game, :expired, user: another_user) }

  let!(:games) { [game1, game2] }

  scenario 'successfully' do
    visit '/'

    click_link another_user.name

    expect(page).to have_text(another_user.name)
    expect(page).not_to have_text('Сменить имя и пароль')

    expect(page).to have_text('деньги')
    expect(page).to have_text('8 000 ₽')
    expect(page).to have_text('время')
    expect(page).to have_text(I18n.l(game1.created_at, format: :short))
    expect(page).to have_text(I18n.l(game2.created_at, format: :short))

    # save_and_open_page
  end
end
