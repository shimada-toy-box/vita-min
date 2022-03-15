class DependentFlowService
  attr_accessor :dependent, :controller_name, :tax_year

  def initialize(dependent, tax_year, controller_name)
    @dependent = dependent
    @controller_name = controller_name
    @tax_year = tax_year
  end

  def show?
    return false unless dependent.present?

    case controller_name.to_s
    when "Ctc::Questions::Dependents::InfoController"
      dependent.intake.had_dependents_yes?
    when "Ctc::Questions::Dependents::ChildQualifiesController"
      eligibility = child_qualification(except: [:age_test, :financial_support_test, :residence_test, :claimable_test])
      eligibility.over_qualifying_age_limit? && eligibility.qualifies?
    when "Ctc::Questions::Dependents::ChildExpensesController"
      eligibility = child_qualification(except: [:financial_support_test, :residence_test, :claimable_test])
      eligibility.qualifies?
    when "Ctc::Questions::Dependents::ChildLivedWithYouController"
      eligibility = child_qualification(except: [:residence_test, :claimable_test])
      eligibility.qualifies?
    when "Ctc::Questions::Dependents::ChildResidenceExceptionsController"
      eligibility = child_qualification(except: [:residence_test, :claimable_test])
      dependent.lived_with_more_than_six_months_no? && eligibility.qualifies?
    when "Ctc::Questions::Dependents::ChildCanBeClaimedByOtherController"
      eligibility = child_qualification(except: :claimable_test)
      eligibility.qualifies?
    when "Ctc::Questions::Dependents::ClaimChildAnywayController"
      eligibility = child_qualification(except: :claimable_test)
      dependent.cant_be_claimed_by_other_no? && eligibility.qualifies?
    else
      raise "must define show? rule for controller in DependentLogicService for #{controller_name}"
    end
  end

  def child_qualification(except: nil)
    Efile::DependentEligibility::QualifyingChild.new(dependent, tax_year, except: except)
  end
end