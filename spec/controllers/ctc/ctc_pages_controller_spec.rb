require "rails_helper"

describe Ctc::CtcPagesController do
  describe "#home" do
    context "with the ?ctc_beta=1 query parameter" do
      it "sets the ctc_intake_ok cookie and redirects to intake" do
        get :home, params: {ctc_beta: "1"}

        expect(cookies[:ctc_intake_ok]).to eq('yes')
        expect(response).to redirect_to Ctc::Questions::OverviewController.to_path_helper
      end

      context "when DISABLE_CTC_BETA_PARAM is set" do
        around do |example|
          ENV['DISABLE_CTC_BETA_PARAM'] = '1'
          example.run
          ENV.delete('DISABLE_CTC_BETA_PARAM')
        end

        it "renders the home page without any cookies or redirects" do
          get :home
          expect(cookies[:ctc_intake_ok]).to be_nil
          expect(response).to be_ok
        end
      end
    end

    context "without the ?ctc_beta=1 query parameter" do
      it "renders the homepage" do
        get :home
        expect(response).to be_ok
      end
    end

    context "CDSS landing page content" do
      [
        %w( cactc /en/help ),
        %w( fed   /en/help ),
      ].each do |source, location|
        describe "When client visits from source param #{source}" do
          it "redirects to #{location}" do
            session[:source] = source
            get :home
            expect(subject).to redirect_to(location)
          end
        end
      end
    end
  end

  describe "#help" do
    it "renders the home template with the needs_help_banner instance variable set to true" do
      get :help
      expect(session[:source]).to eq "help"
      expect(subject).to render_template(:home)
      expect(assigns(:needs_help_banner)).to eq true
    end
  end

  describe "#california_benefits" do
    context "source is present" do
      let(:params) { { source: 'claim' } }

      it "saves the source in the session" do
        get :california_benefits, params: params

        expect(session[:source]).to eq "claim"
      end
    end
  end

  describe "#navigators" do
    render_views

    it "renders the content" do
      get :navigators

      expect(response.body).to include "Need help claiming your tax benefits?"
    end
  end
end
