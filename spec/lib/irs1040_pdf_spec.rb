require "rails_helper"

RSpec.describe Irs1040Pdf do
  include PdfSpecHelper

  let(:pdf) { described_class.new(submission) }
  # Locked to 2021 because the resulting PDF matches 2021 revenue procedure needs.
  let(:tax_year) { 2021 }
  let(:submission) { create :efile_submission, :ctc, tax_year: tax_year }

  describe "initialization" do
    context "when there is a verified address for the submission" do
      it "uses the verified address" do
        expect(pdf.address).to be_an_instance_of Address
        expect(pdf.address).to be_persisted
      end
    end

    context "when there is no verified address for the submission" do
      before do
        submission.verified_address.destroy!
      end

      it "falls back to using the intake address" do
        expect(pdf.address).to be_an_instance_of Address
        expect(pdf.address).not_to be_persisted
      end
    end
  end

  describe "#output_file" do
    context "with an empty submission record" do

      # "clear out" submission so we can see the empty state of the PDF
      before do
        submission.intake.update(email_address: nil, phone_number: nil, sms_phone_number: nil, primary_first_name: "", primary_last_name: "", primary_ssn: "", claim_owed_stimulus_money: "no", zip_code: "", city: "", state: "", street_address: "", street_address2: "" )
        submission.intake.bank_account.destroy!
        submission.verified_address.destroy!
        submission.intake.dependents.destroy_all
        submission.tax_return.update(filing_status: nil)
        submission.reload
      end

      it "returns a pdf with default fields and values" do
        output_file = pdf.output_file
        result = non_preparer_fields(output_file.path)
        expect(result).to match({
                                  "AdditionalChildTaxCreditAmt28" => "0",
                                  "AdditionalTaxAmt17" => nil,
                                  "AddressLine1Txt" => "",
                                  "AdjustedGrossIncomeAmt11" => nil,
                                  "AppliedToEsTaxAmt36" => nil,
                                  "BankAccountTypeCd" => nil,
                                  "CDCODCAmt19" => nil,
                                  "CapitalGainLossAmt7" => nil,
                                  "CharitableContributionAmt12b" => nil,
                                  "CityNm" => "",
                                  "DependentCTCInd[0]" => "Off",
                                  "DependentCTCInd[1]" => "Off",
                                  "DependentCTCInd[2]" => "Off",
                                  "DependentCTCInd[3]" => "Off",
                                  "DependentOTCInd[0]" => "Off",
                                  "DependentOTCInd[1]" => "Off",
                                  "DependentOTCInd[2]" => "Off",
                                  "DependentOTCInd[3]" => "Off",
                                  "DependentLegalNm[0]" => nil,
                                  "DependentLegalNm[1]" => nil,
                                  "DependentLegalNm[2]" => nil,
                                  "DependentLegalNm[3]" => nil,
                                  "DependentRelationship[0]" => nil,
                                  "DependentRelationship[1]" => nil,
                                  "DependentRelationship[2]" => nil,
                                  "DependentRelationship[3]" => nil,
                                  "DependentSSN[0]" => nil,
                                  "DependentSSN[1]" => nil,
                                  "DependentSSN[2]" => nil,
                                  "DependentSSN[3]" => nil,
                                  "DepositorAccountNum35d" => nil,
                                  "EarnedIncomeCreditAmt27a" => nil,
                                  "EmailAddress" => "",
                                  "EsPenaltyAmt38" => nil,
                                  "EstimatedTaxPaymentsAmt26" => nil,
                                  "FilingStatus" => "",
                                  "Form1099WithheldTaxAmt25b" => nil,
                                  "Form8814Ind7" => "Off",
                                  "FormW2WithheldTaxAmt25a" => nil,
                                  "Has4972Ind16_2" => "Off",
                                  "Has8814Ind16_1" => "Off",
                                  "HasOtherFormInd16_3" => "Off",
                                  "IRADistributionsAmt4a" => nil,
                                  "MustItemizeInd" => "Off",
                                  "NontaxCombatPay27a" => nil,
                                  "OrdinaryDividendsAmt3b" => nil,
                                  "OtherFormName16_3" => nil,
                                  "OverpaidAmt34" => "0",
                                  "OwedAmt37" => nil,
                                  "PensionsAnnuitiesAmt5a" => nil,
                                  "PhoneNumber" => "",
                                  "Primary65OrOlderInd" => "Off",
                                  "PrimaryBlindInd" => "Off",
                                  "PrimaryClaimAsDependentInd" => "Off",
                                  "PrimaryFirstNm" => "",
                                  "PrimaryIPPIN" => "",
                                  "PrimaryLastNm" => "",
                                  "PrimarySSN" => "",
                                  "PrimarySignature" => "",
                                  "PrimaryOccupation" => nil,
                                  "PrimarySignatureDate" => "",
                                  "PriorYrIncome27c" => nil,
                                  "RecoveryRebateCreditAmt30" => "0",
                                  "VirtualCurAcquiredDurTYInd" => "false",
                                  "QualifiedBusinessIncomeDedAmt13" => nil,
                                  "QualifiedDividendsAmt3a" => nil,
                                  "QualifiedFosterOrHomelessYouth" => "Off",
                                  "QualifyingPersonName" => nil,
                                  "RefundAmt35" => "0",
                                  "RefundableAmerOppCreditAmt29" => nil,
                                  "RefundableCreditsAmt32" => "0",
                                  "RoutingTransitNum35b" => nil,
                                  "SocSecBenAmt6a" => nil,
                                  "Spouse65OrOlderInd" => "Off",
                                  "SpouseBlindInd" => "Off",
                                  "SpouseClaimAsDependentInd" => "Off",
                                  "SpouseFirstNm" => nil,
                                  "SpouseIPPIN" => nil,
                                  "SpouseLastNm" => nil,
                                  "SpouseOccupation" => nil,
                                  "SpouseSSN" => nil,
                                  "SpouseSignature" => nil,
                                  "SpouseSignatureDate" => nil,
                                  "StateAbbreviationCd" => "",
                                  "TaxAmt16" => nil,
                                  "TaxExemptInterestAmt2a" => nil,
                                  "TaxLessCreditsAmt22" => nil,
                                  "TaxWithheldOtherAmt25c" => nil,
                                  "TaxableIRAAmt4b" => nil,
                                  "TaxableIncomeAmt15" => "0",
                                  "TaxableInterestAmt2b" => nil,
                                  "TaxableSocSecAmt6b" => nil,
                                  "TotalAdditionalIncomeAmt8" => nil,
                                  "TotalAdjustmentsAmt10" => nil,
                                  "TotalAdjustmentsToIncomeAmt12c" => "",
                                  "TotalCreditsAmt21" => nil,
                                  "TotalDeductionsAmt14" => "",
                                  "TotalIncomeAmt9" => nil,
                                  "TotalItemizedOrStandardDedAmt12a" => "",
                                  "TotalNonrefundableCreditsAmt20" => nil,
                                  "TotalOtherPaymentsRfdblCrAmt31" => nil,
                                  "TotalOtherTaxesAmt23" => nil,
                                  "TotalPaymentsAmt33" => "0",
                                  "TotalTaxAmt24" => nil,
                                  "TotalTaxBeforeCrAndOthTaxesAmt18" => nil,
                                  "TotalTaxablePensionsAmt5b" => nil,
                                  "WagesSalariesAndTipsAmt1" => nil,
                                  "WithholdingTaxAmt25d" => nil,
                                  "ZipCd" => "",
                                })
      end
    end

    context "with a filled out submission record" do
      let(:claimed_rrc) { 1000 }
      let(:outstanding_ctc) { 500 }
      let(:outstanding_credits) { (claimed_rrc + outstanding_ctc).to_s }
      before do
        submission.intake.update(primary_ip_pin: "12345", primary_signature_pin_at: Date.new(2020, 1, 1), has_crypto_income: true, was_blind: "yes")

        submission.reload

        allow_any_instance_of(Efile::BenefitsEligibility).to receive(:claimed_recovery_rebate_credit).and_return claimed_rrc
        allow_any_instance_of(Efile::BenefitsEligibility).to receive(:outstanding_ctc_amount).and_return(outstanding_ctc)
        allow(submission.tax_return).to receive(:standard_deduction).and_return(999)
      end

      it "returns a filled out pdf" do
        output_file = pdf.output_file
        result = non_preparer_fields(output_file.path)
        expect(result).to match(hash_including(
                                  "FilingStatus" => "1",
                                  "PrimaryFirstNm" => submission.intake.primary_first_name,
                                  "PrimaryLastNm" => submission.intake.primary_last_name,
                                  "PrimarySSN" => submission.intake.primary_ssn,
                                  "AddressLine1Txt" => "23627 HAWKINS CREEK CT",
                                  "CityNm" => "KATY",
                                  "StateAbbreviationCd" => "TX",
                                  "ZipCd" => "77494",
                                  "VirtualCurAcquiredDurTYInd" => "true",
                                  "PrimaryBlindInd" => "1",
                                  "TotalItemizedOrStandardDedAmt12a" => "999",
                                  "TotalAdjustmentsToIncomeAmt12c" => "999",
                                  "TotalDeductionsAmt14" => "999",
                                  "TaxableIncomeAmt15" => "0",
                                  "Primary65OrOlderInd" => "Off",
                                  "RecoveryRebateCreditAmt30" => claimed_rrc.to_s,
                                  "RefundableCreditsAmt32" => outstanding_credits,
                                  "TotalPaymentsAmt33" => outstanding_credits,
                                  "OverpaidAmt34" => outstanding_credits,
                                  "RefundAmt35" => outstanding_credits,
                                  "PrimarySignature" => "#{submission.intake.primary_first_name} #{submission.intake.primary_last_name}",
                                  "PrimarySignatureDate" => "01/01/20",
                                  "PrimaryIPPIN" => "12345",
                                  "PhoneNumber" => "(415) 555-1212",
                                  "EmailAddress" => submission.intake.email_address,
                                ))
      end
    end

    context "when status is married filing jointly" do
      before do
        submission.intake.update(
          spouse_first_name: "Randall",
          spouse_last_name: "Rouse",
          spouse_signature_pin_at: Date.new(2020, 1, 5),
          spouse_ip_pin: "123456",
          spouse_ssn: "123456789",
          spouse_was_blind: "yes",
        )
        submission.tax_return.update(filing_status: "married_filing_jointly")
        submission.reload
      end

      it "includes spouse information and filing status" do
        output_file = pdf.output_file
        result = non_preparer_fields(output_file.path)
        expect(result).to match(hash_including(
                                  "Spouse65OrOlderInd" => "Off",
                                  "SpouseFirstNm" => "Randall",
                                  "SpouseLastNm" => "Rouse",
                                  "SpouseSSN" => "123456789",
                                  "SpouseSignature" => "Randall Rouse",
                                  "SpouseSignatureDate" => "01/05/20",
                                  "SpouseIPPIN" => "123456",
                                  "SpouseBlindInd" => "1",
                                ))
      end
    end

    context "with filled out qualifying dependents" do
      let(:daughter) do
        create :qualifying_child,
               first_name: "Danielle",
               last_name: "Dob",
               ssn: "123456789",
               relationship: "daughter",
               birth_date: Date.new(2015, 2, 25)
      end
      let(:son) do
        create :qualifying_child,
               first_name: "Daniel",
               last_name: "Dob",
               ssn: "123456788",
               relationship: "son",
               birth_date: Date.new(2015, 2, 26)
      end
      let(:mother) do
        create :qualifying_relative,
               first_name: "Mother",
               last_name: "Dob",
               ssn: "123455788",
               relationship: "parent",
               birth_date: Date.new(1965, 2, 26)
      end

      before do
        submission.intake.update(dependents: [daughter, son, mother])
        submission.intake.dependents.each do |dependent|
          EfileSubmissionDependent.create_qualifying_dependent(submission, dependent)
        end
      end

      it "returns correct values for dependents" do
        output_file = pdf.output_file
        result = non_preparer_fields(output_file.path)
        expect(result).to match(hash_including(
                                  "DependentLegalNm[0]" => "Danielle Dob",
                                  "DependentRelationship[0]" => "DAUGHTER",
                                  "DependentSSN[0]" => "123456789",
                                  "DependentCTCInd[0]" => "1", # checked
                                  "DependentLegalNm[1]" => "Daniel Dob",
                                  "DependentRelationship[1]" => "SON",
                                  "DependentSSN[1]" => "123456788",
                                  "DependentCTCInd[1]" => "1", # checked
                                  "DependentLegalNm[2]" => "Mother Dob",
                                  "DependentRelationship[2]" => "PARENT",
                                  "DependentSSN[2]" => "123455788",
                                  "DependentCTCInd[2]" => "0", # unchecked
                                ))
      end
    end

    context "when primary filer is older than 65" do
      before do
        submission.intake.update(primary_birth_date: Date.new(tax_year - 64, 1, 1))
        submission.reload
      end

      it "returns 1" do
        output_file = pdf.output_file
        result = non_preparer_fields(output_file.path)
        expect(result).to match(hash_including("Primary65OrOlderInd" => "1"))
      end
    end

    context "when spouse is older than 65" do
      before do
        submission.intake.update(
          spouse_birth_date: Date.new(tax_year - 64, 1, 1),
          spouse_first_name: "Randall",
          spouse_last_name: "Rouse",
          spouse_signature_pin_at: Date.new(2020, 1, 5),
          spouse_ip_pin: "123456",
          spouse_ssn: "123456789"
        )
        submission.tax_return.update(filing_status: "married_filing_jointly")
        submission.reload
      end

      it "returns 1" do
        output_file = pdf.output_file
        result = non_preparer_fields(output_file.path)
        expect(result).to match(hash_including("Spouse65OrOlderInd" => "1"))
      end
    end
  end
end
