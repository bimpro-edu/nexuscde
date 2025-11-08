# 3D Viewer Enhancement

## Overview

The 3D Viewer Enhancement feature provides advanced visualization tools for IFC models, including section cuts, comprehensive measurements, enhanced navigation, and rendering quality controls. This transforms the basic xeokit viewer into a professional BIM coordination tool.

## Key Features

### 1. Advanced Section Cuts & Clipping
- **Section Boxes**: 6-plane interactive clipping boxes with draggable handles
- **Section Planes**: Custom cut planes with position and rotation control
- **Saved Configurations**: Store and recall section setups
- **Edge Highlighting**: Contrasting colors for cut edges
- **Multiple Sections**: Support for multiple simultaneous sections

### 2. Comprehensive Measurement Suite
- **Distance Measurements**: Point-to-point and multi-segment distances
- **Area Measurements**: Surface area and horizontal floor area calculations
- **Volume Measurements**: Bounding box and mesh volume
- **Angle Measurements**: Angles between surfaces and edges
- **Elevation Measurements**: Height from reference level
- **Persistent Storage**: Save measurements to database
- **CSV Export**: Export measurement reports

### 3. Enhanced Navigation
- **Multiple Modes**:
  - **Orbit Mode**: Standard 3D rotation around model
  - **Walk Mode**: First-person navigation with collision detection
  - **Fly Mode**: Free-form aerial navigation
  - **Plan Mode**: 2D plan view navigation
- **Saved Views**: Store and recall camera positions
- **Predefined Views**: Standard views (North, South, East, West, Top, Bottom, Isometric)
- **Fly-to Elements**: Animate camera to specific elements

### 4. Visual Quality Enhancements
- **Quality Presets**: Low, Medium, High, Ultra
- **Ambient Occlusion**: Screen-space ambient occlusion (SAO)
- **Edge Rendering**: Silhouette and crease edge highlighting
- **Physically-Based Rendering**: PBR materials support
- **Background Control**: Customizable background colors
- **Transparency Modes**: Normal and X-ray viewing

### 5. Annotation System
- **Label Annotations**: Text labels anchored to 3D positions
- **Dimension Annotations**: Measurement dimension lines
- **Sketch Annotations**: Freehand drawing on model
- **Symbol Annotations**: Standard BIM symbols
- **Redline Annotations**: Markup layers
- **BCF Integration**: Link annotations to BCF issues

---

## Database Schema

### Saved Views Table

```sql
CREATE TABLE bim_saved_views (
  id BIGSERIAL PRIMARY KEY,
  ifc_model_id BIGINT NOT NULL REFERENCES bim_ifc_models(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  
  name VARCHAR(255) NOT NULL,
  description VARCHAR(1000),
  
  camera_eye JSONB NOT NULL DEFAULT '[0,0,0]',
  camera_look JSONB NOT NULL DEFAULT '[0,0,0]',
  camera_up JSONB NOT NULL DEFAULT '[0,0,1]',
  projection VARCHAR(20) DEFAULT 'perspective',
  
  is_default BOOLEAN DEFAULT false,
  sort_order INTEGER DEFAULT 0,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  CHECK (projection IN ('perspective', 'orthogonal'))
);

CREATE INDEX idx_saved_views_on_model ON bim_saved_views(ifc_model_id);
CREATE INDEX idx_saved_views_on_model_and_default ON bim_saved_views(ifc_model_id, is_default);
```

### Section Configurations Table

```sql
CREATE TABLE bim_section_configs (
  id BIGSERIAL PRIMARY KEY,
  ifc_model_id BIGINT NOT NULL REFERENCES bim_ifc_models(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  
  name VARCHAR(255) NOT NULL,
  description VARCHAR(1000),
  
  section_boxes JSONB NOT NULL DEFAULT '[]',
  section_planes JSONB NOT NULL DEFAULT '[]',
  
  show_edges BOOLEAN DEFAULT true,
  fill_sections BOOLEAN DEFAULT false,
  edge_color VARCHAR(7) DEFAULT '#000000',
  fill_color VARCHAR(7) DEFAULT '#CCCCCC',
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_section_configs_on_model ON bim_section_configs(ifc_model_id);
CREATE INDEX idx_section_configs_on_boxes USING GIN(section_boxes);
```

### Measurements Table

```sql
CREATE TABLE bim_measurements (
  id BIGSERIAL PRIMARY KEY,
  ifc_model_id BIGINT NOT NULL REFERENCES bim_ifc_models(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  
  measurement_type VARCHAR(50) NOT NULL,
  value DECIMAL(15,4) NOT NULL,
  unit VARCHAR(20) NOT NULL,
  points JSONB NOT NULL DEFAULT '[]',
  
  label VARCHAR(255),
  color VARCHAR(7) DEFAULT '#FF0000',
  visible BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}',
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  CHECK (measurement_type IN ('distance', 'area', 'volume', 'angle', 'elevation')),
  CHECK (value >= 0)
);

CREATE INDEX idx_measurements_on_model ON bim_measurements(ifc_model_id);
CREATE INDEX idx_measurements_on_type ON bim_measurements(measurement_type);
```

### Annotations Table

```sql
CREATE TABLE bim_annotations (
  id BIGSERIAL PRIMARY KEY,
  ifc_model_id BIGINT NOT NULL REFERENCES bim_ifc_models(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  
  annotation_type VARCHAR(50) NOT NULL,
  position JSONB NOT NULL DEFAULT '[0,0,0]',
  content TEXT,
  
  style JSONB DEFAULT '{}',
  geometry JSONB DEFAULT '{}',
  
  visible BOOLEAN DEFAULT true,
  z_index INTEGER DEFAULT 0,
  bcf_issue_id INTEGER,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  CHECK (annotation_type IN ('label', 'dimension', 'sketch', 'symbol', 'redline'))
);

CREATE INDEX idx_annotations_on_model ON bim_annotations(ifc_model_id);
CREATE INDEX idx_annotations_on_type ON bim_annotations(annotation_type);
```

---

## API Endpoints

### Saved Views

```bash
# List all saved views for a model
GET /api/v3/bim/ifc_models/:id/saved_views

# Create a new saved view
POST /api/v3/bim/ifc_models/:id/saved_views
{
  "saved_view": {
    "name": "Floor 1 Overview",
    "camera_eye": [10.5, 20.3, 15.8],
    "camera_look": [0, 0, 0],
    "camera_up": [0, 0, 1],
    "projection": "perspective"
  }
}

# Get a specific saved view
GET /api/v3/bim/saved_views/:id

# Update a saved view
PATCH /api/v3/bim/saved_views/:id

# Delete a saved view
DELETE /api/v3/bim/saved_views/:id
```

### Section Configurations

```bash
# List section configs
GET /api/v3/bim/ifc_models/:id/section_configs

# Create section config
POST /api/v3/bim/ifc_models/:id/section_configs
{
  "section_config": {
    "name": "Floor 1 Section",
    "section_boxes": [
      { "id": "uuid", "min": [-10,-10,0], "max": [10,10,5], "visible": true }
    ],
    "show_edges": true
  }
}

# Delete section config
DELETE /api/v3/bim/section_configs/:id
```

### Measurements

```bash
# List measurements
GET /api/v3/bim/ifc_models/:id/measurements

# Create measurement
POST /api/v3/bim/ifc_models/:id/measurements
{
  "measurement": {
    "measurement_type": "distance",
    "value": 12.5,
    "unit": "m",
    "points": [[0,0,0], [10,5,0]],
    "label": "Column spacing"
  }
}

# Export measurements to CSV
GET /api/v3/bim/ifc_models/:id/measurements/export

# Delete measurement
DELETE /api/v3/bim/measurements/:id
```

### Annotations

```bash
# List annotations
GET /api/v3/bim/ifc_models/:id/annotations

# Create annotation
POST /api/v3/bim/ifc_models/:id/annotations
{
  "annotation": {
    "annotation_type": "label",
    "position": [10, 20, 5],
    "content": "Main Entrance",
    "style": { "color": "#000000", "fontSize": 16 }
  }
}

# Update annotation
PATCH /api/v3/bim/annotations/:id

# Delete annotation
DELETE /api/v3/bim/annotations/:id
```

---

## Frontend Usage

### Initialize Managers

```typescript
import { SectionManager, MeasurementManager, NavigationManager, RenderingManager } from './managers';

// In your viewer component
export class IFCViewerComponent implements OnInit {
  private sectionManager: SectionManager;
  private measurementManager: MeasurementManager;
  private navigationManager: NavigationManager;
  private renderingManager: RenderingManager;

  constructor(private http: HttpClient) {
    this.sectionManager = new SectionManager(http);
    this.measurementManager = new MeasurementManager(http);
    this.navigationManager = new NavigationManager(http);
    this.renderingManager = new RenderingManager();
  }

  ngOnInit(): void {
    // Initialize after viewer is ready
    this.sectionManager.initialize(this.viewer);
    this.measurementManager.initialize(this.viewer, this.modelId);
    this.navigationManager.initialize(this.viewer, this.modelId);
    this.renderingManager.initialize(this.viewer);
  }
}
```

### Section Management

```typescript
// Create a section box
const box = this.sectionManager.createBox();

// Create a section plane
const plane = this.sectionManager.createPlane(
  [0, 0, 0],  // origin
  [1, 0, 0]   // normal (X-axis)
);

// Save configuration
this.sectionManager.saveConfiguration(modelId, 'Floor 1 Section').subscribe(
  config => console.log('Section saved:', config)
);

// Load and apply configuration
this.sectionManager.loadConfiguration(modelId).subscribe(response => {
  const config = response._embedded.elements[0];
  this.sectionManager.applyConfiguration(config);
});
```

### Measurement Tools

```typescript
// Start distance measurement
this.measurementManager.startMeasurement('distance');

// Start area measurement
this.measurementManager.startMeasurement('area');

// Export to CSV
this.measurementManager.exportToCSV();

// Load existing measurements
this.measurementManager.loadMeasurements().subscribe(response => {
  const measurements = response._embedded.elements;
  console.log(`Loaded ${measurements.length} measurements`);
});
```

### Navigation

```typescript
// Change navigation mode
this.navigationManager.setMode('walk'); // or 'orbit', 'fly', 'plan'

// Save current view
this.navigationManager.saveView('Custom View 1', 'My saved view').subscribe(
  view => console.log('View saved:', view)
);

// Restore a saved view
this.navigationManager.restoreView(viewId);

// Set predefined view
this.navigationManager.setPredefinedView('isometric');

// Fly to element
this.navigationManager.flyToElement('element-guid-123');
```

### Rendering Quality

```typescript
// Set quality preset
this.renderingManager.setQuality('high'); // 'low', 'medium', 'high', 'ultra'

// Individual controls
this.renderingManager.setAmbientOcclusion(true, 1.0);
this.renderingManager.setEdges(true);
this.renderingManager.setPBR(true);
this.renderingManager.setBackgroundColor('#F0F0F0');
```

---

## Demo Data

Generate demo data with sample views, sections, measurements, and annotations:

```bash
rails runner modules/bim/db/seeds/viewer_demo_data.rb
```

This creates:
- 3 saved views per model (Default Isometric, Top View, Front View)
- 2 section configurations per model
- 4 measurements per model (distance, area, volume)
- 3 annotations per model (labels, dimensions)

---

## Testing

### Model Tests

```bash
bundle exec rspec modules/bim/spec/models/bim/saved_view_spec.rb
```

### API Integration Tests

```bash
bundle exec rspec modules/bim/spec/requests/api/v3/bim/viewer_spec.rb
```

---

## Performance Considerations

### Database Optimization
- **GIN Indexes**: JSONB columns have GIN indexes for fast queries
- **Eager Loading**: Use `.includes()` to avoid N+1 queries
- **Pagination**: Large measurement/annotation sets should be paginated

### Frontend Optimization
- **Lazy Loading**: Load managers only when needed
- **Debouncing**: Debounce section box updates
- **Worker Threads**: Offload heavy calculations to web workers
- **Caching**: Cache loaded configurations

---

## Troubleshooting

**Section cuts not appearing:**
- Verify section box bounds are within model AABB
- Check if `visible` property is true
- Ensure viewer scene supports sections

**Measurements not saving:**
- Verify user has manage_ifc_models permission
- Check backend logs for validation errors
- Ensure points array has correct format

**Navigation mode not changing:**
- Check if xeokit CameraControl supports the mode
- Verify viewer is fully initialized
- Some modes may require specific xeokit version

**Performance issues with many annotations:**
- Limit visible annotations via z-index
- Use pagination for annotation lists
- Consider using LoD for distant annotations

---

## Future Enhancements

- **Advanced Rendering**: Shadow mapping, SSAO, HDR lighting
- **Animation**: Camera path animations, guided tours
- **Minimap**: 2D plan view with camera indicator
- **Measurement Reports**: PDF export with thumbnails
- **Collaborative Annotations**: Real-time annotation sharing
- **AR/VR Support**: Extended reality viewing modes

---

## Related Features

- **IFC Upload Enhancement (Slice 1)**: Provides optimized XKT files
- **Model Comparison (Slice 5)**: Uses saved views for comparisons
- **Clash Detection (Slice 6)**: Visualizes clashes with sections
- **BCF Integration**: Links annotations to BCF issues

---

## References

- [xeokit SDK Documentation](https://xeokit.io/)
- [BIMViewer API](https://xeokit.github.io/xeokit-sdk/docs/)
- [OpenProject BIM Edition](https://www.openproject.org/bim-project-management/)
