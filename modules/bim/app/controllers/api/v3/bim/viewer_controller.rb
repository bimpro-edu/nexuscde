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

module API
  module V3
    module Bim
      # Unified controller for 3D Viewer features: saved views, sections, measurements, annotations
      class ViewerController < ::API::V3::BaseController
        before_action :find_ifc_model, only: [:saved_views, :create_saved_view, :section_configs, :create_section_config, 
                                               :measurements, :create_measurement, :export_measurements,
                                               :annotations, :create_annotation]
        before_action :find_saved_view, only: [:show_saved_view, :update_saved_view, :destroy_saved_view]
        before_action :find_section_config, only: [:show_section_config, :destroy_section_config]
        before_action :find_measurement, only: [:destroy_measurement]
        before_action :find_annotation, only: [:update_annotation, :destroy_annotation]

        # GET /api/v3/bim/ifc_models/:id/saved_views
        def saved_views
          views = @ifc_model.saved_views.ordered
          render json: {
            _type: 'Collection',
            total: views.count,
            count: views.size,
            _embedded: {
              elements: views.map { |v| saved_view_representer(v) }
            }
          }
        end

        # POST /api/v3/bim/ifc_models/:id/saved_views
        def create_saved_view
          view = @ifc_model.saved_views.build(saved_view_params)
          view.user = current_user

          if view.save
            render json: saved_view_representer(view), status: :created
          else
            render json: error_response(view.errors), status: :unprocessable_entity
          end
        end

        # GET /api/v3/bim/saved_views/:id
        def show_saved_view
          render json: saved_view_representer(@saved_view)
        end

        # PATCH /api/v3/bim/saved_views/:id
        def update_saved_view
          if @saved_view.update(saved_view_params)
            render json: saved_view_representer(@saved_view)
          else
            render json: error_response(@saved_view.errors), status: :unprocessable_entity
          end
        end

        # DELETE /api/v3/bim/saved_views/:id
        def destroy_saved_view
          @saved_view.destroy
          head :no_content
        end

        # GET /api/v3/bim/ifc_models/:id/section_configs
        def section_configs
          configs = @ifc_model.section_configs.recent
          render json: {
            _type: 'Collection',
            total: configs.count,
            _embedded: { elements: configs.map { |c| section_config_representer(c) } }
          }
        end

        # POST /api/v3/bim/ifc_models/:id/section_configs
        def create_section_config
          config = @ifc_model.section_configs.build(section_config_params)
          config.user = current_user

          if config.save
            render json: section_config_representer(config), status: :created
          else
            render json: error_response(config.errors), status: :unprocessable_entity
          end
        end

        # DELETE /api/v3/bim/section_configs/:id
        def destroy_section_config
          @section_config.destroy
          head :no_content
        end

        # GET /api/v3/bim/ifc_models/:id/measurements
        def measurements
          measurements = @ifc_model.measurements.visible_only.recent
          render json: {
            _type: 'Collection',
            total: measurements.count,
            _embedded: { elements: measurements.map { |m| measurement_representer(m) } }
          }
        end

        # POST /api/v3/bim/ifc_models/:id/measurements
        def create_measurement
          measurement = @ifc_model.measurements.build(measurement_params)
          measurement.user = current_user

          if measurement.save
            render json: measurement_representer(measurement), status: :created
          else
            render json: error_response(measurement.errors), status: :unprocessable_entity
          end
        end

        # GET /api/v3/bim/ifc_models/:id/measurements/export
        def export_measurements
          measurements = @ifc_model.measurements.visible_only
          csv_data = ::Bim::Measurement.export_to_csv(measurements)
          
          send_data csv_data, filename: "measurements_#{@ifc_model.id}_#{Date.today}.csv", type: 'text/csv'
        end

        # DELETE /api/v3/bim/measurements/:id
        def destroy_measurement
          @measurement.destroy
          head :no_content
        end

        # GET /api/v3/bim/ifc_models/:id/annotations
        def annotations
          annotations = @ifc_model.annotations.visible_only.ordered_by_z
          render json: {
            _type: 'Collection',
            total: annotations.count,
            _embedded: { elements: annotations.map { |a| annotation_representer(a) } }
          }
        end

        # POST /api/v3/bim/ifc_models/:id/annotations
        def create_annotation
          annotation = @ifc_model.annotations.build(annotation_params)
          annotation.user = current_user

          if annotation.save
            render json: annotation_representer(annotation), status: :created
          else
            render json: error_response(annotation.errors), status: :unprocessable_entity
          end
        end

        # PATCH /api/v3/bim/annotations/:id
        def update_annotation
          if @annotation.update(annotation_params)
            render json: annotation_representer(@annotation)
          else
            render json: error_response(@annotation.errors), status: :unprocessable_entity
          end
        end

        # DELETE /api/v3/bim/annotations/:id
        def destroy_annotation
          @annotation.destroy
          head :no_content
        end

        private

        def find_ifc_model
          @ifc_model = ::Bim::IfcModels::IfcModel.find(params[:id] || params[:ifc_model_id])
        rescue ActiveRecord::RecordNotFound
          render json: { message: 'IFC model not found' }, status: :not_found
        end

        def find_saved_view
          @saved_view = ::Bim::SavedView.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { message: 'Saved view not found' }, status: :not_found
        end

        def find_section_config
          @section_config = ::Bim::SectionConfig.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { message: 'Section config not found' }, status: :not_found
        end

        def find_measurement
          @measurement = ::Bim::Measurement.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { message: 'Measurement not found' }, status: :not_found
        end

        def find_annotation
          @annotation = ::Bim::Annotation.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { message: 'Annotation not found' }, status: :not_found
        end

        # Representers

        def saved_view_representer(view)
          {
            _type: 'SavedView',
            id: view.id,
            name: view.name,
            description: view.description,
            camera_eye: view.camera_eye,
            camera_look: view.camera_look,
            camera_up: view.camera_up,
            projection: view.projection,
            is_default: view.is_default,
            created_at: view.created_at,
            _links: {
              self: { href: "/api/v3/bim/saved_views/#{view.id}" },
              model: { href: "/api/v3/bim/ifc_models/#{view.ifc_model_id}" }
            }
          }
        end

        def section_config_representer(config)
          {
            _type: 'SectionConfig',
            id: config.id,
            name: config.name,
            section_boxes: config.section_boxes,
            section_planes: config.section_planes,
            show_edges: config.show_edges,
            created_at: config.created_at
          }
        end

        def measurement_representer(measurement)
          {
            _type: 'Measurement',
            id: measurement.id,
            measurement_type: measurement.measurement_type,
            value: measurement.value,
            unit: measurement.unit,
            points: measurement.points,
            label: measurement.label,
            visible: measurement.visible,
            created_at: measurement.created_at
          }
        end

        def annotation_representer(annotation)
          {
            _type: 'Annotation',
            id: annotation.id,
            annotation_type: annotation.annotation_type,
            position: annotation.position,
            content: annotation.content,
            style: annotation.style,
            visible: annotation.visible,
            created_at: annotation.created_at
          }
        end

        def error_response(errors)
          {
            _type: 'Error',
            message: errors.full_messages.join(', ')
          }
        end

        # Strong parameters

        def saved_view_params
          params.require(:saved_view).permit(:name, :description, :projection, :is_default, :sort_order,
                                             camera_eye: [], camera_look: [], camera_up: [])
        end

        def section_config_params
          params.require(:section_config).permit(:name, :description, :show_edges, :fill_sections,
                                                 :edge_color, :fill_color, section_boxes: [], section_planes: [])
        end

        def measurement_params
          params.require(:measurement).permit(:measurement_type, :value, :unit, :label, :color, :visible,
                                             points: [], metadata: {})
        end

        def annotation_params
          params.require(:annotation).permit(:annotation_type, :content, :visible, :z_index, :bcf_issue_id,
                                            position: [], style: {}, geometry: {})
        end
      end
    end
  end
end
