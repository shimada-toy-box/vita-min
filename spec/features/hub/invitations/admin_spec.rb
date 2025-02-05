require "rails_helper"

RSpec.feature "Inviting admin users" do
  context "As an admin user" do
    let(:user) { create :admin_user }
    before do
      login_as user
    end

    scenario "Inviting, re-sending invites, and accepting invites" do
      visit hub_tools_path
      click_on "Invitations"

      # Invitations page
      expect(page).to have_selector "h1", text: "Invitations"
      select "Admin", from: "What type of user do you want to invite?"
      click_on "Continue"

      # new invitation page
      expect(page).to have_text "Send a new invitation"
      fill_in "What is their name?", with: "Aileen Artichoke"
      fill_in "What is their email?", with: "aileen@artichoke.org"
      click_on "Send invitation email"

      # back on the invitations page
      within(".flash--notice") do
        expect(page).to have_text "We sent an email invitation to aileen@artichoke.org"
      end
      within(".invitations") do
        expect(page).to have_text "Aileen Artichoke"
        expect(page).to have_text "aileen@artichoke.org"
        expect(page).to have_text "Admin"
      end
      invited_user = User.where(invited_by: user).last
      expect(invited_user).to be_present

      # resend invitation
      within("#invitation-#{invited_user.id}") do
        click_on "Resend invitation"
      end
      within(".flash--notice") do
        expect(page).to have_text "Invitation re-sent to aileen@artichoke.org"
      end
      invited_user = User.where(invited_by: user).last
      expect(invited_user.invitation_sent_at).to be_within(2.seconds).of(Time.now)

      logout

      # New invitation recipient signing up!
      mail = ActionMailer::Base.deliveries.last
      html_body = mail.body.parts[1].decoded
      accept_invite_url = Nokogiri::HTML.parse(html_body).at_css("a")["href"]
      expect(mail.subject).to eq "You've been invited to GetYourRefund"
      expect(accept_invite_url).to be_present
      expect(mail.body.encoded).to have_text "Hello,"
      expect(mail.body.encoded).to have_text "#{user.name} (#{user.email}) has invited #{invited_user.name} to create an account on GetYourRefund"
      expect(mail.body.encoded).to have_text "If you don't want to accept the invitation, please ignore this email."

      # Sign up page
      visit accept_invite_url
      expect(page).to have_text "Thank you for signing up to help!"
      expect(page).to have_text "aileen@artichoke.org"
      expect(find_field("What is your name?").value).to eq "Aileen Artichoke"
      fill_in "Please choose a strong password", with: "c0v3rt-c4ul1fl0wer"
      fill_in "Enter your new password again", with: "c0v3rt-c4ul1fl0wer"
      click_on "Get started"

      expect(page).to have_text "You're all set and ready to go! You've joined an amazing team!"
      expect(page).to have_text "Aileen Artichoke"
      expect(page).to have_text "Admin"
    end

    it "shows errors if the required data was not provided" do
      visit hub_tools_path
      click_on "Invitations"

      # Invitations page
      expect(page).to have_selector "h1", text: "Invitations"
      select "Admin", from: "What type of user do you want to invite?"
      click_on "Continue"

      # new invitation page
      expect(page).to have_text "Send a new invitation"
      click_on "Send invitation email"

      expect(page).to have_text(I18n.t('errors.messages.blank'))
      expect(page).to have_select('Which role?', selected: 'AdminRole', disabled: true)
    end
  end
end
