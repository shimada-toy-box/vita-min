require "rails_helper"

describe Efile::DependentEligibility::ChildTaxCredit do
  context "when passing in an eligibility object" do
    let(:child_eligibility) { double }
    before do
      allow(child_eligibility).to receive(:qualifies?).and_return true
      allow(Efile::DependentEligibility::QualifyingChild).to receive(:new)
    end

    it "uses the passed in object instead of instantiating a new one" do
      described_class.new((create :dependent), TaxReturn.current_tax_year, child_eligibility: child_eligibility)
      expect(child_eligibility).to have_received(:qualifies?)
    end
  end

  context "when not passing in an eligibility object" do
    let(:intake) { create :ctc_intake, client: create(:client, :with_return) }
    let(:dependent) { create :dependent, intake: intake }
    let(:child_eligibility) { double }
    before do
      allow(child_eligibility).to receive(:qualifies?).and_return true
    end

    it "instantiates a new eligibility object" do
      described_class.new(dependent, TaxReturn.current_tax_year)
      expect(child_eligibility).not_to have_received(:qualifies?)
    end
  end

  context "when the intake says that ctc is disallowed" do
    let(:intake) { create :ctc_intake, client: (create :client, :with_return), disallowed_ctc: true }
    let(:dependent) { create :qualifying_child, intake: intake }
    it "makes the dependent disqualified" do
      subject = described_class.new(dependent, TaxReturn.current_tax_year)
      expect(subject.qualifies?).to eq false
      expect(subject.disqualifiers).to include :disallowed_test
    end
  end

  context "prequalifying attribute" do
    subject { described_class.new(efile_submission_dependent, TaxReturn.current_tax_year) }
    before do
      allow(subject).to receive(:run_tests).and_call_original
    end
    context "when the object is a SubmissionDependent and qualifying_ctc is true" do
      let!(:efile_submission_dependent) { create :efile_submission_dependent, qualifying_ctc: true }

      it "returns true for qualifying, without running all qualifying logic again" do
        expect(subject).not_to have_received(:run_tests)
        expect(subject.qualifies?).to eq true
      end
    end

    context "when the object is an EfileSubmissionDependent and qualifying_ctc false" do
      let!(:efile_submission_dependent) { create :efile_submission_dependent, qualifying_ctc: false }
      it "returns false for qualifying, without running qualifying logic again" do
        expect(subject).not_to have_received(:run_tests)
        expect(subject.qualifies?).to eq false
      end
    end
  end
end