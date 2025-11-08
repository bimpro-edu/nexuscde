# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bim::SavedView, type: :model do
  subject(:saved_view) { build(:bim_saved_view) }

  describe 'associations' do
    it { is_expected.to belong_to(:ifc_model).class_name('Bim::IfcModels::IfcModel') }
    it { is_expected.to belong_to(:user).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:camera_eye) }
    it { is_expected.to validate_presence_of(:camera_look) }
    it { is_expected.to validate_presence_of(:camera_up) }
    it { is_expected.to validate_inclusion_of(:projection).in_array(%w[perspective orthogonal]) }
  end

  describe 'scopes' do
    let!(:default_view) { create(:bim_saved_view, is_default: true) }
    let!(:regular_view) { create(:bim_saved_view, is_default: false) }
    let!(:recent_view) { create(:bim_saved_view, created_at: 1.hour.ago) }

    describe '.defaults' do
      it 'returns only default views' do
        expect(described_class.defaults).to contain_exactly(default_view)
      end
    end

    describe '.recent' do
      it 'orders by created_at descending' do
        expect(described_class.recent.first).to eq(regular_view)
      end
    end
  end

  describe '#default?' do
    it 'returns true when is_default is true' do
      saved_view.is_default = true
      expect(saved_view.default?).to be true
    end

    it 'returns false when is_default is false' do
      saved_view.is_default = false
      expect(saved_view.default?).to be false
    end
  end

  describe '#perspective?' do
    it 'returns true for perspective projection' do
      saved_view.projection = 'perspective'
      expect(saved_view.perspective?).to be true
    end
  end

  describe '#orthogonal?' do
    it 'returns true for orthogonal projection' do
      saved_view.projection = 'orthogonal'
      expect(saved_view.orthogonal?).to be true
    end
  end

  describe '#camera_distance' do
    it 'calculates distance between eye and look points' do
      saved_view.camera_eye = [0, 0, 0]
      saved_view.camera_look = [3, 4, 0]
      expect(saved_view.camera_distance).to eq(5.0)
    end
  end

  describe '#view_direction' do
    it 'returns normalized direction vector' do
      saved_view.camera_eye = [0, 0, 0]
      saved_view.camera_look = [10, 0, 0]
      expect(saved_view.view_direction).to eq([1, 0, 0])
    end
  end

  describe '#to_config' do
    it 'exports view configuration' do
      config = saved_view.to_config
      expect(config).to include(
        :id, :name, :camera, :distance, :is_default
      )
    end
  end
end
