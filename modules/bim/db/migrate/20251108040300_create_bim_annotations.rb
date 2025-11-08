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

class CreateBimAnnotations < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_annotations do |t|
      t.references :ifc_model, null: false, foreign_key: { to_table: :bim_ifc_models, on_delete: :cascade }
      t.references :user, foreign_key: { to_table: :users, on_delete: :set_null }

      # Annotation type
      t.string :annotation_type, null: false, limit: 50
      # Types: 'label', 'dimension', 'sketch', 'symbol', 'redline'

      # 3D position (anchor point)
      t.jsonb :position, null: false, default: [0, 0, 0] # [x, y, z]

      # Content
      t.text :content

      # Style properties (color, font, size, etc.)
      # Structure: { color, fontSize, fontFamily, backgroundColor, borderColor, etc. }
      t.jsonb :style, default: {}

      # Geometry data (for sketches and symbols)
      # Structure: { path, points, shape, size, etc. }
      t.jsonb :geometry, default: {}

      # Display properties
      t.boolean :visible, default: true
      t.integer :z_index, default: 0

      # Optional association with BCF issue
      t.integer :bcf_issue_id

      t.timestamps null: false
    end

    # Indexes
    add_index :bim_annotations, :ifc_model_id, name: 'index_annotations_on_model'
    add_index :bim_annotations, :user_id, name: 'index_annotations_on_user'
    add_index :bim_annotations, :annotation_type, name: 'index_annotations_on_type'
    add_index :bim_annotations, [:ifc_model_id, :annotation_type], name: 'index_annotations_on_model_and_type'
    add_index :bim_annotations, :visible, name: 'index_annotations_on_visible'
    add_index :bim_annotations, :bcf_issue_id, name: 'index_annotations_on_bcf_issue'

    # GIN indexes for JSONB
    add_index :bim_annotations, :style, using: :gin, name: 'index_annotations_on_style'
    add_index :bim_annotations, :geometry, using: :gin, name: 'index_annotations_on_geometry'

    # Check constraints
    add_check_constraint :bim_annotations,
                         "annotation_type IN ('label', 'dimension', 'sketch', 'symbol', 'redline')",
                         name: 'check_annotation_type'
  end
end
