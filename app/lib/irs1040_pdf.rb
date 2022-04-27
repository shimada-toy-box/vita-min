class Irs1040Pdf
  attr_accessor :address
  include PdfHelper

  def source_pdf_name
    "f1040-TY2021"
  end

  def initialize(submission)
    @submission = submission
    @tax_return = submission.tax_return
    @intake = submission.intake
    @qualifying_dependents = submission.qualifying_dependents
    @address = @submission.verified_address || @intake.address
    @benefits = Efile::BenefitsEligibility.new(tax_return: @tax_return, dependents: @qualifying_dependents)
  end

  def hash_for_pdf
    total_refundable_credits = @benefits.claimed_recovery_rebate_credit.to_i + @benefits.outstanding_ctc_amount
    answers = {
        FilingStatus: @tax_return.filing_status_code,
        PrimaryFirstNm: @intake.primary_middle_initial.present? ? "#{@intake.primary_first_name} #{@intake.primary_middle_initial}" : @intake.primary_first_name,
        PrimaryLastNm: @intake.primary_last_name,
        PrimarySSN: @intake.primary_ssn,
        AddressLine1Txt: @address&.street_address,
        CityNm: @address&.city,
        StateAbbreviationCd: @address&.state,
        ZipCd: @address&.zip_code,
        VirtualCurAcquiredDurTYInd: @intake.has_crypto_income,
        PrimaryBlindInd: bool_checkbox(@intake.was_blind_yes?),
        TotalItemizedOrStandardDedAmt12a: @tax_return.standard_deduction,
        TotalAdjustmentsToIncomeAmt12c: @tax_return.standard_deduction, # 12c = 12a + 12b; 12b is charitable contributions which is 0 for us
        TotalDeductionsAmt14: @tax_return.standard_deduction, # 14 = 12c + 13; 13 is business income deduction which we leave blank
        TaxableIncomeAmt15: 0,
        AdditionalChildTaxCreditAmt28: @benefits.outstanding_ctc_amount,
        RecoveryRebateCreditAmt30: @benefits.claimed_recovery_rebate_credit.to_i,
        RefundableCreditsAmt32: total_refundable_credits,
        TotalPaymentsAmt33: total_refundable_credits,
        OverpaidAmt34: total_refundable_credits,
        RefundAmt35: total_refundable_credits,
        Primary65OrOlderInd: bool_checkbox(@tax_return.primary_age_65_or_older?),
        PrimarySignature: @intake.primary_full_name,
        PrimarySignatureDate: @intake.primary_signature_pin_at&.strftime("%m/%d/%y"),
        PrimaryIPPIN: @intake.primary_ip_pin,
        PhoneNumber:  @intake.formatted_phone_number || @intake.formatted_sms_phone_number,
        EmailAddress: @intake.email_address
    }
    answers.merge!(spouse_info) if @tax_return.filing_jointly?
    answers.merge!(dependents_info) if @qualifying_dependents.count.nonzero?
    answers
  end

  def bank_account_info
    return {} unless @intake.bank_account.present?

    {
        RoutingTransitNum35b: pdf_mask(@intake.bank_account.routing_number, 4),
        DepositorAccountNum35d: pdf_mask(@intake.bank_account.account_number, 4),
        BankAccountTypeCd: @intake.bank_account.account_type.titleize
    }
  end

  def spouse_info
    {
        Spouse65OrOlderInd: bool_checkbox(@tax_return.spouse_age_65_or_older?),
        SpouseFirstNm: @intake.spouse_first_name,
        SpouseLastNm: @intake.spouse_last_name,
        SpouseSSN: @intake.spouse_ssn,
        SpouseSignature: @intake.spouse_full_name,
        SpouseSignatureDate: @intake.spouse_signature_pin_at.strftime("%m/%d/%y"),
        SpouseIPPIN: @intake.spouse_ip_pin,
        SpouseBlindInd: bool_checkbox(@intake.spouse_was_blind_yes?),
    }
  end

  # TODO: The tax form only allows for 4 dependents. In the case where we have more than 4 dependents, we
  # really ought to attach a second page with dependent information.
  def dependents_info
    answers = {}
    @qualifying_dependents.first(4).each_with_index do |dependent, index|
      answers["DependentLegalNm[#{index}]"] = dependent.full_name
      answers["DependentRelationship[#{index}]"] = dependent.irs_relationship_enum
      answers["DependentSSN[#{index}]"] = dependent.ssn
      answers["DependentCTCInd[#{index}]"] = dependent.qualifying_ctc ? 1 : 0
    end
    answers
  end

  def bool_checkbox(value)
    value ? "1" : "Off"
  end
end