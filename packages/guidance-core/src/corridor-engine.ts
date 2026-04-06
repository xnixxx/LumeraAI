import { Coordinate, RouteSegment, CorridorEstimate } from "@lumera/domain";
import { CORRIDOR_THRESHOLDS } from "@lumera/config";

// Haversine distance between two coordinates (meters)
export function haversineDistanceM(a: Coordinate, b: Coordinate): number {
  const R = 6_371_000;
  const dLat = toRad(b.latitude - a.latitude);
  const dLon = toRad(b.longitude - a.longitude);
  const sinDLat = Math.sin(dLat / 2);
  const sinDLon = Math.sin(dLon / 2);
  const x =
    sinDLat * sinDLat +
    Math.cos(toRad(a.latitude)) *
      Math.cos(toRad(b.latitude)) *
      sinDLon *
      sinDLon;
  return R * 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1 - x));
}

function toRad(deg: number): number {
  return (deg * Math.PI) / 180;
}

// Bearing from a to b (degrees, 0 = north, clockwise)
export function bearingDeg(a: Coordinate, b: Coordinate): number {
  const dLon = toRad(b.longitude - a.longitude);
  const lat1 = toRad(a.latitude);
  const lat2 = toRad(b.latitude);
  const y = Math.sin(dLon) * Math.cos(lat2);
  const x =
    Math.cos(lat1) * Math.sin(lat2) -
    Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon);
  return ((Math.atan2(y, x) * 180) / Math.PI + 360) % 360;
}

// Signed cross-track distance from position to segment centerline (meters)
// Positive = right of centerline, negative = left
export function crossTrackDistanceM(
  position: Coordinate,
  segmentStart: Coordinate,
  segmentEnd: Coordinate
): number {
  const R = 6_371_000;
  const d13 = haversineDistanceM(segmentStart, position) / R; // angular dist
  const theta13 = toRad(bearingDeg(segmentStart, position));
  const theta12 = toRad(bearingDeg(segmentStart, segmentEnd));
  return Math.asin(Math.sin(d13) * Math.sin(theta13 - theta12)) * R;
}

// Along-track distance (how far along the segment we are)
export function alongTrackDistanceM(
  position: Coordinate,
  segmentStart: Coordinate,
  segmentEnd: Coordinate
): number {
  const R = 6_371_000;
  const d13 = haversineDistanceM(segmentStart, position) / R;
  const theta13 = toRad(bearingDeg(segmentStart, position));
  const theta12 = toRad(bearingDeg(segmentStart, segmentEnd));
  const dxt = Math.asin(Math.sin(d13) * Math.sin(theta13 - theta12));
  return Math.acos(Math.cos(d13) / Math.cos(dxt)) * R;
}

// Find the closest segment from a route to the runner's position
export function findClosestSegment(
  position: Coordinate,
  segments: RouteSegment[]
): { segment: RouteSegment; crossTrackM: number; alongTrackM: number } | null {
  let best: { segment: RouteSegment; crossTrackM: number; alongTrackM: number } | null = null;
  let bestAbsCrossTrack = Infinity;

  for (const segment of segments) {
    const polyline = segment.centerPolyline;
    for (let i = 0; i < polyline.length - 1; i++) {
      const start = polyline[i];
      const end = polyline[i + 1];
      if (!start || !end) continue;

      const crossTrack = crossTrackDistanceM(position, start, end);
      const absCtd = Math.abs(crossTrack);
      if (absCtd < bestAbsCrossTrack) {
        bestAbsCrossTrack = absCtd;
        best = {
          segment,
          crossTrackM: crossTrack,
          alongTrackM: alongTrackDistanceM(position, start, end),
        };
      }
    }
  }

  return best;
}

// Estimate corridor state from position + closest segment
export function estimateCorridor(
  position: Coordinate,
  segments: RouteSegment[],
  gpsConfidence: number
): CorridorEstimate {
  const match = findClosestSegment(position, segments);

  if (!match) {
    return {
      deviationFromCenterM: 0,
      onSoftCorridor: false,
      onHardCorridor: false,
      outsideCorridor: true,
      confidence: 0,
    };
  }

  const { segment, crossTrackM } = match;
  const absDeviation = Math.abs(crossTrackM);

  return {
    deviationFromCenterM: crossTrackM,
    onSoftCorridor: absDeviation <= segment.softCorridorWidthM,
    onHardCorridor:
      absDeviation > segment.softCorridorWidthM &&
      absDeviation <= segment.hardCorridorWidthM,
    outsideCorridor: absDeviation > CORRIDOR_THRESHOLDS.UNSAFE_M,
    confidence: gpsConfidence,
  };
}
