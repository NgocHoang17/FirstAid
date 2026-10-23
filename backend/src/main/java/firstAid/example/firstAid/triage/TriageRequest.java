package firstAid.example.firstAid.triage;

import jakarta.validation.constraints.NotNull;

public record TriageRequest(
        @NotNull(message = "conscious is required") Boolean conscious,
        @NotNull(message = "breathing is required") Boolean breathing,
        @NotNull(message = "severeBleeding is required") Boolean severeBleeding) {
}
