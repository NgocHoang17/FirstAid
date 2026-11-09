package firstAid.example.firstAid.common;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class ApiFailure extends RuntimeException {
    private final HttpStatus status;
    private final String code;
    private final List<Map<String, String>> fields;

    public ApiFailure(HttpStatus status, String code, String message) {
        this(status, code, message, List.of());
    }

    public ApiFailure(HttpStatus status, String code, String message, List<Map<String, String>> fields) {
        super(message);
        this.status = status;
        this.code = code;
        this.fields = fields;
    }

    public HttpStatus status() { return status; }
    public String code() { return code; }
    public List<Map<String, String>> fields() { return fields; }

    public static ApiFailure invalid(String field, String message) {
        return new ApiFailure(HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", "Dữ liệu chưa hợp lệ",
                List.of(Map.of("field", field, "message", message)));
    }

    public static ApiFailure notFound() {
        return new ApiFailure(HttpStatus.NOT_FOUND, "NOT_FOUND", "Không tìm thấy dữ liệu công khai phù hợp");
    }

    public static ApiFailure inUse() {
        return new ApiFailure(HttpStatus.CONFLICT, "RESOURCE_IN_USE", "Dữ liệu đang được tham chiếu");
    }
}
