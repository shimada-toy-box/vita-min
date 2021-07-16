module Ctc
  module Questions
    class ConfirmMailingAddressController < QuestionsController
      include AuthenticatedCtcClientConcern
      include AnonymousIntakeConcern

      layout "intake"

      private

      def form_class
        NullForm
      end

      def illustration_path; end
    end
  end
end