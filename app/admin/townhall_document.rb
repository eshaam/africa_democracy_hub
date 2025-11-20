ActiveAdmin.register TownhallDocument do
  permit_params :title, :status, :ai_summary

  scope :all
  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }

  index do
    selectable_column
    id_column
    column :user
    column :title
    column :file_type
    column :status do |doc|
      color = doc.status == 'completed' ? :green : :orange
      status_tag doc.status, class: "status_tag #{color}"
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :title
      row :user
      row :status
      row :file do |doc|
        if doc.file.attached?
          link_to "📥 Download Original PDF", rails_blob_path(doc.file, disposition: "attachment")
        else
          "No file attached"
        end
      end
      row :ai_summary do |doc|
        simple_format doc.ai_summary
      end
      row :extracted_text do |doc|
        div style: "max-height: 150px; overflow-y: scroll; background: #f4f4f4; padding: 10px;" do
          doc.extracted_text
        end
      end
      row :created_at
    end
  end
end