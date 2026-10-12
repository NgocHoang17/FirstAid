package firstAid.example.firstAid.facility;

public record MedicalFacility(
        String id,
        String name,
        String address,
        double latitude,
        double longitude,
        String phone,
        String source) {
}
