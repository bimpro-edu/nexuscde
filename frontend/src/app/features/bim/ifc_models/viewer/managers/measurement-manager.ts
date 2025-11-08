/**
 * Measurement Manager
 * 
 * Manages measurements for IFC models: distance, area, volume, angle, elevation.
 * Provides persistent storage and CSV export.
 */

import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

export type MeasurementType = 'distance' | 'area' | 'volume' | 'angle' | 'elevation';

export interface Measurement {
  id?: number;
  measurement_type: MeasurementType;
  value: number;
  unit: string;
  points: [number, number, number][];
  label?: string;
  color?: string;
  visible: boolean;
}

@Injectable()
export class MeasurementManager {
  private viewer: any;
  private measurements: Map<number, Measurement> = new Map();
  private activeTool: any = null;
  private modelId: number | null = null;

  constructor(private http: HttpClient) {}

  initialize(viewer: any, modelId: number): void {
    this.viewer = viewer;
    this.modelId = modelId;
  }

  // Start measurement tool
  startMeasurement(type: MeasurementType): void {
    if (!this.viewer) throw new Error('Viewer not initialized');

    this.stopActiveTool();

    switch (type) {
      case 'distance':
        this.activeTool = new (window as any).XKT.DistanceMeasurementsPlugin(this.viewer);
        break;
      case 'area':
        // Custom implementation
        break;
      case 'angle':
        this.activeTool = new (window as any).XKT.AngleMeasurementsPlugin(this.viewer);
        break;
      default:
        console.warn(`Measurement type ${type} not yet implemented`);
    }

    if (this.activeTool) {
      this.activeTool.on('measurementEnd', (measurement: any) => {
        this.onMeasurementComplete(type, measurement);
      });
      this.activeTool.activate();
    }
  }

  // Stop active tool
  stopActiveTool(): void {
    if (this.activeTool) {
      this.activeTool.deactivate();
      this.activeTool = null;
    }
  }

  // Save measurement to backend
  saveMeasurement(measurement: Measurement): Observable<Measurement> {
    if (!this.modelId) throw new Error('Model ID not set');

    return this.http.post<Measurement>(
      `/api/v3/bim/ifc_models/${this.modelId}/measurements`,
      { measurement }
    );
  }

  // Load measurements from backend
  loadMeasurements(): Observable<{ _embedded: { elements: Measurement[] } }> {
    if (!this.modelId) throw new Error('Model ID not set');

    return this.http.get<{ _embedded: { elements: Measurement[] } }>(
      `/api/v3/bim/ifc_models/${this.modelId}/measurements`
    );
  }

  // Delete measurement
  deleteMeasurement(id: number): Observable<void> {
    return this.http.delete<void>(`/api/v3/bim/measurements/${id}`);
  }

  // Export measurements to CSV
  exportToCSV(): void {
    if (!this.modelId) throw new Error('Model ID not set');

    window.location.href = `/api/v3/bim/ifc_models/${this.modelId}/measurements/export`;
  }

  // Clear all measurements
  clearAll(): void {
    this.measurements.clear();
    // Clear visual measurements from viewer
  }

  private onMeasurementComplete(type: MeasurementType, measurement: any): void {
    const data: Measurement = {
      measurement_type: type,
      value: measurement.length || measurement.angle || 0,
      unit: type === 'angle' ? 'degrees' : 'm',
      points: measurement.origin ? [measurement.origin, measurement.corner] : [],
      visible: true
    };

    this.saveMeasurement(data).subscribe(saved => {
      this.measurements.set(saved.id!, saved);
    });
  }

  getMeasurementCount(): number {
    return this.measurements.size;
  }
}
