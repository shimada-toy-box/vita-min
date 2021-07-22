# == Schema Information
#
# Table name: dependents
#
#  id                                          :bigint           not null, primary key
#  birth_date                                  :date
#  born_in_2020                                :integer          default("unfilled"), not null
#  can_be_claimed_by_other                     :integer          default("unfilled"), not null
#  claim_regardless                            :integer          default("unfilled"), not null
#  disabled                                    :integer          default("unfilled"), not null
#  encrypted_ip_pin                            :string
#  encrypted_ip_pin_iv                         :string
#  encrypted_ssn                               :string
#  encrypted_ssn_iv                            :string
#  filed_joint_return                          :integer          default("unfilled"), not null
#  first_name                                  :string
#  full_time_student                           :integer          default("unfilled"), not null
#  has_ip_pin                                  :integer          default("unfilled"), not null
#  last_name                                   :string
#  lived_with_less_than_six_months             :integer          default("unfilled"), not null
#  meets_misc_qualifying_relative_requirements :integer          default("unfilled"), not null
#  middle_initial                              :string
#  months_in_home                              :integer
#  no_ssn_atin                                 :integer          default("unfilled"), not null
#  north_american_resident                     :integer          default("unfilled"), not null
#  on_visa                                     :integer          default("unfilled"), not null
#  passed_away_2020                            :integer          default("unfilled"), not null
#  permanent_residence_with_client             :integer          default("unfilled"), not null
#  permanently_totally_disabled                :integer          default("unfilled"), not null
#  placed_for_adoption                         :integer          default("unfilled"), not null
#  provided_over_half_own_support              :integer          default("unfilled"), not null
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

FactoryBot.define do
  factory :dependent do
    intake
    first_name { "Kara" }
    last_name { "Kiwi" }
    birth_date { Date.new(2011, 3, 5) }
    relationship { "daughter" }
    north_american_resident { "yes" }
    on_visa { "no" }
    months_in_home { 11 }
    was_married { "no" }
    was_student { "yes" }
    disabled { "no" }
    sequence(:ssn) do |n|
      if intake.is_ctc?
        "88811#{"%04d" % (n % 1000)}"
      else
        nil
      end
    end
  end
end
