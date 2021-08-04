module Ctc
  module Questions
    class Filed2020YesController < QuestionsController

      layout "intake"

      private

      def form_class
        NullForm
      end

      def illustration_path
        "hand-holding-check.svg"
      end
    end
  end
end