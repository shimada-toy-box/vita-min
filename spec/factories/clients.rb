# == Schema Information
#
# Table name: clients
#
#  id                                          :bigint           not null, primary key
#  attention_needed_since                      :datetime
#  completion_survey_sent_at                   :datetime
#  consented_to_service_at                     :datetime
#  ctc_experience_survey_sent_at               :datetime
#  ctc_experience_survey_variant               :integer
#  current_sign_in_at                          :datetime
#  current_sign_in_ip                          :inet
#  experience_survey                           :integer          default("unfilled"), not null
#  failed_attempts                             :integer          default(0), not null
#  filterable_tax_return_properties            :jsonb
#  first_unanswered_incoming_interaction_at    :datetime
#  flagged_at                                  :datetime
#  identity_verification_denied_at             :datetime
#  identity_verified_at                        :datetime
#  in_progress_survey_sent_at                  :datetime
#  last_incoming_interaction_at                :datetime
#  last_internal_or_outgoing_interaction_at    :datetime
#  last_outgoing_communication_at              :datetime
#  last_seen_at                                :datetime
#  last_sign_in_at                             :datetime
#  last_sign_in_ip                             :inet
#  locked_at                                   :datetime
#  login_requested_at                          :datetime
#  login_token                                 :string
#  message_tracker                             :jsonb
#  needs_to_flush_filterable_properties_set_at :datetime
#  previous_sessions_active_seconds            :integer
#  restricted_at                               :datetime
#  routing_method                              :integer
#  sign_in_count                               :integer          default(0), not null
#  still_needs_help                            :integer          default("unfilled"), not null
#  triggered_still_needs_help_at               :datetime
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null
#  vita_partner_id                             :bigint
#
# Indexes
#
#  index_clients_on_consented_to_service_at                      (consented_to_service_at)
#  index_clients_on_filterable_tax_return_properties             (filterable_tax_return_properties) USING gin
#  index_clients_on_in_progress_survey_sent_at                   (in_progress_survey_sent_at)
#  index_clients_on_last_outgoing_communication_at               (last_outgoing_communication_at)
#  index_clients_on_login_token                                  (login_token)
#  index_clients_on_needs_to_flush_filterable_properties_set_at  (needs_to_flush_filterable_properties_set_at)
#  index_clients_on_vita_partner_id                              (vita_partner_id)
#
# Foreign Keys
#
#  fk_rails_...  (vita_partner_id => vita_partners.id)
#
FactoryBot.define do
  factory :client do
    consented_to_service_at { DateTime.current }
    efile_security_informations { [build(:efile_security_information)] }

    trait :with_return do
      transient do
        tax_return_state { "intake_in_progress" }
        filing_status { "single" }
      end
      after(:create) do |client, evaluator|
        create :tax_return, evaluator.tax_return_state, client: client, filing_status: evaluator.filing_status
      end
    end

    factory :client_with_tax_return_state do
      with_return
    end

    trait :with_empty_consent do
      after(:build) do |client|
        create :consent,
               client: client,
               disclose_consented_at: nil,
               use_consented_at: nil,
               global_carryforward_consented_at: nil,
               relational_efin_consented_at: nil
      end
    end

    trait :with_consent do
      after(:build) do |client|
        create :consent, client: client
      end
    end

    factory :client_with_intake_and_return do
      with_return
      transient do
        preferred_name { "Maeby" }
      end
      after(:create) do |client, evaluator|
        create :intake, client: client, preferred_name: evaluator.preferred_name
      end
    end

    factory :client_with_ctc_intake_and_return do
      with_return
      vita_partner do
        ctc_org = VitaPartner.find_or_create_by!(name: "GetCTC.org", type: Organization::TYPE)
        VitaPartner.find_or_create_by!(name: "GetCTC.org (Site)", type: Site::TYPE, parent_organization: ctc_org)
      end
      transient do
        preferred_name { "Maeby" }
        primary_first_name { "Maeby" }
        primary_last_name { "Tomorrow" }
      end

      after(:create) do |client, evaluator|
        create :ctc_intake, client: client, preferred_name: evaluator.preferred_name, primary_first_name: evaluator.primary_first_name, primary_last_name: evaluator.primary_last_name
      end
    end

    factory :ctc_client do
      vita_partner do
        ctc_org = VitaPartner.find_or_create_by!(name: "GetCTC.org", type: Organization::TYPE)
        VitaPartner.find_or_create_by!(name: "GetCTC.org (Site)", type: Site::TYPE, parent_organization: ctc_org)
      end
    end
  end
end
