class Course < ActiveRecord::Base
  belongs_to  :department
  has_many    :sections, dependent: :destroy
  validates   :number, uniqueness: { scope: :department_id }
  default_scope { order(number: :asc) }

  def self.get code, number
    joins(:department).where("departments.code = ? AND number = ?", code, number).first
  end

  def self.search params
    # query = <<-SQL
    #   SELECT * FROM (
    #     SELECT DISTINCT
    #       courses.*,
    #       to_tsvector(departments.name) ||
    #       to_tsvector(departments.code) ||
    #       to_tsvector(to_char(courses.number, '9999')) ||
    #       to_tsvector(courses.name) ||
    #       to_tsvector(coalesce((string_agg(array_to_string(sections.instructors, ' '), ' ')), ''))
    #     AS document FROM courses
    #     JOIN sections on sections.course_id = courses.id
    #     JOIN departments on courses.department_id = departments.id
    #     GROUP BY courses.id, sections.id, departments.id
    #   ) c_search
    #   WHERE c_search.document @@ to_tsquery('#{search_params}')
    #   ORDER BY ts_rank(c_search.document, to_tsquery('#{search_params}')) DESC
    #   LIMIT 25;
    # SQL

    search_params = params.join(' & ')

    selected = <<-SQL
        courses.*,
        to_tsvector(departments.name) ||
        to_tsvector(departments.code) ||
        to_tsvector(to_char(courses.number, '9999')) ||
        to_tsvector(courses.name) ||
        to_tsvector(coalesce((string_agg(array_to_string(sections.instructors, ' '), ' ')), ''))
      AS document 
    SQL
    subquery = self.reorder('')
                   .joins(:sections)
                   .joins(:department)
                   .group(:"courses.id", :"sections.id", :"departments.id")
                   .select(selected)
                   .to_sql

    self
        .distinct(false)
        .reorder('')
        .from(Arel.sql("(#{subquery}) c_search"))
        .where("c_search.document @@ to_tsquery('#{search_params}')")
        .order("ts_rank(c_search.document, to_tsquery('#{search_params}')) DESC")
        .limit(25)
  end

  def credits
    min_credits == max_credits ? "#{min_credits}" : "#{min_credits}-#{max_credits}"
  end
end
