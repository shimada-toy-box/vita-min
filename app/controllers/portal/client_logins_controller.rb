module Portal
  class ClientLoginsController < ApplicationController
    before_action :gyr_redirect_unless_open_for_logged_in_clients
    before_action :redirect_to_portal_if_client_authenticated
    before_action :validate_token, only: [:edit, :update]
    before_action :redirect_locked_clients, only: [:edit, :update]
    layout "portal"

    def new
      @form = RequestClientLoginForm.new
    end

    def create
      @form = RequestClientLoginForm.new(request_client_login_params)
      if @form.valid?
        RequestVerificationCodeForLoginJob.perform_later(
          email_address: @form.email_address,
          phone_number: @form.sms_phone_number,
          visitor_id: visitor_id,
          locale: I18n.locale,
          service_type: service_type
        )

        @verification_code_form = Portal::VerificationCodeForm.new(contact_info: @form.email_address.present? ? @form.email_address : @form.sms_phone_number)
        render :enter_verification_code
      else
        render :new
      end
    end

    def check_verification_code
      params = check_verification_code_params
      if params[:contact_info].blank?
        head :bad_request
        return
      end

      @verification_code_form = Portal::VerificationCodeForm.new(contact_info: params[:contact_info], verification_code: params[:verification_code])
      if @verification_code_form.valid?
        hashed_verification_code = VerificationCodeService.hash_verification_code_with_contact_info(params[:contact_info], params[:verification_code])

        if client_login_service.clients_for_token(hashed_verification_code).present?
          DatadogApi.increment("client_logins.verification_codes.right_code")
          redirect_to edit_portal_client_login_path(id: hashed_verification_code)
          return
        else
          @verification_code_form.errors.add(:verification_code, I18n.t("portal.client_logins.form.errors.bad_verification_code"))
          DatadogApi.increment("client_logins.verification_codes.wrong_code")

          @clients = Client.by_contact_info(email_address: params[:contact_info], phone_number: params[:contact_info])
          @clients.map(&:increment_failed_attempts)
          return if redirect_locked_clients
        end
      end

      render :enter_verification_code
    end

    def account_locked; end

    def edit
      @form = ClientLoginForm.new(possible_clients: @clients)
    end

    def update
      @form = ClientLoginForm.new(client_login_params)
      if @form.valid?
        sign_in @form.client
        @form.client.accumulate_total_session_durations
        @form.client.touch :last_seen_at
        redirect_to session.delete(:after_client_login_path) || portal_root_path
      else
        @clients.each(&:increment_failed_attempts)

        # Re-checking if account is locked after incrementing
        return if redirect_locked_clients

        render :edit
      end
    end

    private

    def request_client_login_params
      params.require(:portal_request_client_login_form).permit(:email_address, :sms_phone_number)
    end

    def client_login_params
      params.require(:portal_client_login_form).permit(:last_four_or_client_id).merge(possible_clients: @clients)
    end

    def check_verification_code_params
      params.require(:portal_verification_code_form).permit(:contact_info, :verification_code)
    end

    def validate_token
      @clients = client_login_service.clients_for_token(params[:id])
      redirect_to portal_client_logins_path unless @clients.present?
    end

    def client_login_service
      ClientLoginService.new(service_type)
    end

    def service_type
      :gyr
    end

    def redirect_locked_clients
      redirect_to account_locked_portal_client_logins_path if @clients.map(&:access_locked?).any?
    end

    def redirect_to_portal_if_client_authenticated
      redirect_to portal_root_path if current_client.present?
    end

    def gyr_redirect_unless_open_for_logged_in_clients
      return unless Routes::GyrDomain.new.matches?(request)

      redirect_to root_path unless open_for_gyr_logged_in_clients?
    end
  end
end
