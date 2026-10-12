package firstAid.example.firstAid.facility;

import java.util.Comparator;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class FacilityService {

    private static final double EARTH_RADIUS_KM = 6371.0088;

    // Seed data only. Replace with an approved, regularly refreshed provider before production.
    private static final List<MedicalFacility> FACILITIES = List.of(
            new MedicalFacility("sample-1", "Cơ sở y tế mẫu Quận 1", "Quận 1, TP. Hồ Chí Minh", 10.7769, 106.7009, "115", "SAMPLE_DATA"),
            new MedicalFacility("sample-2", "Cơ sở y tế mẫu Bình Thạnh", "Bình Thạnh, TP. Hồ Chí Minh", 10.8106, 106.7091, "115", "SAMPLE_DATA"),
            new MedicalFacility("sample-3", "Cơ sở y tế mẫu Thủ Đức", "Thủ Đức, TP. Hồ Chí Minh", 10.8498, 106.7550, "115", "SAMPLE_DATA"));

    public List<NearbyFacility> findNearby(double latitude, double longitude, double radiusKm, int limit) {
        return FACILITIES.stream()
                .map(facility -> toNearby(facility, latitude, longitude))
                .filter(facility -> facility.distanceKm() <= radiusKm)
                .sorted(Comparator.comparingDouble(NearbyFacility::distanceKm))
                .limit(limit)
                .toList();
    }

    private NearbyFacility toNearby(MedicalFacility facility, double latitude, double longitude) {
        double distance = haversine(latitude, longitude, facility.latitude(), facility.longitude());
        return new NearbyFacility(facility.id(), facility.name(), facility.address(), facility.latitude(), facility.longitude(),
                facility.phone(), Math.round(distance * 100.0) / 100.0, facility.source());
    }

    private double haversine(double lat1, double lon1, double lat2, double lon2) {
        double latDelta = Math.toRadians(lat2 - lat1);
        double lonDelta = Math.toRadians(lon2 - lon1);
        double value = Math.sin(latDelta / 2) * Math.sin(latDelta / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDelta / 2) * Math.sin(lonDelta / 2);
        return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(value), Math.sqrt(1 - value));
    }
}
