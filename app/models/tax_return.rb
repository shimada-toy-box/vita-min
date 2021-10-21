# == Schema Information
#
# Table name: tax_returns
#
#  id                  :bigint           not null, primary key
#  certification_level :integer
#  filing_status       :integer
#  filing_status_note  :text
#  internal_efile      :boolean          default(FALSE), not null
#  is_ctc              :boolean          default(FALSE)
#  is_hsa              :boolean
#  primary_signature   :string
#  primary_signed_at   :datetime
#  primary_signed_ip   :inet
#  ready_for_prep_at   :datetime
#  service_type        :integer          default("online_intake")
#  spouse_signature    :string
#  spouse_signed_at    :datetime
#  spouse_signed_ip    :inet
#  status              :integer          default("intake_before_consent"), not null
#  year                :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  assigned_user_id    :bigint
#  client_id           :bigint           not null
#
# Indexes
#
#  index_tax_returns_on_assigned_user_id    (assigned_user_id)
#  index_tax_returns_on_client_id           (client_id)
#  index_tax_returns_on_year_and_client_id  (year,client_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (assigned_user_id => users.id)
#  fk_rails_...  (client_id => clients.id)
#
class TaxReturn < ApplicationRecord
  has_many :tax_return_transitions, autosave: false
  include Statesman::Adapters::ActiveRecordQueries[
              transition_class: TaxReturnTransition,
              initial_state: TaxReturnStateMachine.initial_state
          ]
  PRIMARY_SIGNATURE = "primary".freeze
  SPOUSE_SIGNATURE = "spouse".freeze
  belongs_to :client
  has_one :intake, through: :client
  belongs_to :assigned_user, class_name: "User", optional: true
  has_many :documents
  has_many :assignments, class_name: "TaxReturnAssignment", dependent: :destroy
  has_many :tax_return_selection_tax_returns, dependent: :destroy
  has_many :tax_return_selections, through: :tax_return_selection_tax_returns
  has_many :efile_submissions
  has_one :accepted_tax_return_analytics
  enum status: TaxReturnStatus::STATUSES, _prefix: :status
  enum certification_level: { advanced: 1, basic: 2, foreign_student: 3 }
  enum service_type: { online_intake: 0, drop_off: 1 }, _prefix: :service_type
  # The enum values map to the filing status codes dictated by the IRS
  enum filing_status: { single: 1, married_filing_jointly: 2, married_filing_separately: 3, head_of_household: 4, qualifying_widow: 5 }, _prefix: :filing_status
  validates :year, presence: true

  after_update_commit :send_mixpanel_status_change_event, :send_surveys
  after_update_commit { InteractionTrackingService.record_internal_interaction(client) }

  def state_machine
    @state_machine ||= TaxReturnStateMachine.new(self, transition_class: TaxReturnTransition)
  end

  delegate :can_transition_to?, :history, :last_transition, :last_transition_to,
           :transition_to!, :transition_to, :in_state?, :advance_to, :previous_transition, :previous_state, :last_changed_by, to: :state_machine

  def current_state
    state_machine.last_transition&.to_state || status
  end

  before_save do
    if status == "prep_ready_for_prep" && status_changed?
      self.ready_for_prep_at = DateTime.current
    end
  end

  def qualifying_dependents
    raise StandardError, "Qualifying dependent logic is only valid for 2020.  Define new rules for #{year}." unless year == 2020

    intake.dependents.filter { |d| d.qualifying_child_2020? || d.qualifying_relative_2020? }
  end

  def filing_status_code
    self.class.filing_statuses[filing_status]
  end

  def standard_deduction
    StandardDeduction.for(tax_year: year, filing_status: filing_status)
  end

  def outstanding_recovery_rebate_credit
    return nil unless intake.eip1_amount_received && intake.eip2_amount_received

    [expected_recovery_rebate_credit_one - intake.eip1_amount_received, 0].max + [expected_recovery_rebate_credit_two - intake.eip2_amount_received, 0].max
  end

  def claimed_recovery_rebate_credit
    return 0 if intake.claim_owed_stimulus_money_no?

    outstanding_recovery_rebate_credit
  end

  def rrc_eligible_filer_count
    return intake.primary_tin_type == "ssn" ? 1 : 0 if filing_status_single?

    # if one spouse is a member of the armed forces, both qualify for benefits
    return 2 if [intake.primary_active_armed_forces, intake.spouse_active_armed_forces].any?("yes")

    # only filers with SSNs (valid for employment) are eligible for RRC
    [intake.primary_tin_type, intake.spouse_tin_type].count { |tin_type| tin_type == "ssn" }
  end

  def expected_recovery_rebate_credit_one
    EconomicImpactPaymentOneCalculator.payment_due(
      filer_count: rrc_eligible_filer_count,
      dependent_count: qualifying_dependents.count(&:eligible_for_eip1?)
    )
  end

  def expected_recovery_rebate_credit_two
    EconomicImpactPaymentTwoCalculator.payment_due(
      filer_count: rrc_eligible_filer_count,
      dependent_count: qualifying_dependents.count(&:eligible_for_eip2?)
    )
  end

  def expected_recovery_rebate_credit_three
    EconomicImpactPaymentThreeCalculator.payment_due(
      filer_count: rrc_eligible_filer_count,
      dependent_count: intake.dependents.count(&:eligible_for_eip3?)
    )
  end

  def expected_advance_ctc_payments
    ChildTaxCreditCalculator.total_advance_payment(self)
  end

  def has_submissions?
    efile_submissions.count.nonzero?
  end

  def record_expected_payments!
    raise StandardError, "Cannot record payments on tax return that is not accepted" unless status == "file_accepted"

    create_accepted_tax_return_analytics!(
      advance_ctc_amount_cents: expected_advance_ctc_payments ? expected_advance_ctc_payments * 100 : 0,
      refund_amount_cents: claimed_recovery_rebate_credit ? claimed_recovery_rebate_credit * 100 : 0,
      eip3_amount_cents: expected_recovery_rebate_credit_three ? expected_recovery_rebate_credit_three * 100 : 0
    )
  end

  def self.filing_years
    [2020, 2019, 2018, 2017]
  end

  def self.service_type_options
    [[I18n.t("general.drop_off"), "drop_off"], [I18n.t("general.online"), "online_intake"]]
  end

  def filing_jointly?
    filing_status == "married_filing_jointly" || intake&.filing_joint == "yes"
  end

  def primary_has_signed_8879?
    primary_signature.present? && primary_signed_after_unsigned_8879_upload? && primary_signed_ip?
  end

  def spouse_has_signed_8879?
    spouse_signature.present? && spouse_signed_after_unsigned_8879_upload? && spouse_signed_ip?
  end

  def primary_signed_after_unsigned_8879_upload?
    return false unless primary_signed_at.present?
    return true if unsigned_8879s.empty?

    unsigned_8879s.pluck(:created_at).max < primary_signed_at
  end

  def spouse_signed_after_unsigned_8879_upload?
    return false unless spouse_signed_at.present?
    return true if unsigned_8879s.empty?

    unsigned_8879s.pluck(:created_at).max < spouse_signed_at
  end

  def ready_for_8879_signature?(signature_type)
    case signature_type
    when TaxReturn::PRIMARY_SIGNATURE
      return true if unsigned_8879s.present? && !primary_has_signed_8879?
    when TaxReturn::SPOUSE_SIGNATURE
      return true if unsigned_8879s.present? && filing_jointly? && !spouse_has_signed_8879?
    else
      raise StandardError, "Invalid signature_type parameter"
    end
    false
  end

  def completely_signed_8879?
    if filing_jointly?
      primary_has_signed_8879? && spouse_has_signed_8879?
    else
      primary_has_signed_8879?
    end
  end

  def ready_to_file?
    (filing_jointly? && primary_has_signed_8879? && spouse_has_signed_8879?) || (!filing_jointly? && primary_has_signed_8879?)
  end

  def unsigned_8879s
    documents.active.where(document_type: DocumentTypes::UnsignedForm8879.key)
  end

  def signed_8879s
    documents.active.where(document_type: DocumentTypes::CompletedForm8879.key)
  end

  def final_tax_documents
    documents.active.where(document_type: DocumentTypes::FinalTaxDocument.key)
  end

  def sign_primary!(ip)
    unless unsigned_8879s.present?
      raise AlreadySignedError if primary_has_signed_8879?
    end

    sign_successful = ActiveRecord::Base.transaction do
      self.primary_signed_at = DateTime.current
      self.primary_signed_ip = ip
      self.primary_signature = client.legal_name || "N/A"

      if ready_to_file?
        system_change_status(:file_ready_to_file)
        Sign8879Service.create(self)
        SystemNote::SignedDocument.generate!(signed_by_type: :primary, tax_return: self)
        client.flag!
      else
        SystemNote::SignedDocument.generate!(signed_by_type: :primary, waiting: true, tax_return: self)
      end
      save!
    end

    raise FailedToSignReturnError unless sign_successful

    true
  end

  def sign_spouse!(ip)
    unless unsigned_8879s.present?
      raise AlreadySignedError if spouse_has_signed_8879?
    end

    sign_successful = ActiveRecord::Base.transaction do
      self.spouse_signed_at = DateTime.current
      self.spouse_signed_ip = ip
      self.spouse_signature = client.spouse_legal_name || "N/A"

      if ready_to_file?
        system_change_status(:file_ready_to_file)
        Sign8879Service.create(self)
        SystemNote::SignedDocument.generate!(signed_by_type: :spouse, tax_return: self)
        client.flag!
      else
        SystemNote::SignedDocument.generate!(signed_by_type: :spouse, waiting: true, tax_return: self)
      end
      save!
    end

    raise FailedToSignReturnError unless sign_successful

    true
  end

  def assign!(assigned_user: nil, assigned_by: nil)
    update!(assigned_user: assigned_user)
    SystemNote::AssignmentChange.generate!(initiated_by: assigned_by, tax_return: self)

    if assigned_user.present? && (assigned_user != assigned_by)
      UserNotification.create!(
        user: assigned_user,
        notifiable: TaxReturnAssignment.create!(
          assigner: assigned_by,
          tax_return: self
        )
      )
      UserMailer.assignment_email(
        assigned_user: assigned_user,
        assigning_user: assigned_by,
        assigned_at: updated_at,
        tax_return: self
      ).deliver_later
    end
  end

  private

  def send_mixpanel_status_change_event
    if saved_change_to_status?
      MixpanelService.send_status_change_event(self)

      if status == "file_rejected"
        MixpanelService.send_file_rejected_event(self)
      elsif status == "file_accepted"
        MixpanelService.send_file_accepted_event(self)
      elsif status == "prep_ready_for_prep"
        MixpanelService.send_tax_return_event(self, "ready_for_prep")
      elsif status == "file_efiled"
        MixpanelService.send_tax_return_event(self, "filing_filed")
      end
    end
  end

  def system_change_status(new_status)
    SystemNote::StatusChange.generate!(tax_return: self, old_status: current_state, new_status: new_status)
    transition_to(new_status)
  end

  def send_surveys
    if saved_change_to_status? && TaxReturnStatus::TERMINAL_STATUSES.map(&:to_s).include?(status)
      if is_ctc && service_type_online_intake?
        SendClientCtcExperienceSurveyJob.set(wait_until: Time.current + 1.day).perform_later(client)
      end

      if !is_ctc
        SendClientCompletionSurveyJob.set(wait_until: Time.current + 1.day).perform_later(client)
      end
    end
  end
end

class FailedToSignReturnError < StandardError; end

class AlreadySignedError < StandardError; end
