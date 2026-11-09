package firstAid.example.firstAid.content;

import firstAid.example.firstAid.common.Api;
import firstAid.example.firstAid.common.ApiFailure;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/offline-snapshot")
public class OfflineController {
    private final JdbcTemplate db;
    private final Rows rows;
    private final CatalogService catalog;
    private final ArticleService articles;
    private final String locale;
    private final String publicRegion;
    private final String emergencyNumber;

    public OfflineController(JdbcTemplate db, Rows rows, CatalogService catalog, ArticleService articles,
            @Value("${firstaid.public.locale}") String locale,
            @Value("${firstaid.public.region-code}") String publicRegion,
            @Value("${firstaid.public.emergency-number}") String emergencyNumber) {
        this.db = db; this.rows = rows; this.catalog = catalog; this.articles = articles;
        this.locale = locale; this.publicRegion = publicRegion; this.emergencyNumber = emergencyNumber;
    }

    @GetMapping
    @Transactional(readOnly = true, isolation = Isolation.REPEATABLE_READ)
    public ResponseEntity<Map<String, Object>> snapshot(@RequestParam String region_code,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        if (region_code.isBlank() || region_code.length() > 40) throw ApiFailure.invalid("region_code", "Vùng không hợp lệ");
        if (publicRegion.isBlank() || emergencyNumber.isBlank())
            throw new ApiFailure(HttpStatus.SERVICE_UNAVAILABLE, "SERVICE_UNAVAILABLE", "Chưa cấu hình vùng và số hỗ trợ đã xác minh");
        if (!publicRegion.equals(region_code)) throw ApiFailure.invalid("region_code", "Vùng chưa được cấu hình công khai");
        Map<String, Object> state = db.query("SELECT data_version,updated_at FROM public_data_state WHERE id=1",
                (rs, n) -> Map.<String, Object>of("data_version", rs.getString(1), "updated_at", rs.getTimestamp(2).toInstant()))
                .stream().findFirst().orElseThrow(() -> new ApiFailure(HttpStatus.SERVICE_UNAVAILABLE, "SERVICE_UNAVAILABLE", "Thiếu trạng thái dữ liệu"));
        String version = (String) state.get("data_version");
        String etag = "\"" + version + "\"";
        if (etag.equals(ifNoneMatch)) return ResponseEntity.status(HttpStatus.NOT_MODIFIED).eTag(etag).build();
        List<Map<String, Object>> categoryList = catalog.categories(false);
        List<Map<String, Object>> articleList = articles.list(null, null, null, null, false, 1, 500);
        for (Map<String, Object> summary : articleList) {
            Map<String, Object> full = articles.get(java.util.UUID.fromString((String) summary.get("id")), false);
            summary.clear(); summary.putAll(full);
        }
        List<Map<String, Object>> sourceList = db.query("SELECT s.* FROM sources s WHERE s.is_active=true AND EXISTS(" +
                "SELECT 1 FROM article_references r JOIN articles a ON a.id=r.article_id JOIN categories c ON c.id=a.category_id " +
                "WHERE r.source_id=s.id AND a.status='PUBLISHED' AND a.content_checked=true AND c.is_active=true) ORDER BY s.code",
                rows::source);
        List<Map<String, Object>> facilityList = catalog.facilities(region_code, null, null, false);
        if (categoryList.size() > 30 || articleList.size() > 500 || sourceList.size() > 100 || facilityList.size() > 100)
            throw new ApiFailure(HttpStatus.SERVICE_UNAVAILABLE, "SERVICE_UNAVAILABLE", "Snapshot vượt giới hạn contract");
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("schema_version", 1); payload.put("data_version", version);
        payload.put("generated_at", (Instant) state.get("updated_at")); payload.put("region_code", region_code);
        payload.put("app_config", Map.of("locale", locale, "emergency_number", emergencyNumber));
        payload.put("categories", categoryList); payload.put("articles", articleList);
        payload.put("sources", sourceList); payload.put("facilities", facilityList);
        return ResponseEntity.ok().eTag(etag).body(Api.ok(payload));
    }
}
