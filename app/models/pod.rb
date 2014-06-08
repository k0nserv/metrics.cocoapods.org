require 'lib/pod_metrics'
require File.expand_path '../version', __FILE__

# Only for reading purposes.
#
class Pod < Sequel::Model(:pods)
  # Currently adds:
  #   * Pod#github_metrics (one_to_one)
  #   * Pod.with_github_metrics
  #
  include PodMetrics

  one_to_many :versions

  plugin :timestamps

  # E.g. Pod.oldest(2)
  #
  def self.oldest(amount = 100)
    order(:updated_at).limit(amount)
  end

  def self.without_github_metrics
    with_github_metrics.where(:pod_id => nil)
  end

  def self.with_old_github_metrics
    with_github_metrics.where('github_metrics.updated_at < ?', Date.today - 3)
  end

  def specification_json
    version = versions.last
    commit = version.commits.last if version
    commit.specification_data if commit
  end

  def specification_data
    JSON.parse(specification_json || '{}')
  end

  def github_url
    data = specification_data
    source = data['source'] || {}
    source['git']
  end
end
