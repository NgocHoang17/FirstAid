package firstAid.example.firstAid.common;

import java.util.List;
import java.util.Map;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.bind.MissingServletRequestParameterException;

@RestControllerAdvice
public class ApiExceptionHandler {
    @ExceptionHandler(ApiFailure.class)
    ResponseEntity<Map<String, Object>> business(ApiFailure ex) {
        ResponseEntity.BodyBuilder response = ResponseEntity.status(ex.status());
        if (ex.status() == HttpStatus.TOO_MANY_REQUESTS) response.header("Retry-After", "60");
        return response.body(Api.error(ex.code(), ex.getMessage(), ex.fields()));
    }

    @ExceptionHandler({HttpMessageNotReadableException.class, MethodArgumentTypeMismatchException.class,
            HandlerMethodValidationException.class, MethodArgumentNotValidException.class,
            MissingServletRequestParameterException.class})
    ResponseEntity<Map<String, Object>> invalid(Exception ex) {
        return ResponseEntity.badRequest().body(Api.error("VALIDATION_ERROR", "Dữ liệu chưa hợp lệ", List.of()));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    ResponseEntity<Map<String, Object>> integrity(DataIntegrityViolationException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(Api.error("RESOURCE_IN_USE", "Dữ liệu trùng hoặc còn được tham chiếu", List.of()));
    }

    @ExceptionHandler(DataAccessException.class)
    ResponseEntity<Map<String, Object>> database(DataAccessException ex) {
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(Api.error("SERVICE_UNAVAILABLE", "Cơ sở dữ liệu tạm thời không sẵn sàng", List.of()));
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<Map<String, Object>> unexpected(Exception ex) {
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(Api.error("SERVICE_UNAVAILABLE", "Dịch vụ tạm thời không sẵn sàng", List.of()));
    }
}
