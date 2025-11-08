# frozen_string_literal: true

FactoryBot.define do
  factory :bim_saved_view, class: 'Bim::SavedView' do
    association :ifc_model, factory: :bim_ifc_model
    association :user, factory: :user

    name { "Saved View #{SecureRandom.hex(4)}" }
    description { 'A saved camera view' }
    camera_eye { [10.0, 20.0, 15.0] }
    camera_look { [0.0, 0.0, 0.0] }
    camera_up { [0.0, 0.0, 1.0] }
    projection { 'perspective' }
    is_default { false }
    sort_order { 0 }

    trait :default do
      is_default { true }
      name { 'Default View' }
    end

    trait :orthogonal do
      projection { 'orthogonal' }
    end

    trait :top_view do
      name { 'Top View' }
      camera_eye { [0.0, 0.0, 50.0] }
      camera_up { [0.0, 1.0, 0.0] }
      projection { 'orthogonal' }
    end
  end

  factory :bim_section_config, class: 'Bim::SectionConfig' do
    association :ifc_model, factory: :bim_ifc_model
    association :user, factory: :user

    name { "Section #{SecureRandom.hex(4)}" }
    description { 'A section configuration' }
    section_boxes { [{ id: SecureRandom.uuid, min: [-10, -10, -10], max: [10, 10, 10], visible: true }] }
    section_planes { [] }
    show_edges { true }
    fill_sections { false }
    edge_color { '#000000' }
    fill_color { '#CCCCCC' }
  end

  factory :bim_measurement, class: 'Bim::Measurement' do
    association :ifc_model, factory: :bim_ifc_model
    association :user, factory: :user

    measurement_type { 'distance' }
    value { 12.5 }
    unit { 'm' }
    points { [[0, 0, 0], [10, 5, 0]] }
    label { 'Distance measurement' }
    color { '#FF0000' }
    visible { true }

    trait :area do
      measurement_type { 'area' }
      value { 25.5 }
      unit { 'm²' }
      points { [[0, 0, 0], [5, 0, 0], [5, 5, 0], [0, 5, 0]] }
      label { 'Area measurement' }
    end

    trait :volume do
      measurement_type { 'volume' }
      value { 125.0 }
      unit { 'm³' }
      label { 'Volume measurement' }
    end
  end

  factory :bim_annotation, class: 'Bim::Annotation' do
    association :ifc_model, factory: :bim_ifc_model
    association :user, factory: :user

    annotation_type { 'label' }
    position { [10.0, 20.0, 5.0] }
    content { 'Sample annotation' }
    style { { color: '#000000', fontSize: 14 } }
    geometry { {} }
    visible { true }
    z_index { 0 }

    trait :dimension do
      annotation_type { 'dimension' }
      content { '12.5m' }
    end

    trait :sketch do
      annotation_type { 'sketch' }
      geometry { { path: [[0, 0], [10, 10], [20, 5]] } }
    end
  end
end
