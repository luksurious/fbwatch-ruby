class ResourceGroup < ActiveRecord::Base
  has_and_belongs_to_many :resources, -> { order('active DESC, last_synced IS NULL, last_synced DESC, created_at ASC') }

  def currently_syncing?
    Tasks::SyncTask.get_active_for(resource_group: self).count > 0
  end
end