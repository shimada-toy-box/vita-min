# Be sure to restart your server when you modify this file.

# Configure parameters to be filtered from the log file. Use this to limit dissemination of
# sensitive information. See the ActiveSupport::ParameterFilter documentation for supported
# notations and behaviors.
Rails.application.config.filter_parameters += [
  :password,
  :name,
  :primary_first_name,
  :primary_last_name,
  :spouse_first_name,
  :spouse_last_name,
  :email,
  :email_address,
  :email_address_confirmation,
  :spouse_email_address,
  :phone_number,
  :sms_phone_number,
  :additional_info,
  :filename,
  :bank_name,
  :bank_routing_number,
  :bank_routing_number_confirmation,
  :routing_number,
  :routing_number_confirmation,
  :bank_account_number,
  :bank_account_number_confirmation,
  :account_number,
  :account_number_confirmation,
  :primary_last_four_ssn,
  :spouse_last_four_ssn,
  :last_four_or_client_id,
  :primary_ssn,
  :spouse_ssn,
  :ssn,
  :primary_ip_pin,
  :spouse_ip_pin,
  :ip_pin,
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp
]
