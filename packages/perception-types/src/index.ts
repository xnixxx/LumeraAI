import { HazardType, HazardSeverity } from "@lumera/domain";

// Raw output from the vision inference adapter before normalization
export interface RawVisionFrame {
  frameId: string;
  capturedAt: Date;
  widthPx: number;
  heightPx: number;
  detections: RawDetection[];
  freeSpaceMaskAvailable: boolean;
}

export interface RawDetection {
  classLabel: string;
  confidenceScore: number; // 0.0–1.0
  boundingBox: BoundingBox;
  depthEstimateM?: number;
}

export interface BoundingBox {
  xMinNorm: number;
  yMinNorm: number;
  xMaxNorm: number;
  yMaxNorm: number;
}

// Normalized hazard output (model-agnostic)
export interface PerceptionHazard {
  hazardType: HazardType;
  severity: HazardSeverity;
  distanceM: number;
  lateralOffsetM: number; // + = right of runner, - = left
  widthM: number;
  confidence: number;
  sourceFrameId: string;
}

// Free space output
export interface FreeSpaceOutput {
  estimatedClearWidthM: number;
  leftBoundaryM: number;
  rightBoundaryM: number;
  centerOffsetM: number; // how far center of free space is from runner center
  confidence: number;
}

// Complete perception output batch
export interface PerceptionOutput {
  frameId: string;
  timestamp: Date;
  hazards: PerceptionHazard[];
  freeSpace: FreeSpaceOutput | null;
  processingLatencyMs: number;
  modelVersion: string;
}
