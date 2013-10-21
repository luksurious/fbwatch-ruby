module ResourcesHelper
  def print_res_list_excl_self(collection, owner)
    collection.map do |res|
      next unless res.is_a?(Resource)
      next if res == owner

      link_to res.name, resource_details_path(res.username)
    end.compact.join(', ')
  end
end