# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Bim
  # Section cut configurations for IFC models
  # Stores section boxes and planes for model sectioning
  class SectionConfig < ApplicationRecord
    self.table_name = 'bim_section_configs'

    belongs_to :ifc_model, class_name: 'Bim::IfcModels::IfcModel'
    belongs_to :user, optional: true

    validates :name, presence: true, length: { maximum: 255 }
    validates :name, uniqueness: { scope: :ifc_model_id }
    validates :section_boxes, presence: true
    validates :section_planes, presence: true

    scope :for_model, ->(model_id) { where(ifc_model_id: model_id) }
    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :recent, -> { order(created_at: :desc) }

    # Add a section box
    def add_box(box_config)
      boxes = section_boxes || []
      boxes << box_config.merge(id: SecureRandom.uuid)
      update(section_boxes: boxes)
      boxes.last
    end

    # Add a section plane
    def add_plane(plane_config)
      planes = section_planes || []
      planes << plane_config.merge(id: SecureRandom.uuid)
      update(section_planes: planes)
      planes.last
    end

    # Remove a section box by ID
    def remove_box(box_id)
      boxes = (section_boxes || []).reject { |b| b['id'] == box_id }
      update(section_boxes: boxes)
    end

    # Remove a section plane by ID
    def remove_plane(plane_id)
      planes = (section_planes || []).reject { |p| p['id'] == plane_id }
      update(section_planes: planes)
    end

    # Count total sections
    def section_count
      (section_boxes&.size || 0) + (section_planes&.size || 0)
    end

    # Check if has any sections
    def has_sections?
      section_count > 0
    end

    # Export configuration for frontend
    def to_config
      {
        id: id,
        name: name,
        description: description,
        section_boxes: section_boxes || [],
        section_planes: section_planes || [],
        show_edges: show_edges,
        fill_sections: fill_sections,
        edge_color: edge_color,
        fill_color: fill_color
      }
    end
  end
end
