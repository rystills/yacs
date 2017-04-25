class Course < ActiveRecord::Base
  belongs_to :department
  has_many   :sections, dependent: :destroy
  validates  :number, presence: true, uniqueness: { scope: :department_id }
  default_scope { order(number: :asc) }

  def self.get code, number
    joins(:department).where("departments.code = ? AND number = ?", code, number).first
  end

  def self.search params
    params.map! {|p| p+"*"} 
        courses = Sunspot.search(Course) do 
        fulltext params 
    end.results
    courses = find_by_sql(query).uniq
    ActiveRecord::Associations::Preloader.new.preload(courses, :sections)
    courses
  end

  def credits
    min_credits == max_credits ? "#{min_credits}" : "#{min_credits}-#{max_credits}"
  end
end
