package firstAid.example.firstAid.facility;

public record NearbyFacility(
        String id,
        String name,
        String address,
        double latitude,
        double longitude,
        String phone,
        double distanceKm,
        String source) {
}
