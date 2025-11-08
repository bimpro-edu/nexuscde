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

class CreateBimSectionConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_section_configs do |t|
      t.references :ifc_model, null: false, foreign_key: { to_table: :bim_ifc_models, on_delete: :cascade }
      t.references :user, foreign_key: { to_table: :users, on_delete: :set_null }

      t.string :name, null: false, limit: 255
      t.string :description, limit: 1000

      # Section boxes (6-plane clipping boxes)
      # Structure: [{ id, min: [x,y,z], max: [x,y,z], visible, color }]
      t.jsonb :section_boxes, null: false, default: []

      # Section planes (custom cut planes)
      # Structure: [{ id, pos: [x,y,z], dir: [x,y,z], visible, color }]
      t.jsonb :section_planes, null: false, default: []

      # Configuration options
      t.boolean :show_edges, default: true
      t.boolean :fill_sections, default: false
      t.string :edge_color, limit: 7, default: '#000000'
      t.string :fill_color, limit: 7, default: '#CCCCCC'

      t.timestamps null: false
    end

    # Indexes
    add_index :bim_section_configs, :ifc_model_id, name: 'index_section_configs_on_model'
    add_index :bim_section_configs, :user_id, name: 'index_section_configs_on_user'
    add_index :bim_section_configs, [:ifc_model_id, :name], name: 'index_section_configs_on_model_and_name', unique: true

    # GIN indexes for JSONB arrays
    add_index :bim_section_configs, :section_boxes, using: :gin, name: 'index_section_configs_on_boxes'
    add_index :bim_section_configs, :section_planes, using: :gin, name: 'index_section_configs_on_planes'
  end
end
