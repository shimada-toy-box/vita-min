class UserMailer < ApplicationMailer
  default from: Rails.configuration.email_from[:noreply][:gyr]

  helper :time
  def assignment_email(
    assigned_user:,
    assigning_user:,
    tax_return:,
    assigned_at:
  )
    @assigned_user = assigned_user
    @assigning_user = assigning_user
    @assigned_at = assigned_at.in_time_zone(@assigned_user.timezone)
    @client = tax_return.client
    @subject = "GetYourRefund Client ##{@client.id} Assigned to You"
    service = MultiTenantService.new(:gyr)
    attachments.inline['logo.png'] = service.email_logo

    mail(to: @assigned_user.email, subject: @subject)
  end
end
