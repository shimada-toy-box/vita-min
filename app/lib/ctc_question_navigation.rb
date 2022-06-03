class CtcQuestionNavigation
  include ControllerNavigation

  FLOW = [
    # Basic info
    Ctc::Questions::OverviewController,
    Ctc::Questions::MainHomeController,
    Ctc::Questions::FilingStatusController, # At this point we create the intake, client, and tax return
    Ctc::Questions::IncomeController,
    Ctc::Questions::FileFullReturnController,
    Ctc::Questions::RestrictionsController,

    # Eligibility
    Ctc::Questions::AlreadyFiledController,
    Ctc::Questions::LifeSituationsController,

    # Consent/Contact
    Ctc::Questions::LegalConsentController,
    Ctc::Questions::FiledPriorTaxYearController,
    Ctc::Questions::PriorTaxYearAgiController,
    Ctc::Questions::ContactPreferenceController,
    Ctc::Questions::CellPhoneNumberController,
    Ctc::Questions::EmailAddressController,
    Ctc::Questions::EmailVerificationController,  # At this verification point we sign in the client
    Ctc::Questions::PhoneVerificationController,  # Same sign in behavior as previous controller, but verified through SMS instead of email

    # Spouse Info
    Ctc::Questions::SpouseInfoController, # This and all later controllers require the client to be signed in
    Ctc::Questions::SpouseFiledPriorTaxYearController,
    Ctc::Questions::SpousePriorTaxYearAgiController,
    Ctc::Questions::SpouseReviewController,

    # Dependents Intro
    Ctc::Questions::HadDependentsController,

    # Looping Dependents Questions
    Ctc::Questions::Dependents::InfoController,
    Ctc::Questions::Dependents::ChildQualifiersController,
    Ctc::Questions::Dependents::ChildExpensesController,
    Ctc::Questions::Dependents::ChildResidenceController,
    Ctc::Questions::Dependents::ChildResidenceExceptionsController,
    Ctc::Questions::Dependents::ChildCanBeClaimedByOtherController,
    Ctc::Questions::Dependents::ChildClaimAnywayController,
    Ctc::Questions::Dependents::RelativeMemberOfHouseholdController,
    Ctc::Questions::Dependents::RelativeFinancialSupportController,
    Ctc::Questions::Dependents::RelativeQualifiersController,
    Ctc::Questions::Dependents::DoesNotQualifyCtcController,

    # Dependents Summary
    Ctc::Questions::ConfirmDependentsController,
    Ctc::Questions::HeadOfHouseholdController, # only reached through link on ConfirmDependentsController#edit

    # No Dependents
    Ctc::Questions::NoDependentsController,
    Ctc::Questions::NoDependentsAdvanceCtcPaymentsController,

    # RRC
    # => Adv. CTC
    Ctc::Questions::AdvanceCtcController,
    Ctc::Questions::AdvanceCtcAmountController,
    Ctc::Questions::AdvanceCtcClaimedController,
    Ctc::Questions::AdvanceCtcReceivedController,

    # => EIP
    Ctc::Questions::StimulusPaymentsController,
    Ctc::Questions::StimulusThreeController,
    Ctc::Questions::StimulusReceivedController,
    Ctc::Questions::StimulusOwedController,

    # Bank and mailing info
    Ctc::Questions::RefundPaymentController,

    # DEPRECATED - remove soon
    Ctc::Questions::DirectDepositController,
    Ctc::Questions::RoutingNumberController,
    Ctc::Questions::AccountNumberController,

    Ctc::Questions::BankAccountController,
    Ctc::Questions::ConfirmBankAccountController,
    Ctc::Questions::MailingAddressController,
    Ctc::Questions::ConfirmMailingAddressController,

    # Review
    Ctc::Questions::IpPinController,
    Ctc::Questions::IpPinEntryController,
    Ctc::Questions::ConfirmInformationController,
    Ctc::Questions::ConfirmPaymentController,
    Ctc::Questions::DriversLicenseController,
    Ctc::Questions::SpouseDriversLicenseController,
    Ctc::Questions::ConfirmLegalController, # sets completed_at, after which a client will no longer be able to make changes in the questions flow.
  ].freeze
end
