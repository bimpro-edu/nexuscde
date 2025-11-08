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

class CreateBimMeasurements < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_measurements do |t|
      t.references :ifc_model, null: false, foreign_key: { to_table: :bim_ifc_models, on_delete: :cascade }
      t.references :user, foreign_key: { to_table: :users, on_delete: :set_null }

      # Measurement type
      t.string :measurement_type, null: false, limit: 50
      # Types: 'distance', 'area', 'volume', 'angle', 'elevation'

      # Measurement value and unit
      t.decimal :value, precision: 15, scale: 4, null: false
      t.string :unit, null: false, limit: 20

      # Measurement points (array of [x, y, z] coordinates)
      # For distance: 2 points
      # For area: 3+ points
      # For volume: bounding box corners
      # For angle: 3 points
      t.jsonb :points, null: false, default: []

      # Display properties
      t.string :label, limit: 255
      t.string :color, limit: 7, default: '#FF0000'
      t.boolean :visible, default: true

      # Additional metadata
      t.jsonb :metadata, default: {}

      t.timestamps null: false
    end

    # Indexes
    add_index :bim_measurements, :ifc_model_id, name: 'index_measurements_on_model'
    add_index :bim_measurements, :user_id, name: 'index_measurements_on_user'
    add_index :bim_measurements, :measurement_type, name: 'index_measurements_on_type'
    add_index :bim_measurements, [:ifc_model_id, :measurement_type], name: 'index_measurements_on_model_and_type'
    add_index :bim_measurements, :visible, name: 'index_measurements_on_visible'

    # GIN index for points JSONB
    add_index :bim_measurements, :points, using: :gin, name: 'index_measurements_on_points'

    # Check constraints
    add_check_constraint :bim_measurements,
                         "measurement_type IN ('distance', 'area', 'volume', 'angle', 'elevation')",
                         name: 'check_measurement_type'
    add_check_constraint :bim_measurements, "value >= 0", name: 'check_measurement_value_positive'
  end
end
