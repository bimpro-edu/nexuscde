/**
 * Rendering Manager
 * 
 * Manages rendering quality settings for the 3D viewer.
 * Provides presets and individual controls for visual effects.
 */

import { Injectable } from '@angular/core';

export type RenderingQuality = 'low' | 'medium' | 'high' | 'ultra';

export interface RenderingConfig {
  sao: boolean; // Screen-space ambient occlusion
  saoScale?: number;
  edges: boolean;
  pbr: boolean; // Physically-based rendering
  shadows: boolean;
  shadowMapSize?: number;
  antialias: boolean;
}

@Injectable()
export class RenderingManager {
  private viewer: any;
  private currentQuality: RenderingQuality = 'medium';

  initialize(viewer: any): void {
    this.viewer = viewer;
    this.setQuality('medium'); // Set default quality
  }

  // Set rendering quality preset
  setQuality(quality: RenderingQuality): void {
    if (!this.viewer) return;

    this.currentQuality = quality;

    const configs: Record<RenderingQuality, RenderingConfig> = {
      low: {
        sao: false,
        edges: false,
        pbr: false,
        shadows: false,
        antialias: false
      },
      medium: {
        sao: true,
        saoScale: 0.5,
        edges: true,
        pbr: false,
        shadows: false,
        antialias: true
      },
      high: {
        sao: true,
        saoScale: 1.0,
        edges: true,
        pbr: true,
        shadows: false,
        antialias: true
      },
      ultra: {
        sao: true,
        saoScale: 1.5,
        edges: true,
        pbr: true,
        shadows: true,
        shadowMapSize: 2048,
        antialias: true
      }
    };

    this.applyConfig(configs[quality]);
  }

  // Get current quality setting
  getQuality(): RenderingQuality {
    return this.currentQuality;
  }

  // Apply rendering configuration
  private applyConfig(config: RenderingConfig): void {
    if (!this.viewer) return;

    const scene = this.viewer.scene;

    // Apply SAO (Screen-space Ambient Occlusion)
    if (scene.sao) {
      scene.sao.enabled = config.sao;
      if (config.saoScale !== undefined) {
        scene.sao.scale = config.saoScale;
      }
    }

    // Apply edge rendering
    if (scene.edgeMaterial) {
      scene.edgeMaterial.edges = config.edges;
    }

    // Apply PBR
    if (scene.pbrEnabled !== undefined) {
      scene.pbrEnabled = config.pbr;
    }

    // Note: Shadow rendering requires additional implementation
    // as it's not a standard xeokit feature
  }

  // Enable/disable shadows
  setShadows(enabled: boolean): void {
    // Custom shadow implementation would go here
    console.log(`Shadows ${enabled ? 'enabled' : 'disabled'}`);
  }

  // Enable/disable ambient occlusion
  setAmbientOcclusion(enabled: boolean, scale = 1.0): void {
    if (!this.viewer || !this.viewer.scene.sao) return;

    this.viewer.scene.sao.enabled = enabled;
    this.viewer.scene.sao.scale = scale;
  }

  // Enable/disable edge rendering
  setEdges(enabled: boolean): void {
    if (!this.viewer || !this.viewer.scene.edgeMaterial) return;

    this.viewer.scene.edgeMaterial.edges = enabled;
  }

  // Enable/disable physically-based rendering
  setPBR(enabled: boolean): void {
    if (!this.viewer || this.viewer.scene.pbrEnabled === undefined) return;

    this.viewer.scene.pbrEnabled = enabled;
  }

  // Set background color
  setBackgroundColor(color: string): void {
    if (!this.viewer) return;

    // Convert hex to RGB
    const rgb = this.hexToRgb(color);
    if (rgb) {
      this.viewer.scene.canvas.backgroundColor = [rgb.r / 255, rgb.g / 255, rgb.b / 255];
    }
  }

  // Set transparency
  setTransparencyMode(mode: 'normal' | 'xray'): void {
    if (!this.viewer) return;

    const scene = this.viewer.scene;
    if (mode === 'xray') {
      scene.xrayMaterial.fill = true;
      scene.xrayMaterial.fillAlpha = 0.3;
      scene.xrayMaterial.fillColor = [0.3, 0.3, 1.0];
    }
  }

  private hexToRgb(hex: string): { r: number, g: number, b: number } | null {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
      r: parseInt(result[1], 16),
      g: parseInt(result[2], 16),
      b: parseInt(result[3], 16)
    } : null;
  }

  // Reset to default settings
  reset(): void {
    this.setQuality('medium');
  }
}
