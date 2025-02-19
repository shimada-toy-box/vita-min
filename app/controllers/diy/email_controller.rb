module Diy
  class EmailController < BaseController
    def edit
      @diy_intake = DiyIntake.new
    end

    def update
      @diy_intake = DiyIntake.new(create_params)

      return render :edit unless @diy_intake.save

      session[:diy_intake_id] = @diy_intake.id
      redirect_to(diy_continue_to_fsa_path)
    end

    private

    def create_params
      params.require(:diy_intake).permit(:email_address, :email_address_confirmation).merge(
        source: source,
        referrer: referrer,
        visitor_id: visitor_id,
        locale: I18n.locale
      )
    end
  end
end
