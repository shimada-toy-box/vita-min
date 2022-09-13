class Ctc::Portal::W2s::EmployeeInfoController < Ctc::Portal::BaseIntakeRevisionController
  def edit
    @form = form_class.from_w2(current_model)
    render edit_template
  end

  private

  def edit_template
    "ctc/portal/w2s/employee_info/edit"
  end

  def form_class
    Ctc::W2s::EmployeeInfoForm
  end

  def current_model
    @_current_model ||= current_intake.w2s.find(params[:id])
  end

  def next_path
    redirect_to Ctc::Portal::W2s::EmployerInfoController.to_path_helper(action: :edit, id: current_model.id)
  end
end
