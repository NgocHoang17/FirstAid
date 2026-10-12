package firstAid.example.firstAid.triage;

import java.util.List;

public record TriageResponse(
        Protocol protocol,
        boolean callEmergencyServices,
        String emergencyNumber,
        String headline,
        List<String> immediateActions,
        String safetyNotice) {

    public enum Protocol {
        CPR,
        NO_BREATHING,
        SEVERE_BLEEDING,
        UNCONSCIOUS,
        ASSESSMENT
    }
}
