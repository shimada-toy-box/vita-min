class Ctc::Portal::PortalController < ApplicationController
  include AuthenticatedClientConcern
  layout "portal"

  def home
    if current_client.efile_submissions.any?
      submission = current_client.efile_submissions.last
      latest_transition = submission.last_client_accessible_transition
      @status = latest_transition.present? ? latest_transition.to_state : EfileSubmissionStateMachine.initial_state
      @exposed_error = latest_transition.present? ? latest_transition.client_facing_errors.first : nil
      @current_step = nil
    else
      @status = "intake_in_progress"
      @exposed_error = nil
      @current_step = current_client.intake.current_step
    end
  end

  private

  def service_type
    :ctc
  end

  def wrapping_layout
    service_type
  end
end
