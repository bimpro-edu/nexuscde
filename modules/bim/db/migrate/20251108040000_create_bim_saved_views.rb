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

class CreateBimSavedViews < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_saved_views do |t|
      t.references :ifc_model, null: false, foreign_key: { to_table: :bim_ifc_models, on_delete: :cascade }
      t.references :user, foreign_key: { to_table: :users, on_delete: :set_null }

      t.string :name, null: false, limit: 255
      t.string :description, limit: 1000

      # Camera position
      t.jsonb :camera_eye, null: false, default: [0, 0, 0] # [x, y, z]
      t.jsonb :camera_look, null: false, default: [0, 0, 0] # [x, y, z]
      t.jsonb :camera_up, null: false, default: [0, 0, 1] # [x, y, z]

      # Camera projection
      t.string :projection, limit: 20, default: 'perspective' # 'perspective' or 'orthogonal'

      # View metadata
      t.boolean :is_default, default: false
      t.integer :sort_order, default: 0

      t.timestamps null: false
    end

    # Indexes
    add_index :bim_saved_views, :ifc_model_id, name: 'index_saved_views_on_model'
    add_index :bim_saved_views, :user_id, name: 'index_saved_views_on_user'
    add_index :bim_saved_views, [:ifc_model_id, :name], name: 'index_saved_views_on_model_and_name'
    add_index :bim_saved_views, [:ifc_model_id, :is_default], name: 'index_saved_views_on_model_and_default'

    # Check constraints
    add_check_constraint :bim_saved_views, "projection IN ('perspective', 'orthogonal')", name: 'check_projection_type'
  end
end
