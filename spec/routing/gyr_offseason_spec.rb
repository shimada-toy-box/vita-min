require "rails_helper"

RSpec.describe "GYR offseason redirects", type: :request do
  describe "questions pages when not logged-in" do
    it_behaves_like :a_normal_page_when_intake_is_open, GyrQuestionNavigation.first
    it_behaves_like :a_redirect_home_when_intake_is_closed, GyrQuestionNavigation.first
    it_behaves_like :a_redirect_home_when_login_is_closed, GyrQuestionNavigation.first
  end

  describe "questions pages when logged-in" do
    before { login_as(create(:intake).client, scope: :client) }
    it_behaves_like :a_normal_page_when_intake_is_open, GyrQuestionNavigation.first
    it_behaves_like :a_normal_page_when_intake_is_closed, GyrQuestionNavigation.first
    it_behaves_like :a_redirect_home_when_login_is_closed, GyrQuestionNavigation.first
  end

  describe "login pages" do
    it_behaves_like :a_normal_page_when_intake_is_open, Portal::ClientLoginsController, action: :new
    it_behaves_like :a_normal_page_when_intake_is_closed, Portal::ClientLoginsController, action: :new
    it_behaves_like :a_redirect_home_when_login_is_closed, Portal::ClientLoginsController, action: :new
  end

  describe "portal pages when logged-in" do
    before { login_as(create(:intake).client, scope: :client) }
    it_behaves_like :a_normal_page_when_intake_is_open, Portal::PortalController, action: :home
    it_behaves_like :a_normal_page_when_intake_is_closed, Portal::PortalController, action: :home
    it_behaves_like :a_redirect_home_when_login_is_closed, Portal::PortalController, action: :home
  end

  describe "diy pages" do
    it_behaves_like :a_normal_page_when_intake_is_open, Diy::FileYourselfController
    it_behaves_like :a_normal_page_when_intake_is_closed, Diy::FileYourselfController
    it_behaves_like :a_normal_page_when_intake_is_closed, PublicPagesController, action: :diy
    it_behaves_like :a_redirect_home_when_login_is_closed, Diy::FileYourselfController
  end
end
