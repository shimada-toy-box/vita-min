namespace :not_ready do
  desc "sends not ready reminder emails"
  task "remind" => :environment do
    return if Rails.configuration.offseason

    remindable_returns = TaxReturn.joins(:intake, :client).where(status: "intake_in_progress", intakes: { type: "Intake::GyrIntake" }).where('tax_returns.updated_at < ?', 3.days.ago)
    remindable_returns.find_each do |tax_return|
      NotReadyReminder.process(tax_return)
    end
  end
end