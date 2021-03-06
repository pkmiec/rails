require 'ostruct'

module DeveloperProjectsAssociationExtension
  def find_most_recent
    find(:first, :order => "id DESC")
  end
end

module DeveloperProjectsAssociationExtension2
  def find_least_recent
    find(:first, :order => "id ASC")
  end
end

class Developer < ActiveRecord::Base
  has_and_belongs_to_many :projects do
    def find_most_recent
      find(:first, :order => "id DESC")
    end
  end

  has_and_belongs_to_many :projects_extended_by_name,
      :class_name => "Project",
      :join_table => "developers_projects",
      :association_foreign_key => "project_id",
      :extend => DeveloperProjectsAssociationExtension

  has_and_belongs_to_many :projects_extended_by_name_twice,
      :class_name => "Project",
      :join_table => "developers_projects",
      :association_foreign_key => "project_id",
      :extend => [DeveloperProjectsAssociationExtension, DeveloperProjectsAssociationExtension2]

  has_and_belongs_to_many :projects_extended_by_name_and_block,
      :class_name => "Project",
      :join_table => "developers_projects",
      :association_foreign_key => "project_id",
      :extend => DeveloperProjectsAssociationExtension do
        def find_least_recent
          find(:first, :order => "id ASC")
        end
      end

  has_and_belongs_to_many :special_projects, :join_table => 'developers_projects', :association_foreign_key => 'project_id'

  has_many :audit_logs

  scope :jamises, :conditions => {:name => 'Jamis'}

  validates_inclusion_of :salary, :in => 50000..200000
  validates_length_of    :name, :within => 3..20

  before_create do |developer|
    developer.audit_logs.build :message => "Computer created"
  end

  def log=(message)
    audit_logs.build :message => message
  end

  def self.all_johns
    self.with_exclusive_scope :find => where(:name => 'John') do
      self.all
    end
  end
end

class AuditLog < ActiveRecord::Base
  belongs_to :developer, :validate => true
  belongs_to :unvalidated_developer, :class_name => 'Developer'
end

DeveloperSalary = Struct.new(:amount)
class DeveloperWithAggregate < ActiveRecord::Base
  self.table_name = 'developers'
  composed_of :salary, :class_name => 'DeveloperSalary', :mapping => [%w(salary amount)]
end

class DeveloperWithBeforeDestroyRaise < ActiveRecord::Base
  self.table_name = 'developers'
  has_and_belongs_to_many :projects, :join_table => 'developers_projects', :foreign_key => 'developer_id'
  before_destroy :raise_if_projects_empty!

  def raise_if_projects_empty!
    raise if projects.empty?
  end
end

class DeveloperOrderedBySalary < ActiveRecord::Base
  self.table_name = 'developers'
  default_scope :order => 'salary DESC'

  scope :by_name, order('name DESC')

  def self.all_ordered_by_name
    with_scope(:find => { :order => 'name DESC' }) do
      find(:all)
    end
  end
end

class DeveloperCalledDavid < ActiveRecord::Base
  self.table_name = 'developers'
  default_scope where("name = 'David'")
end

class LazyLambdaDeveloperCalledDavid < ActiveRecord::Base
  self.table_name = 'developers'
  default_scope lambda { where(:name => 'David') }
end

class LazyBlockDeveloperCalledDavid < ActiveRecord::Base
  self.table_name = 'developers'
  default_scope { where(:name => 'David') }
end

class CallableDeveloperCalledDavid < ActiveRecord::Base
  self.table_name = 'developers'
  default_scope OpenStruct.new(:call => where(:name => 'David'))
end

class ClassMethodDeveloperCalledDavid < ActiveRecord::Base
  self.table_name = 'developers'

  def self.default_scope
    where(:name => 'David')
  end
end

class DeveloperCalledJamis < ActiveRecord::Base
  self.table_name = 'developers'
  default_scope where(:name => 'Jamis')
  scope :poor, where('salary < 150000')
end

class PoorDeveloperCalledJamis < ActiveRecord::Base
  self.table_name = 'developers'
  default_scope where(:name => 'Jamis', :salary => 50000)
end

class InheritedPoorDeveloperCalledJamis < DeveloperCalledJamis
  self.table_name = 'developers'

  ActiveSupport::Deprecation.silence do
    default_scope where(:salary => 50000)
  end
end

class MultiplePoorDeveloperCalledJamis < ActiveRecord::Base
  self.table_name = 'developers'
  default_scope where(:name => 'Jamis')

  ActiveSupport::Deprecation.silence do
    default_scope where(:salary => 50000)
  end
end
