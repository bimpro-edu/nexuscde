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

##
# 3D Viewer Demo Data Seeder
#
# Creates demonstration data for 3D Viewer enhancements:
# - Saved camera views
# - Section configurations
# - Measurements
# - Annotations
#
# Usage:
#   rails runner modules/bim/db/seeds/viewer_demo_data.rb
#

module Bim
  module Seeds
    class ViewerDemoData
      def self.seed!
        new.seed!
      end

      def seed!
        puts "🌱 Seeding 3D Viewer demo data..."

        @project = find_demo_project
        @user = User.admin.first || User.first
        @ifc_models = @project.ifc_models.limit(3)

        if @ifc_models.empty?
          puts "⚠️  No IFC models found. Please seed IFC upload data first."
          return
        end

        @ifc_models.each do |model|
          seed_saved_views(model)
          seed_section_configs(model)
          seed_measurements(model)
          seed_annotations(model)
        end

        print_summary

        puts "\n✅ 3D Viewer demo data seeded successfully!"
      end

      private

      def find_demo_project
        Project.find_by(identifier: 'ifc-upload-demo') ||
          Project.first ||
          Project.create!(
            name: 'BIM Demo',
            identifier: 'bim-demo',
            enabled_module_names: %w[bim work_package_tracking]
          )
      end

      def seed_saved_views(model)
        views = []

        # Default isometric view
        views << Bim::SavedView.create!(
          ifc_model: model,
          user: @user,
          name: 'Default Isometric',
          description: '3D isometric view',
          camera_eye: [50, -50, 50],
          camera_look: [0, 0, 0],
          camera_up: [0, 0, 1],
          projection: 'perspective',
          is_default: true,
          sort_order: 1
        )

        # Top view
        views << Bim::SavedView.create!(
          ifc_model: model,
          user: @user,
          name: 'Top View',
          description: 'Orthogonal view from above',
          camera_eye: [0, 0, 100],
          camera_look: [0, 0, 0],
          camera_up: [0, 1, 0],
          projection: 'orthogonal',
          sort_order: 2
        )

        # Front view
        views << Bim::SavedView.create!(
          ifc_model: model,
          user: @user,
          name: 'Front View',
          description: 'Orthogonal view from front',
          camera_eye: [0, -100, 0],
          camera_look: [0, 0, 0],
          camera_up: [0, 0, 1],
          projection: 'orthogonal',
          sort_order: 3
        )

        puts "  ✓ Created #{views.size} saved views for '#{model.title}'"
      end

      def seed_section_configs(model)
        # Section box configuration
        Bim::SectionConfig.create!(
          ifc_model: model,
          user: @user,
          name: 'Floor 1 Section',
          description: 'Section box for first floor',
          section_boxes: [{
            id: SecureRandom.uuid,
            min: [-20, -20, 0],
            max: [20, 20, 5],
            visible: true
          }],
          section_planes: [],
          show_edges: true,
          edge_color: '#FF0000'
        )

        # Section plane configuration
        Bim::SectionConfig.create!(
          ifc_model: model,
          user: @user,
          name: 'Vertical Cut',
          description: 'Vertical section plane',
          section_boxes: [],
          section_planes: [{
            id: SecureRandom.uuid,
            pos: [0, 0, 0],
            dir: [1, 0, 0],
            visible: true
          }],
          show_edges: true,
          edge_color: '#0000FF'
        )

        puts "  ✓ Created 2 section configs for '#{model.title}'"
      end

      def seed_measurements(model)
        measurements = []

        # Distance measurements
        measurements << Bim::Measurement.create!(
          ifc_model: model,
          user: @user,
          measurement_type: 'distance',
          value: 12.5,
          unit: 'm',
          points: [[0, 0, 0], [10, 5, 0]],
          label: 'Column spacing',
          color: '#FF0000',
          visible: true
        )

        measurements << Bim::Measurement.create!(
          ifc_model: model,
          user: @user,
          measurement_type: 'distance',
          value: 3.5,
          unit: 'm',
          points: [[0, 0, 0], [0, 0, 3.5]],
          label: 'Floor height',
          color: '#00FF00',
          visible: true
        )

        # Area measurement
        measurements << Bim::Measurement.create!(
          ifc_model: model,
          user: @user,
          measurement_type: 'area',
          value: 25.5,
          unit: 'm²',
          points: [[0, 0, 0], [5, 0, 0], [5, 5, 0], [0, 5, 0]],
          label: 'Room area',
          color: '#0000FF',
          visible: true
        )

        # Volume measurement
        measurements << Bim::Measurement.create!(
          ifc_model: model,
          user: @user,
          measurement_type: 'volume',
          value: 125.0,
          unit: 'm³',
          points: [[0, 0, 0], [5, 5, 5]],
          label: 'Space volume',
          color: '#FF00FF',
          visible: true
        )

        puts "  ✓ Created #{measurements.size} measurements for '#{model.title}'"
      end

      def seed_annotations(model)
        annotations = []

        # Label annotations
        annotations << Bim::Annotation.create!(
          ifc_model: model,
          user: @user,
          annotation_type: 'label',
          position: [10, 20, 5],
          content: 'Main Entrance',
          style: { color: '#000000', fontSize: 16, fontWeight: 'bold' },
          visible: true,
          z_index: 1
        )

        annotations << Bim::Annotation.create!(
          ifc_model: model,
          user: @user,
          annotation_type: 'label',
          position: [5, 10, 3],
          content: 'Structural Column C1',
          style: { color: '#0000FF', fontSize: 14 },
          visible: true,
          z_index: 2
        )

        # Dimension annotation
        annotations << Bim::Annotation.create!(
          ifc_model: model,
          user: @user,
          annotation_type: 'dimension',
          position: [0, 0, 0],
          content: '12.5m',
          style: { color: '#FF0000', fontSize: 14 },
          geometry: { start: [0, 0, 0], end: [12.5, 0, 0] },
          visible: true,
          z_index: 3
        )

        puts "  ✓ Created #{annotations.size} annotations for '#{model.title}'"
      end

      def print_summary
        puts "\n📊 3D Viewer Demo Summary:"
        puts "  Project: #{@project.name}"
        puts "  IFC Models: #{@ifc_models.size}"
        puts "  Total Saved Views: #{Bim::SavedView.count}"
        puts "  Total Section Configs: #{Bim::SectionConfig.count}"
        puts "  Total Measurements: #{Bim::Measurement.count}"
        puts "  Total Annotations: #{Bim::Annotation.count}"
      end
    end
  end
end

# Run seeder if executed directly
if __FILE__ == $PROGRAM_NAME
  Bim::Seeds::ViewerDemoData.seed!
end
