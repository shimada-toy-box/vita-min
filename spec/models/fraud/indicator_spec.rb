# == Schema Information
#
# Table name: fraud_indicators
#
#  id                   :bigint           not null, primary key
#  activated_at         :datetime
#  description          :text
#  indicator_attributes :string           default([]), is an Array
#  indicator_type       :string
#  list_model_name      :string
#  multiplier           :float
#  name                 :string
#  points               :integer
#  query_model_name     :string
#  reference            :string
#  threshold            :float
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
require "rails_helper"

describe Fraud::Indicator do
  before do
    stub_const("Fraud::Indicator::Bunny", Class.new do
      attr_accessor :pet_name
      attr_accessor :extra_points

      def initialize(pet_name:, extra_points:)
        @pet_name = pet_name
        @extra_points = extra_points
      end

      def self.comparison_column
        :pet_name
      end

      def self.safelist
        ["Bunny", "Peter", "Rabbit", "Bugs"]
      end

      def self.riskylist_records
        [
          new(pet_name: "Dog", extra_points: nil),
          new(pet_name: "Pluto", extra_points: 10),
          new(pet_name: "Mickey", extra_points: nil),
          new(pet_name: "Cat", extra_points: nil)
        ]
      end
    end)
  end

  describe '#execute' do
    let(:indicator) { described_class.new(indicator_type: "average_under", indicator_attributes: ["something"], threshold: "5") }
    context "when the reference is the same type as the query_model_name" do
      let(:client) { create :client }
      let(:query_double) { double }
      before do
        indicator.reference = "client"
        indicator.query_model_name = "Client"
        allow(Client).to receive(:where).and_return query_double
        allow(query_double).to receive(:average)
      end

      it "builds the scoped query using a single object" do
        indicator.execute(client: client)
        expect(Client).to have_received(:where).with(id: client.id)
      end
    end

    context "when the reference is a different type than the query_model_name" do
      let(:client) { create :client }
      let(:query_double) { double }
      before do
        indicator.reference = "client"
        indicator.query_model_name = "Intake"
        allow(Intake).to receive(:where).and_return query_double
        allow(query_double).to receive(:average)
      end

      it "builds the scoped query using a single object" do
        indicator.execute(client: client)
        expect(Intake).to have_received(:where).with("client" => client)
      end
    end

    context "when the reference is intake and query_model_name is Intake::CtcIntake" do
      let(:intake) { create :intake }
      let(:query_double) { double }
      before do
        indicator.reference = "intake"
        indicator.query_model_name = "Intake::CtcIntake"
        allow(Intake::CtcIntake).to receive(:where).and_return query_double
        allow(query_double).to receive(:average)
      end

      it "builds the scoped query as a self-reference" do
        indicator.execute(intake: intake)
        expect(Intake::CtcIntake).to have_received(:where).with(id: intake.id)
      end
    end

    context "when the indicator type has a defined method" do
      before do
        allow(indicator).to receive(:average_under)
      end

      it "calls the indicator_type method on the class with passed reference" do
        indicator.execute(client: create(:client), tax_return: create(:tax_return), efile_submission: create(:efile_submission), intake: create(:ctc_intake), bank_account: create(:bank_account))
        expect(indicator).to have_received(:average_under).with({
                                                              client: an_instance_of(Client),
                                                              efile_submission: an_instance_of(EfileSubmission),
                                                              intake: an_instance_of(Intake::CtcIntake),
                                                              bank_account: an_instance_of(BankAccount),
                                                              tax_return: an_instance_of(TaxReturn)
                                                          })
      end
    end
  end

  describe "#average_under" do
    let(:fraud_indicator) { described_class.new(name: "too_short", indicator_type: "average_under", reference: "client", indicator_attributes: ["height"], threshold: "60", query_model_name: "Intake", points: 80) }
    let(:query_double) { double }
    let(:client) { create :client }

    before do
      allow(Intake).to receive(:where).and_return query_double
      allow(query_double).to receive(:average).and_return 40
    end

    context "validations" do
      it "is not valid without the appropriate data" do
        indicator = described_class.new(indicator_type: "average_under")
        expect(indicator.valid?).to eq false
        expect(indicator.errors[:name]).to include "Can't be blank."
        expect(indicator.errors[:indicator_attributes]).to include "must have length of 1"
        expect(indicator.errors[:threshold]).to include "is not a number"
        expect(indicator.errors[:query_model_name]).to include "Can't be blank."
        expect(indicator.errors[:reference]).to include "Can't be blank."
      end
    end

    it "builds a proper query" do
      expect(fraud_indicator.execute(client: client)).to eq [80, [40]]
      expect(query_double).to have_received(:average).with("height")
    end

    context "when average query returns nil (there are no objects to average)" do
      before do
        allow(query_double).to receive(:average).and_return nil
      end

      it "returns true (yes, is indicator of potential fraudiness)" do
        expect(fraud_indicator.execute(client: client)).to eq [80, [nil]]
      end
    end
  end

  describe "#not_in_safelist" do
    let(:fraud_indicator) { described_class.new(name: "fraudy_if_not_a_bunny_name", points: 120, indicator_type: "not_in_safelist", reference: "intake", indicator_attributes: ["primary_first_name"], query_model_name: "Intake", list_model_name: "Fraud::Indicator::Bunny") }
    let(:query_double) { double }
    let(:intake) { create :intake, primary_first_name: "Tiger" }

    context "validations" do
      it "is not valid without the appropriate data" do
        indicator = described_class.new(indicator_type: "not_in_safelist")
        expect(indicator.valid?).to eq false
        expect(indicator.errors[:name]).to include "Can't be blank."
        expect(indicator.errors[:indicator_attributes]).to include "must have length of 1"
        expect(indicator.errors[:query_model_name]).to include "Can't be blank."
        expect(indicator.errors[:list_model_name]).to include "Can't be blank."
        expect(indicator.errors[:reference]).to include "Can't be blank."
      end
    end

    context "when generating a query" do
      before do
        allow(Intake).to receive(:where).and_return query_double
        allow(query_double).to receive_message_chain(:where, :not).and_return query_double # ensure a ActiveRecord query object
        allow(query_double).to receive(:pluck).and_return []
      end

      it "builds the appropriate query" do
        fraud_indicator.execute(intake: intake)
        expect(query_double.where).to have_received(:not).with("primary_first_name" => Fraud::Indicator::Bunny.safelist)
      end
    end

    context "when the excluded name appears in the set" do
      it "indicates fraud" do
        expect(fraud_indicator.execute(intake: intake)).to eq [120, ["Tiger"]]
      end
    end
  end

  describe "#in_riskylist" do
    let(:fraud_indicator) { described_class.new(name: "not_a_bunny", points: 60, indicator_type: "in_riskylist", reference: "intake", indicator_attributes: ["primary_first_name"], query_model_name: "Intake", list_model_name: "Fraud::Indicator::Bunny") }
    let(:query_double) { double }
    let(:intake) { create :intake, primary_first_name: "Mickey" }

    context "validations" do
      it "is not valid without the appropriate data" do
        indicator = described_class.new(indicator_type: "in_riskylist")
        expect(indicator.valid?).to eq false
        expect(indicator.errors[:name]).to include "Can't be blank."
        expect(indicator.errors[:indicator_attributes]).to include "must have length of 1"
        expect(indicator.errors[:query_model_name]).to include "Can't be blank."
        expect(indicator.errors[:list_model_name]).to include "Can't be blank."
        expect(indicator.errors[:reference]).to include "Can't be blank."
      end
    end

    context "when generating a query" do
      before do
        allow(Intake).to receive(:where).and_return query_double
        allow(query_double).to receive_message_chain(:find_by).and_return nil
      end

      it "builds the appropriate query" do
        fraud_indicator.execute(intake: intake)
        expect(query_double).to have_received(:find_by).with("primary_first_name" => Fraud::Indicator::Bunny.riskylist_records.map(&:pet_name))
      end
    end

    context "with a name from the riskylist" do
      it "indicates fraud" do
        expect(fraud_indicator.execute(intake: intake)).to eq [60, ["Mickey"]]
      end
    end

    context "with a name from the riskylist that has extra points" do
      let(:intake) { create :intake, primary_first_name: "Pluto" }

      it "indicates fraud with more points" do
        expect(fraud_indicator.execute(intake: intake)).to eq [70, ["Pluto"]]
      end
    end
  end

  describe "#duplicates" do
    let(:query_double) { double }
    let(:intake) { create :ctc_intake, primary_first_name: "Roger", primary_last_name: "Rabbit" }
    let(:client) { create :client }
    let(:fraud_indicator) { described_class.new(name: "duplicated_stuff", points: 80, multiplier: 0.25, indicator_type: "duplicates", reference: "intake", query_model_name: "Intake::CtcIntake", indicator_attributes: [:primary_first_name, :primary_last_name]) }

    context "validations" do
      it "is not valid without the appropriate data" do
        indicator = described_class.new(indicator_type: "duplicates")
        expect(indicator.valid?).to eq false
        expect(indicator.errors[:name]).to include "Can't be blank."
        expect(indicator.errors[:indicator_attributes]).to include "must have minimum length of 1"
        expect(indicator.errors[:query_model_name]).to include "Can't be blank."
        expect(indicator.errors[:reference]).to include "Can't be blank."
      end
    end

    before do
      allow(DeduplicationService).to receive(:duplicates).and_return query_double
      allow(query_double).to receive(:pluck).and_return [1,2,3]
    end

    context "when the query_model_name responds to accessible_intakes" do
      it "sets up the query to only look at accessible intakes" do
        fraud_indicator.execute(intake: intake, client: client)
        expect(DeduplicationService).to have_received(:duplicates).with(intake, "primary_first_name", "primary_last_name", from_scope: Intake::CtcIntake.accessible_intakes)
      end
    end

    context "when the query_model_name does not respond to accessible_intakes" do
      before do
        fraud_indicator.query_model_name = "EfileSecurityInformation"
      end

      it "sets up the query correctly" do
        fraud_indicator.execute(intake: intake, client: client)
        expect(DeduplicationService).to have_received(:duplicates).with(intake, "primary_first_name", "primary_last_name", from_scope: EfileSecurityInformation)
      end
    end

    context "when the values are nil for the duplicated data" do
      before do
        fraud_indicator.indicator_attributes = [:primary_first_name]
        intake.update(primary_first_name: nil)
      end

      it "does not execute the duplification query and returns a passing response" do
        expect(fraud_indicator.execute(intake: intake)).to eq [0, []]
        expect(DeduplicationService).not_to have_received(:duplicates)
      end
    end


    context "when there are duplicates" do
      it "returns the count of duplicates" do
        multiplied_score = (80 + (2 * 2 * 0.25 * 80)).to_i
        expect(fraud_indicator.execute(intake: intake, client: client)).to eq [multiplied_score, [1,2,3]]
      end

      context "when there are duplicates, but the threshold is greater than the number of duplicates" do
        before do
          fraud_indicator.threshold = 5
        end

        it "provides the duplicates but the score is 0" do
          expect(fraud_indicator.execute(intake: intake, client: client)).to eq [0, [1,2,3]]
        end
      end
    end

    context "when there are no duplicates" do
      before do
        allow(query_double).to receive(:pluck).and_return []
      end

      it "returns the count of duplicates" do
        expect(fraud_indicator.execute(intake: intake, client: client)).to eq [0, []]
      end
    end

    context "if there is no reference object to compare it to" do
      before do
        fraud_indicator.update(reference: "something_different")
      end
      it "bypasses running the query and returns a 0 point result" do
        expect(fraud_indicator.execute(intake: intake, client: client)).to eq [0, []]
      end
    end
  end

  describe "#missing_relationship" do
    let(:tax_return) { create :tax_return }
    let(:efile_submission) { create :efile_submission }
    let(:fraud_indicator) { described_class.create(name: "no_transitions", points: 5, indicator_type: "missing_relationship", query_model_name: "EfileSubmission", reference: "tax_return", indicator_attributes: ["efile_submission_transitions"]) }

    context "validations" do
      it "is not valid without the appropriate data" do
        indicator = described_class.new(indicator_type: "missing_relationship")
        expect(indicator.valid?).to eq false
        expect(indicator.errors[:name]).to include "Can't be blank."
        expect(indicator.errors[:indicator_attributes]).to include "must have length of 1"
        expect(indicator.errors[:query_model_name]).to include "Can't be blank."
        expect(indicator.errors[:reference]).to include "Can't be blank."
      end
    end

    context "when the reference's query model record is missing the relationship" do
      let!(:efile_submission) { create :efile_submission, tax_return: tax_return }

      it "returns some points" do
        expect(fraud_indicator.execute(tax_return: tax_return)).to eq [5, []]
      end
    end

    context "when the reference's query model record is not missing the relationship" do
      let!(:efile_submission) { create :efile_submission, :new, tax_return: tax_return }

      it "returns zero points" do
        expect(fraud_indicator.execute(tax_return: tax_return)).to eq [0, []]
      end
    end

    context "when the rule is self-referencing" do
      before do
        allow(EfileSubmission).to receive(:where).and_call_original
      end

      let(:fraud_indicator) { described_class.create(name: "no_transitions", points: 5, indicator_type: "missing_relationship", query_model_name: "EfileSubmission", reference: "efile_submission", indicator_attributes: ["efile_submission_transitions"]) }
      it "builds a where query on the query_model using id" do
        fraud_indicator.execute(efile_submission: efile_submission)
        expect(EfileSubmission).to have_received(:where).with(id: efile_submission.id)
      end
    end
  end

  describe "#equals" do
    let(:fraud_indicator) { described_class.create(name: "no_accepted", points: 12, indicator_type: "equals", query_model_name: "Intake", reference: "client", indicator_attributes: ["primary_first_name", "Martin"]) }
    let(:query_double) { double }
    let(:client) { create :client }
    before do
      allow(Intake).to receive(:where).and_return query_double
      allow(query_double).to receive(:where).and_return query_double # ensure a ActiveRecord query object
      allow(query_double).to receive(:exists?).and_return true
    end

    context "validations" do
      it "is not valid without the appropriate data" do
        indicator = described_class.new(indicator_type: "equals")
        expect(indicator.valid?).to eq false
        expect(indicator.errors[:name]).to include "Can't be blank."
        expect(indicator.errors[:indicator_attributes]).to include "must have length of 2"
        expect(indicator.errors[:query_model_name]).to include "Can't be blank."
        expect(indicator.errors[:reference]).to include "Can't be blank."
      end
    end

    it "builds the appropriate query" do
      fraud_indicator.execute(client: client)
      expect(Intake).to have_received(:where).with({ "client" => client })
      expect(query_double).to have_received(:where).with({ "primary_first_name" => "Martin" })
    end

    it "returns the right stuff" do
      expect(fraud_indicator.execute(client: client)).to eq [12, []]
    end
  end

  describe "#gem" do
    let(:fraud_indicator) { described_class.create(name: "gem_method", points: 7, indicator_type: "gem", query_model_name: "Intake", reference: "intake", indicator_attributes: %w[bank_name primary_first_name primary_last_name]) }
    let(:intake) { create :intake, primary_first_name: "Mickey", primary_last_name: "Mouse", bank_name: "abc inc" }
    let(:gem_double) { double } # not using an instance double so we can obfuscate the real method name

    before do
      allow(FraudGem).to receive(:new).and_return(gem_double)
    end

    context "when the gem indicates fraud" do
      before do
        allow(gem_double).to receive(:gem_method).with(value1: 'abc inc', value2: 'Mickey', value3: 'Mouse').and_return(true)
      end

      it "returns points" do
        expect(fraud_indicator.execute(intake: intake)).to eq [7, []]
      end
    end

    context "when the gem indicates not fraud" do
      before do
        allow(gem_double).to receive(:gem_method).with(value1: 'abc inc', value2: 'Mickey', value3: 'Mouse').and_return(false)
      end

      it "returns no points" do
        expect(fraud_indicator.execute(intake: intake)).to eq [0, []]
      end
    end

    context "validations" do
      it "is not valid without the appropriate data" do
        indicator = described_class.new(indicator_type: "gem")
        expect(indicator.valid?).to eq false
        expect(indicator.errors[:name]).to include "Can't be blank."
        expect(indicator.errors[:indicator_attributes]).to include "must have length of 3"
        expect(indicator.errors[:query_model_name]).to include "Can't be blank."
        expect(indicator.errors[:reference]).to include "Can't be blank."
      end
    end
  end
end
