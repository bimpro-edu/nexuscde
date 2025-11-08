/**
 * Navigation Manager
 * 
 * Manages camera navigation modes, saved views, and predefined views.
 * Supports orbit, walk, fly, and plan modes.
 */

import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

export type NavigationMode = 'orbit' | 'walk' | 'fly' | 'plan';
export type PredefinedView = 'north' | 'south' | 'east' | 'west' | 'top' | 'bottom' | 'isometric';

export interface SavedView {
  id?: number;
  name: string;
  description?: string;
  camera_eye: [number, number, number];
  camera_look: [number, number, number];
  camera_up: [number, number, number];
  projection: 'perspective' | 'orthogonal';
  is_default?: boolean;
}

@Injectable()
export class NavigationManager {
  private viewer: any;
  private mode: NavigationMode = 'orbit';
  private modelId: number | null = null;
  private savedViews: Map<number, SavedView> = new Map();

  constructor(private http: HttpClient) {}

  initialize(viewer: any, modelId: number): void {
    this.viewer = viewer;
    this.modelId = modelId;
    this.loadSavedViews();
  }

  // Set navigation mode
  setMode(mode: NavigationMode): void {
    if (!this.viewer) return;

    this.mode = mode;
    const cameraControl = this.viewer.cameraControl;

    switch (mode) {
      case 'orbit':
        cameraControl.navMode = 'orbit';
        cameraControl.followPointer = false;
        break;

      case 'walk':
        cameraControl.navMode = 'firstPerson';
        cameraControl.followPointer = true;
        cameraControl.firstPersonKeyRate = 5.0;
        break;

      case 'fly':
        cameraControl.navMode = 'planView';
        cameraControl.followPointer = true;
        break;

      case 'plan':
        cameraControl.navMode = 'planView';
        this.setPredefinedView('top');
        break;
    }
  }

  // Get current navigation mode
  getMode(): NavigationMode {
    return this.mode;
  }

  // Save current view
  saveView(name: string, description?: string, isDefault = false): Observable<SavedView> {
    if (!this.viewer || !this.modelId) throw new Error('Viewer or model not initialized');

    const camera = this.viewer.camera;
    const view: SavedView = {
      name,
      description,
      camera_eye: Array.from(camera.eye) as [number, number, number],
      camera_look: Array.from(camera.look) as [number, number, number],
      camera_up: Array.from(camera.up) as [number, number, number],
      projection: camera.projection === 'perspective' ? 'perspective' : 'orthogonal',
      is_default: isDefault
    };

    return this.http.post<SavedView>(
      `/api/v3/bim/ifc_models/${this.modelId}/saved_views`,
      { saved_view: view }
    );
  }

  // Load saved views from backend
  loadSavedViews(): void {
    if (!this.modelId) return;

    this.http.get<{ _embedded: { elements: SavedView[] } }>(
      `/api/v3/bim/ifc_models/${this.modelId}/saved_views`
    ).subscribe(response => {
      this.savedViews.clear();
      response._embedded.elements.forEach(view => {
        if (view.id) {
          this.savedViews.set(view.id, view);
        }
      });
    });
  }

  // Restore a saved view
  restoreView(viewId: number): void {
    const view = this.savedViews.get(viewId);
    if (!view || !this.viewer) return;

    const camera = this.viewer.camera;
    camera.eye = view.camera_eye;
    camera.look = view.camera_look;
    camera.up = view.camera_up;
    camera.projection = view.projection;
  }

  // Delete a saved view
  deleteView(viewId: number): Observable<void> {
    return this.http.delete<void>(`/api/v3/bim/saved_views/${viewId}`);
  }

  // Set predefined view
  setPredefinedView(view: PredefinedView): void {
    if (!this.viewer) return;

    const scene = this.viewer.scene;
    const aabb = scene.aabb;
    const center: [number, number, number] = [
      (aabb[0] + aabb[3]) / 2,
      (aabb[1] + aabb[4]) / 2,
      (aabb[2] + aabb[5]) / 2
    ];

    const distance = Math.max(
      aabb[3] - aabb[0],
      aabb[4] - aabb[1],
      aabb[5] - aabb[2]
    ) * 1.5;

    const viewConfigs: Record<PredefinedView, { eye: [number, number, number], up: [number, number, number] }> = {
      north: { eye: [center[0], center[1] - distance, center[2]], up: [0, 0, 1] },
      south: { eye: [center[0], center[1] + distance, center[2]], up: [0, 0, 1] },
      east: { eye: [center[0] + distance, center[1], center[2]], up: [0, 0, 1] },
      west: { eye: [center[0] - distance, center[1], center[2]], up: [0, 0, 1] },
      top: { eye: [center[0], center[1], center[2] + distance], up: [0, 1, 0] },
      bottom: { eye: [center[0], center[1], center[2] - distance], up: [0, -1, 0] },
      isometric: {
        eye: [center[0] + distance, center[1] - distance, center[2] + distance],
        up: [0, 0, 1]
      }
    };

    const config = viewConfigs[view];
    const camera = this.viewer.camera;
    camera.eye = config.eye;
    camera.look = center;
    camera.up = config.up;
  }

  // Fly to element
  flyToElement(elementId: string, duration = 1.0): void {
    if (!this.viewer) return;

    const entity = this.viewer.scene.objects[elementId];
    if (!entity) return;

    this.viewer.cameraFlight.flyTo({
      aabb: entity.aabb,
      duration
    });
  }

  // Get saved views list
  getSavedViews(): SavedView[] {
    return Array.from(this.savedViews.values());
  }
}
