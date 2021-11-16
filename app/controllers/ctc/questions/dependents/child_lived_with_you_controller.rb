module Ctc
  module Questions
    module Dependents
      class ChildLivedWithYouController < BaseDependentController
        include AuthenticatedCtcClientConcern
        layout "yes_no_question"

        def self.show?(dependent)
          return false unless dependent&.relationship

          dependent.qualifying_child_relationship? && dependent.yr_2020_meets_qc_age_condition? && dependent.meets_qc_misc_conditions? && !dependent.yr_2020_born_in_final_6_months?
        end

        def method_name
          'lived_with_more_than_six_months'
        end

        private

        def illustration_path
          "dependents_home.svg"
        end
      end
    end
  end
end
