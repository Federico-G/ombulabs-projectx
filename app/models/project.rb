class Project < ApplicationRecord
  validates :title, presence: true

  has_many :stories
  has_many :estimates, through: :stories
  has_many :users, through: :estimates

  belongs_to :parent, class_name: "Project", required: false
  has_many :projects, class_name: "Project", foreign_key: :parent_id, dependent: :destroy

  before_create :add_position

  scope :parents, -> { where(parent: nil) }
  scope :sub_projects_with_ordered_stories, ->(project_id) {
    where(parent_id: project_id)
      .includes(:stories).references(:stories)
      .order(Arel.sql("projects.position ASC, stories.position ASC NULLS FIRST"))
  }

  def best_estimate_total
    stories.includes(:estimates).sum(&:best_estimate_average)
  end

  def worst_estimate_total
    stories.includes(:estimates).sum(&:worst_estimate_average)
  end

  def real_score_total
    stories.collect(&:real_score).compact.sum
  end

  def best_estimate_sum_per_user(user)
    stories.includes(:estimates).sum { |x| x.best_estimate_for(user) }
  end

  def worst_estimate_sum_per_user(user)
    stories.includes(:estimates).sum { |x| x.worst_estimate_for(user) }
  end

  def percentage_off_estimate_total(estimate_total, real_score_total)
    if estimate_total != 0 && real_score_total != 0
      ((estimate_total - real_score_total).abs / estimate_total) * 100
    else
      0
    end
  end

  def breadcrumb
    parent.present? ? "#{parent.breadcrumb} » #{title}" : title
  end

  # returns all the sub-projects from its parent's project except self
  def siblings
    parent_id ? Project.where(parent_id: parent_id).where.not(id: id) : []
  end

  def has_parent?
    parent.present?
  end

  private

  def add_position
    return unless parent
    return if position

    last_position = parent.projects.where.not(position: nil).order(position: :asc).last&.position || 0
    self.position = last_position + 1
  end
end
