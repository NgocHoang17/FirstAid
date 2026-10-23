package firstAid.example.firstAid.facility;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/v1/facilities")
public class FacilityController {

    private final FacilityService facilityService;

    public FacilityController(FacilityService facilityService) {
        this.facilityService = facilityService;
    }

    @GetMapping("/nearby")
    public ResponseEntity<List<NearbyFacility>> nearby(
            @RequestParam @DecimalMin(value = "-90") @DecimalMax(value = "90") double latitude,
            @RequestParam @DecimalMin(value = "-180") @DecimalMax(value = "180") double longitude,
            @RequestParam(defaultValue = "20") @DecimalMin(value = "1") @DecimalMax(value = "100") double radiusKm,
            @RequestParam(defaultValue = "3") @Min(1) @Max(10) int limit) {
        return ResponseEntity.ok(facilityService.findNearby(latitude, longitude, radiusKm, limit));
    }

    
}
