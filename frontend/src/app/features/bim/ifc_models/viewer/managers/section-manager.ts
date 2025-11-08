/**
 * Section Manager
 * 
 * Manages section boxes and planes for IFC model sectioning.
 * Provides interactive clipping and saved section configurations.
 */

import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

export interface SectionBox {
  id: string;
  min: [number, number, number];
  max: [number, number, number];
  visible: boolean;
  color?: string;
}

export interface SectionPlane {
  id: string;
  pos: [number, number, number];
  dir: [number, number, number];
  visible: boolean;
  color?: string;
}

export interface SectionConfig {
  id?: number;
  name: string;
  description?: string;
  section_boxes: SectionBox[];
  section_planes: SectionPlane[];
  show_edges: boolean;
  fill_sections: boolean;
  edge_color: string;
  fill_color: string;
}

@Injectable()
export class SectionManager {
  private viewer: any; // xeokit BIMViewer
  private sectionBoxes: Map<string, any> = new Map();
  private sectionPlanes: Map<string, any> = new Map();
  private currentConfig: SectionConfig | null = null;

  constructor(private http: HttpClient) {}

  initialize(viewer: any): void {
    this.viewer = viewer;
  }

  // Create a new section box
  createBox(): any {
    if (!this.viewer) throw new Error('Viewer not initialized');

    const id = this.generateUUID();
    const box = new (window as any).XKT.SectionBox(this.viewer.scene, {
      id,
      visible: true,
      gizmoVisible: true
    });

    // Listen for updates
    box.on('updated', () => this.onSectionUpdated());

    this.sectionBoxes.set(id, box);
    return box;
  }

  // Create a new section plane
  createPlane(origin: [number, number, number], normal: [number, number, number]): any {
    if (!this.viewer) throw new Error('Viewer not initialized');

    const id = this.generateUUID();
    const plane = new (window as any).XKT.SectionPlane(this.viewer.scene, {
      id,
      pos: origin,
      dir: normal
    });

    this.sectionPlanes.set(id, plane);
    return plane;
  }

  // Remove a section box
  removeBox(id: string): void {
    const box = this.sectionBoxes.get(id);
    if (box) {
      box.destroy();
      this.sectionBoxes.delete(id);
    }
  }

  // Remove a section plane
  removePlane(id: string): void {
    const plane = this.sectionPlanes.get(id);
    if (plane) {
      plane.destroy();
      this.sectionPlanes.delete(id);
    }
  }

  // Clear all sections
  clearAll(): void {
    this.sectionBoxes.forEach(box => box.destroy());
    this.sectionPlanes.forEach(plane => plane.destroy());
    this.sectionBoxes.clear();
    this.sectionPlanes.clear();
  }

  // Save current section configuration to backend
  saveConfiguration(modelId: number, name: string, description?: string): Observable<SectionConfig> {
    const config: SectionConfig = {
      name,
      description,
      section_boxes: this.exportBoxes(),
      section_planes: this.exportPlanes(),
      show_edges: true,
      fill_sections: false,
      edge_color: '#000000',
      fill_color: '#CCCCCC'
    };

    return this.http.post<SectionConfig>(`/api/v3/bim/ifc_models/${modelId}/section_configs`, {
      section_config: config
    });
  }

  // Load section configuration from backend
  loadConfiguration(modelId: number): Observable<{ _embedded: { elements: SectionConfig[] } }> {
    return this.http.get<{ _embedded: { elements: SectionConfig[] } }>(
      `/api/v3/bim/ifc_models/${modelId}/section_configs`
    );
  }

  // Apply a saved configuration
  applyConfiguration(config: SectionConfig): void {
    this.clearAll();

    // Restore boxes
    config.section_boxes.forEach(boxData => {
      const box = this.createBox();
      box.min = boxData.min;
      box.max = boxData.max;
      box.visible = boxData.visible;
    });

    // Restore planes
    config.section_planes.forEach(planeData => {
      this.createPlane(planeData.pos, planeData.dir);
    });

    this.currentConfig = config;
  }

  // Export boxes to data format
  private exportBoxes(): SectionBox[] {
    const boxes: SectionBox[] = [];
    this.sectionBoxes.forEach((box, id) => {
      boxes.push({
        id,
        min: box.min,
        max: box.max,
        visible: box.visible
      });
    });
    return boxes;
  }

  // Export planes to data format
  private exportPlanes(): SectionPlane[] {
    const planes: SectionPlane[] = [];
    this.sectionPlanes.forEach((plane, id) => {
      planes.push({
        id,
        pos: plane.pos,
        dir: plane.dir,
        visible: plane.visible
      });
    });
    return planes;
  }

  private onSectionUpdated(): void {
    // Emit event or trigger update
  }

  private generateUUID(): string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  // Get section count
  getSectionCount(): number {
    return this.sectionBoxes.size + this.sectionPlanes.size;
  }

  // Check if has sections
  hasSections(): boolean {
    return this.getSectionCount() > 0;
  }
}
