module RelationshipsHelper
  # provides a list of relationship options for dependents, and pushes the client's provided free-form answer
  # to the list if necessary.
  def dependent_relationship_options(current_relationship: nil)
    relationships_hash = Hash[sorted_relationships]
    options = relationships_hash.map { |k, v| [v, k] }
    if current_relationship.present?
      key = relationships_hash[current_relationship.to_sym]
      options.push(["#{I18n.t("general.dependent_relationships.11_other")}: #{current_relationship}", current_relationship]) unless key.present?
    end
    options
  end

  def translated_relationship(relationship)
    Hash[sorted_relationships][relationship&.to_sym] || relationship
  end

  private

  def sorted_relationships
    I18n.t("general.dependent_relationships").map { |k, v| [k.to_s.sub(/^\d+_/, '').to_sym, v] }
  end
end
