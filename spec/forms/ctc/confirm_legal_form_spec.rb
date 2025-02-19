require 'rails_helper'

describe Ctc::ConfirmLegalForm do
  let(:client) { create :client, tax_returns: [(create :tax_return, filing_status: 'single')] }
  let!(:intake) { create :ctc_intake, client: client }
  let(:params) do
    {
      consented_to_legal: "yes",
      device_id: "7BA1E530D6503F380F1496A47BEB6F33E40403D1",
      user_agent: "GeckoFox",
      browser_language: "en-US",
      platform: "iPad",
      timezone_offset: "+240",
      client_system_time: "Mon Aug 02 2021 18:55:41 GMT-0400 (Eastern Daylight Time)",
      ip_address: "1.1.1.1",
      recaptcha_action: "confirm_legal",
      recaptcha_score: "0.9",
      timezone: "America/New_York"
    }
  end

  context "validations" do
    context "when consented to legal is selected" do
      it "is valid" do
        expect(
          described_class.new(intake, params)
        ).to be_valid
      end
    end

    context "when consented to legal is not selected" do
      before do
        params[:consented_to_legal] = "no"
      end

      it "is not valid" do
        form = described_class.new(intake, params)
        expect(form).not_to be_valid
        expect(form.errors.attribute_names).to include(:consented_to_legal)
      end
    end

    context "when efile security information fields are missing" do
      before do
        [:device_id, :user_agent, :browser_language, :platform, :timezone_offset, :client_system_time, :ip_address].each { |key| params.delete(key) }
      end

      it "is not valid" do
        form = described_class.new(intake, params)
        expect(form).not_to be_valid
        expect(form.errors.attribute_names).to match array_including(:device_id, :user_agent, :browser_language, :platform, :timezone_offset, :ip_address)
      end
    end
  end

  context "save" do
    it "persists the consented to legal to intake and create an efile submission and set status to preparing" do
      expect {
        described_class.new(intake, params).save
        intake.reload
      }
        .to change(intake, :consented_to_legal).from("unfilled").to("yes")
        .and change(intake, :completed_at).from(nil)
        .and change(intake.tax_returns.last.efile_submissions, :count).by(1)
    end

    context "when there was a positive eitc_amount at submission time" do
      let!(:intake) { create :ctc_intake, :claiming_eitc, client: client }
      let!(:w2) { create :w2, intake: intake }

      it "sets claimed_eitc to be true on the submission" do
        described_class.new(intake, params).save
        expect(EfileSubmission.last.claimed_eitc).to be_truthy
      end
    end

    it "persists efile_security_information as a record linked to the client" do
      expect {
        described_class.new(intake, params).save
      }.to change(EfileSecurityInformation, :count).by(1)
       .and change(intake.client.recaptcha_scores, :count).by 1
      efile_security_information = intake.client.reload.efile_security_informations.last
      expect(efile_security_information.ip_address).to eq "1.1.1.1"
      expect(efile_security_information.device_id).to eq "7BA1E530D6503F380F1496A47BEB6F33E40403D1"
      expect(efile_security_information.user_agent).to eq "GeckoFox"
      expect(efile_security_information.browser_language).to eq "en-US"
      expect(efile_security_information.platform).to eq "iPad"
      expect(efile_security_information.timezone_offset).to eq "+240"
      expect(efile_security_information.client_system_time).to eq "Mon Aug 02 2021 18:55:41 GMT-0400 (Eastern Daylight Time)"
    end

    context 'when a submission already exists' do
      before do
        create :efile_submission, tax_return: intake.tax_returns.last
      end

      it "does not create another one" do
        expect { described_class.new(intake, params).save }
          .not_to change(intake.tax_returns.last.efile_submissions, :count)
      end
    end

    context "when completed_at has already been set" do
      before do
        intake.touch(:completed_at)
      end

      it "does not overwrite the value" do
        expect { described_class.new(intake, params).save }.not_to change(intake, :completed_at)
      end
    end
  end
end
