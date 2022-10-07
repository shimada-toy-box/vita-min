class IrsStreetAddressTypeValidator < ActiveModel::EachValidator
  ADDRESS_REGEX = /\A[A-Za-z0-9]( ?[A-Za-z0-9\- \/])*\z/

  def validate_each(record, attr_name, value)
    unless value =~ ADDRESS_REGEX
      record.errors.add(attr_name, I18n.t("validators.irs_street_address"))
    end
  end
end
