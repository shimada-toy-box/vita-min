# == Schema Information
#
# Table name: dependents
#
#  id                                          :bigint           not null, primary key
#  birth_date                                  :date
#  born_in_2020                                :integer          default(0), not null
#  can_be_claimed_by_other                     :integer          default(0), not null
#  claim_anyhow                                :integer          default(0), not null
#  disabled                                    :integer          default("unfilled"), not null
#  encrypted_ip_pin                            :string
#  encrypted_ip_pin_iv                         :string
#  encrypted_ssn                               :string
#  encrypted_ssn_iv                            :string
#  filed_joint_return                          :integer          default(0), not null
#  first_name                                  :string
#  full_time_student                           :integer          default(0), not null
#  has_ip_pin                                  :integer          default("unfilled"), not null
#  last_name                                   :string
#  lived_with_less_than_six_months             :integer          default(0), not null
#  meets_misc_qualifying_relative_requirements :integer          default(0), not null
#  middle_initial                              :string
#  months_in_home                              :integer
#  no_ssn_atin                                 :integer          default(0), not null
#  north_american_resident                     :integer          default("unfilled"), not null
#  on_visa                                     :integer          default("unfilled"), not null
#  passed_away_2020                            :integer          default(0), not null
#  permanent_residence_with_client             :integer          default(0), not null
#  permanently_totally_disabled                :integer          default(0), not null
#  placed_for_adoption                         :integer          default(0), not null
#  provided_over_half_own_support              :integer          default(0), not null
#  relationship                                :string
#  tin_type                                    :integer
#  was_married                                 :integer          default("unfilled"), not null
#  was_student                                 :integer          default("unfilled"), not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null
#  intake_id                                   :bigint           not null
#
# Indexes
#
#  index_dependents_on_intake_id  (intake_id)
#

require "rails_helper"

describe Dependent do
  it "strips leading or trailing spaces from any free-text attributes" do
    dependent = Dependent.new(
      first_name: "  doug",
      last_name: "  douglasson",
      middle_initial: "   XYZ ",
      ssn: "000000000 ",
      ip_pin: "000111 "
    )
    dependent.valid?
    expect(dependent.attributes).to match(a_hash_including({
      "first_name" => "doug",
      "last_name" => "douglasson",
      "middle_initial" => "XYZ",
    }))
    expect(dependent.ip_pin).to eq("000111")
    expect(dependent.ssn).to eq("000000000")
  end

  describe "validations" do
    it "requires essential fields" do
      dependent = Dependent.new

      expect(dependent).to_not be_valid
      expect(dependent.errors).to include :intake
      expect(dependent.errors).to include :first_name
      expect(dependent.errors).to include :last_name
      expect(dependent.errors).to include :birth_date
    end
  end

  describe "#full_name_and_birthdate" do
    let(:dependent) do
      build :dependent, first_name: "Kara", last_name: "Kiwi", birth_date: Date.new(2013, 5, 9)
    end

    it "returns a concatenated string with formatted date" do
      expect(dependent.full_name_and_birth_date).to eq "Kara Kiwi 5/9/2013"
    end
  end

  describe "#age_at_end_of_year" do
    let(:dependent) { build :dependent, birth_date: dob }
    let(:intake_double) { instance_double("Intake", tax_year: tax_year) }
    before { allow(dependent).to receive(:intake).and_return intake_double }

    context "a kid born the same year as the tax year" do
      let(:dob) { Date.new(2019, 12, 31) }
      let(:tax_year) { 2019 }
      it "returns 0" do
        expect(dependent.age_at_end_of_year(tax_year)).to eq 0
      end
    end

    context "a kid born in 2015 at end of 2019" do
      let(:dob) { Date.new(2015, 12, 25) }
      let(:tax_year) { 2019 }
      it "returns 4" do
        expect(dependent.age_at_end_of_year(tax_year)).to eq 4
      end
    end
  end

  describe "#mixpanel_data" do
    let(:dependent) do
      build(
        :dependent,
        birth_date: Date.new(2015, 6, 15),
        relationship: "Nibling",
        months_in_home: 12,
        was_student: "no",
        on_visa: "no",
        north_american_resident: "yes",
        disabled: "no",
        was_married: "no"
      )
    end

    it "returns the expected hash" do
      expect(dependent.mixpanel_data).to eq({
        dependent_age_at_end_of_tax_year: "4",
        dependent_under_6: "yes",
        dependent_months_in_home: "12",
        dependent_was_student: "no",
        dependent_on_visa: "no",
        dependent_north_american_resident: "yes",
        dependent_disabled: "no",
        dependent_was_married: "no",
      })
    end
  end
end
