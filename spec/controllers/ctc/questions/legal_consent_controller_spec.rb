require "rails_helper"

describe Ctc::Questions::LegalConsentController do
  let(:intake) { create :ctc_intake, :unconsented, visitor_id: "visitor-id" }

  before do
    allow(MixpanelService).to receive(:send_event)
    session[:intake_id] = intake.id
    allow(controller).to receive(:verify_recaptcha).and_return(true)
    allow(controller).to receive(:recaptcha_reply).and_return({ 'score' => "0.9" })
  end

  describe "#edit" do
    it "renders edit template and initializes form" do
      get :edit, params: {}
      expect(response).to render_template :edit
      expect(assigns(:form)).to be_an_instance_of Ctc::LegalConsentForm
      expect(assigns(:form).intake).to be_an_instance_of Intake::CtcIntake
    end
  end

  describe "#update" do
    context "with valid params" do
      let(:params) do
        {
          ctc_legal_consent_form: {
            primary_first_name: "Marty",
            primary_middle_initial: "J",
            primary_last_name: "Mango",
            primary_birth_date_year: "1963",
            primary_birth_date_month: "9",
            primary_birth_date_day: "10",
            primary_ssn: "111-22-8888",
            primary_ssn_confirmation: "111-22-8888",
            primary_active_armed_forces: "no",
            phone_number: "831-234-5678",
            primary_tin_type: "ssn",
          }
        }
      end

      it "updates client with intake personal info" do
        post :update, params: params

        client = Client.last
        expect(client.intake.primary_first_name).to eq "Marty"
        recaptcha_score = client.recaptcha_scores.last
        expect(recaptcha_score.score).to eq 0.9
        expect(recaptcha_score.action).to eq 'legal_consent'
      end

      it "sends a Mixpanel event" do
        post :update, params: params
        expect(MixpanelService).to have_received(:send_event).with hash_including(
          distinct_id: "visitor-id",
          event_name: "ctc_provided_personal_info"
        )
      end

      it "sets the consented to service properties as well" do
        post :update, params: params
        expect(intake.reload.primary_consented_to_service_at).not_to be_nil
        expect(intake.primary_consented_to_service).to eq "yes"
        expect(intake.primary_consented_to_service_ip).not_to be_nil
      end
    end
  end
end
