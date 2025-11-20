ActiveAdmin.register Rumor do
  permit_params :content, :status, :danger_level, :sentiment

  scope :all
  scope :high_danger
  scope :pending

  index do
    selectable_column
    id_column
    column :user
    column :country
    column :content do |r|
      truncate(r.content, length: 50)
    end
    column :danger_level do |r|
      color = case r.danger_level
              when 'High' then :red
              when 'Medium' then :orange
              else :green
              end
      status_tag r.danger_level, class: "status_tag #{color}"
    end
    column :sentiment
    actions
  end

  show do
    attributes_table do
      row :user
      row :country
      row :content
      row :danger_level
      row :sentiment
      row :ai_summary
      row :raw_ai_response do |r|
        tag.pre JSON.pretty_generate(r.raw_ai_response) if r.raw_ai_response
      end
    end
  end
end