module CachedHelper
  # By keeping expires_in (even with a default),
  # we ensure that cache entries do not stay indefinitely
  # and are cleared after a reasonable amount of time.
  # For large projects, you may consider using custom namespaces.
  def write_cache(object, expires_in: 60.minutes)
    Rails.cache.write(
      object.id,
      object,
      namespace: object.class.name.underscore,
      expires_in: expires_in
    )
  end

  def delete_cache(object)
    Rails.cache.delete(
      object.id,
      namespace: object.class.name.underscore
    )
  end

  def fetch_cache(id, klass:, expires_in: 60.minutes)
    # Get all associations of the provided class
    has_many_associations = klass.reflect_on_all_associations(:has_many).map(&:name)
    belongs_to_associations = klass.reflect_on_all_associations(:belongs_to).map(&:name)

    # Use the provided class for the namespace
    Rails.cache.fetch(id.to_s, namespace: klass.name.underscore, expires_in: expires_in) do
      # Preload both `has_many` and `belongs_to` associations (if they exist)
      query = klass

      # Include `has_many` associations if present
      query = query.includes(has_many_associations) if has_many_associations.present?

      # Include `belongs_to` associations if present
      query = query.includes(belongs_to_associations) if belongs_to_associations.present?

      # Find the object by ID with the appropriate includes
      query.find_by(id: id)
    end
  end
end
