require 'digest/md5'

class SharedResourcesMetric < MetricBase
  def initialize(resource_group)
    @resource_group = resource_group

    super(resource_group: @resource_group, class: self.class)
  end

  def resource_combinations
    @resource_group.resources.to_a.combination(2).to_a
  end

  def analyze
    resource_combinations.each do |combination|

      # calc shared resources

      # faster locally, but slower online
      # NOTE: DO NOT add .count to the query like that. It would be really slow!
      # If a direct count is necessary remove the .distinct method and move to .select('DISTINCT resources.id').count
      # Only other acceptable version is #.count(:id, distinct: true), which is now deprecated though
      # result = Resource.distinct.select(resources: :id).joins('INNER JOIN feeds feed1 ON feed1.from_id = resources.id OR feed1.to_id = resources.id',
      #  'INNER JOIN feeds feed2 ON feed2.from_id = resources.id OR feed2.to_id = resources.id').
      #  where(feed1: {resource_id: }, feed2: {resource_id: 257})

      result = Resource.find_by_sql ["SELECT A.id FROM (
          SELECT DISTINCT resources.* 
          FROM resources 
            INNER JOIN feeds 
              ON feeds.from_id = resources.id 
                OR feeds.to_id = resources.id 
          WHERE feeds.resource_id = ?) 
        A INNER JOIN (
          SELECT DISTINCT resources.* 
          FROM resources 
            INNER JOIN feeds 
              ON feeds.from_id = resources.id 
                OR feeds.to_id = resources.id 
          WHERE feeds.resource_id = ?) 
        B ON A.id = B.id", combination[0].id, combination[1].id]

      shared_resources = result.to_json

      # save metric
      token = Digest::MD5.hexdigest(combination.map{ |res| "#{res.id}.#{res.username}"  }.join('_'))
      make_group_metric_model(name: 'shared_resources', token: token, value: shared_resources, resources: combination)

    end

    get_metrics
  end

  def render(name, value, resources)

  end
end