class SyncTaskWorker < TaskWorker
  # I need :facebook => access_token
  # and    :task     => task
  def perform(options)
    koala = Koala::Facebook::API.new(options['token'])

    super(options['task']) do |task|
      task.koala = koala
    end
  end
end