module CachedHelper
  # By keeping expires_in (even with a default),
  # we ensure that cache entries do not stay indefinitely
  # and are cleared after a reasonable amount of time.
  # For large projects, you may consider using custom namespaces.
  require 'set'

  def write_cache(object, cached = Set.new)
    namespace = object.class.name.underscore
    cache_key = object.id

    # Skip if this object is already cached in this cycle
    return if cached.include?(cache_key)

    # Mark this object as cached
    cached.add(cache_key)

    # Get all associations
    belongs_to_associations = object.class.reflect_on_all_associations(:belongs_to).map(&:name)
    has_many_associations = object.class.reflect_on_all_associations(:has_many).map(&:name)

    # Combine associations for eager loading
    includes_associations = belongs_to_associations + has_many_associations

    # Reload with includes to prevent N+1
    if includes_associations.present?
      object = object.class.includes(includes_associations).find(object.id)
    end

    # Recursively cache belongs_to associations
    belongs_to_associations.each do |association|
      associated_object = object.public_send(association)
      write_cache(associated_object, cached) if associated_object
    end

    # Recursively cache has_many associations
    has_many_associations.each do |association|
      associated_objects = object.public_send(association)
      next unless associated_objects.present?

      associated_objects.each do |assoc_obj|
        write_cache(assoc_obj, cached)
      end
    end

    # Cache the object itself
    Rails.cache.write(
      object.id,
      object,
      namespace: namespace
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
