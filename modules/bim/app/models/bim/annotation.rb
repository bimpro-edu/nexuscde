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
  # Annotations for IFC models
  # Stores labels, dimensions, sketches, symbols, and redlines
  class Annotation < ApplicationRecord
    self.table_name = 'bim_annotations'

    ANNOTATION_TYPES = %w[label dimension sketch symbol redline].freeze

    belongs_to :ifc_model, class_name: 'Bim::IfcModels::IfcModel'
    belongs_to :user, optional: true

    validates :annotation_type, presence: true, inclusion: { in: ANNOTATION_TYPES }
    validates :position, presence: true

    scope :for_model, ->(model_id) { where(ifc_model_id: model_id) }
    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :by_type, ->(type) { where(annotation_type: type) }
    scope :visible_only, -> { where(visible: true) }
    scope :recent, -> { order(created_at: :desc) }
    scope :ordered_by_z, -> { order(:z_index, :created_at) }

    # Type check methods
    def label?
      annotation_type == 'label'
    end

    def dimension?
      annotation_type == 'dimension'
    end

    def sketch?
      annotation_type == 'sketch'
    end

    def symbol?
      annotation_type == 'symbol'
    end

    def redline?
      annotation_type == 'redline'
    end

    # Get position as array
    def position_array
      position.is_a?(Array) ? position : [0, 0, 0]
    end

    # Export for frontend
    def to_annotation_data
      {
        id: id,
        type: annotation_type,
        position: position_array,
        content: content,
        style: style || {},
        geometry: geometry || {},
        visible: visible,
        z_index: z_index,
        bcf_issue_id: bcf_issue_id,
        created_at: created_at
      }
    end
  end
end
