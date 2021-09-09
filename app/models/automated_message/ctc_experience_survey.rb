module AutomatedMessage
  class CtcExperienceSurvey
    def self.name
      'messages.surveys.ctc_experience'.freeze
    end

    def self.survey_link(client)
      ctc_rejected_status = client.intake.tax_return(2020).status == "file_rejected" ? 'TRUE' : 'FALSE'

      "https://codeforamerica.co1.qualtrics.com/jfe/form/SV_cHN2H3IWcxAEKPA?&ExternalDataReference=#{client.id}&ctcRejected=#{ctc_rejected_status}&expGroup=#{client.ctc_experience_survey_variant}"
    end

    def sms_body(*args)
      I18n.t("messages.surveys.ctc_experience.sms", *args)
    end

    def email_subject(*args)
      I18n.t("messages.surveys.ctc_experience.email.subject", *args)
    end

    def email_body(*args)
      I18n.t("messages.surveys.ctc_experience.email.body", *args)
    end
  end
end
