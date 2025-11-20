ActiveAdmin.register Petition do
  permit_params :topic, :raw_input, :final_content, :status

  index do
    selectable_column
    id_column
    column :topic
    column :status do |petition|
      status_tag petition.status
    end
    column :created_at
    actions
  end

  filter :topic
  filter :status
  filter :created_at

  show do
    attributes_table do
      row :topic
      row :status
      row :raw_input
      row :final_content do |p|
        simple_format p.final_content # Renders newlines properly
      end
      row :created_at
    end
  end
end