require "rails_helper"

describe SubmissionBuilder::Documents::Scenario5Irs1040 do
  let(:submission) { TestSubmissions::Scenario5Submission.create_submission }
  context 'with the scenario 5 data' do
    it 'conforms to the schema' do
      expect(described_class.build(submission)).to be_valid
    end
  end
end