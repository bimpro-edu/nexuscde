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
  # Measurements for IFC models  
  # Stores distance, area, volume, angle, and elevation measurements
  class Measurement < ApplicationRecord
    self.table_name = 'bim_measurements'

    MEASUREMENT_TYPES = %w[distance area volume angle elevation].freeze

    belongs_to :ifc_model, class_name: 'Bim::IfcModels::IfcModel'
    belongs_to :user, optional: true

    validates :measurement_type, presence: true, inclusion: { in: MEASUREMENT_TYPES }
    validates :value, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :unit, presence: true
    validates :points, presence: true

    scope :for_model, ->(model_id) { where(ifc_model_id: model_id) }
    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :by_type, ->(type) { where(measurement_type: type) }
    scope :visible_only, -> { where(visible: true) }
    scope :recent, -> { order(created_at: :desc) }

    # Type check methods
    def distance?
      measurement_type == 'distance'
    end

    def area?
      measurement_type == 'area'
    end

    def volume?
      measurement_type == 'volume'
    end

    def angle?
      measurement_type == 'angle'
    end

    def elevation?
      measurement_type == 'elevation'
    end

    # Get formatted value with unit
    def formatted_value
      "#{value.round(2)} #{unit}"
    end

    # Get point count
    def point_count
      (points || []).size
    end

    # Export for frontend
    def to_measurement_data
      {
        id: id,
        type: measurement_type,
        value: value,
        unit: unit,
        points: points || [],
        label: label,
        color: color,
        visible: visible,
        created_at: created_at
      }
    end

    # Class method: Export measurements to CSV
    def self.export_to_csv(measurements)
      require 'csv'
      CSV.generate do |csv|
        csv << ['ID', 'Type', 'Label', 'Value', 'Unit', 'Points', 'Created At']
        measurements.each do |m|
          csv << [m.id, m.measurement_type, m.label, m.value, m.unit, m.point_count, m.created_at]
        end
      end
    end
  end
end
