module Ctc
  class BaseSpouseForm < QuestionsForm
    include DateHelper

    validates :spouse_first_name, presence: true, legal_name: true
    validates :spouse_last_name, presence: true, legal_name: true
    validates :spouse_middle_initial, length: { maximum: 1 }, format: { with: /\A[A-Za-z]\z/.freeze, message: I18n.t('validators.alpha'), allow_blank: true }
    validate  :spouse_birth_date_is_valid_date
    validates :spouse_ssn, social_security_number: true, if: -> { ["ssn", "ssn_no_employment"].include?(spouse_tin_type) && spouse_ssn.present? }
    validates :spouse_ssn, individual_taxpayer_identification_number: true, if: -> { spouse_tin_type == "itin" }

    with_options if: -> { (spouse_ssn.present? && spouse_ssn.remove("-") != intake.spouse.ssn) || spouse_ssn_confirmation.present? } do
      validates :spouse_ssn, confirmation: true
      validates :spouse_ssn_confirmation, presence: true
    end

    validates_presence_of :spouse_ssn, message: -> (_object, _data) { I18n.t('views.ctc.questions.spouse_info.ssn_required_message') }, if: -> { spouse_tin_type != "none" }

    def save
      @intake.update(attributes_for(:intake).merge(
        spouse_birth_date: spouse_birth_date,
      ))
    end

    def self.existing_attributes(intake, attribute_keys)
      if intake.spouse.birth_date.present?
        super.merge(
          spouse_birth_date_day: intake.spouse.birth_date.day,
          spouse_birth_date_month: intake.spouse.birth_date.month,
          spouse_birth_date_year: intake.spouse.birth_date.year,
        )
      else
        super
      end
    end

    private

    def spouse_birth_date
      parse_date_params(spouse_birth_date_year, spouse_birth_date_month, spouse_birth_date_day)
    end

    def spouse_birth_date_is_valid_date
      valid_text_birth_date(spouse_birth_date_year, spouse_birth_date_month, spouse_birth_date_day, :spouse_birth_date)
    end
  end
end
