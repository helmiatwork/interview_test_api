module CachedHelper
  # By keeping expires_in (even with a default),
  # we ensure that cache entries do not stay indefinitely
  # and are cleared after a reasonable amount of time.
  # For large projects, you may consider using custom namespaces.
  def write_cache(object)
    # Define a namespace based on the object's class name to avoid clashes across models
    namespace = object.class.name.underscore

    # Get all the :belongs_to associations for the object's class
    belongs_to_associations = object.class.reflect_on_all_associations(:belongs_to).map(&:name)

    # Cache each of the associated objects as well
    belongs_to_associations.each do |association|
      associated_object = object.send(association)  # Access the associated object
      if associated_object
        # Recursively cache the associated object using its ID and namespace
        write_cache(associated_object)
      end
    end

    # Cache the object itself using only its ID as the cache key and the namespace
    Rails.cache.write(
      object.id,
      object,
      namespace: object.class.name.underscore
    )
  end


  def delete_cache(object)
    Rails.cache.delete(
      object.id,
      namespace: object.class.name.underscore
    )
  end

  def fetch_cache(id, klass:)
    # Get all associations of the provided class
    has_many_associations = klass.reflect_on_all_associations(:has_many).map(&:name)
    belongs_to_associations = klass.reflect_on_all_associations(:belongs_to).map(&:name)

    # Use the provided class for the namespace
    Rails.cache.fetch(id.to_s, namespace: klass.name.underscore) do
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
