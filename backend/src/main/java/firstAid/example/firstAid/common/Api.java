package firstAid.example.firstAid.common;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

public final class Api {
    private Api() {}

    public static Map<String, Object> ok(Object data) {
        return Map.of("data", data, "meta", Map.of("trace_id", UUID.randomUUID().toString()));
    }

    public static Map<String, Object> items(List<?> items) {
        return ok(Map.of("items", items));
    }

    public static ResponseEntity<Map<String, Object>> created(Object data) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ok(data));
    }

    public static Map<String, Object> error(String code, String message, List<Map<String, String>> fields) {
        Map<String, Object> detail = new LinkedHashMap<>();
        detail.put("code", code);
        detail.put("message", message);
        detail.put("field_errors", fields);
        return Map.of("error", detail, "meta", Map.of("trace_id", UUID.randomUUID().toString()));
    }
}
