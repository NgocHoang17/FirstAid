package firstAid.example.firstAid.assistant;

import firstAid.example.firstAid.common.ApiFailure;
import firstAid.example.firstAid.common.Checks;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

@Service
public class AssistantService {
    private static final Set<String> STATUSES = Set.of("answered", "clarification_needed", "emergency_redirect",
            "insufficient_evidence", "out_of_scope", "unavailable");
    private final HttpClient client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(2)).build();
    private final ObjectMapper json;
    private final JdbcTemplate db;
    private final EmergencyPolicy emergencyPolicy;
    private final String baseUrl;
    private final String token;
    private final int maxPerMinute;
    private final ConcurrentHashMap<String, ArrayDeque<Long>> windows = new ConcurrentHashMap<>();
    private final AtomicInteger requestCount = new AtomicInteger();

    public AssistantService(ObjectMapper json, JdbcTemplate db, EmergencyPolicy emergencyPolicy,
            @Value("${firstaid.ai.base-url}") String baseUrl,
            @Value("${firstaid.ai.internal-token}") String token,
            @Value("${firstaid.ai.max-per-minute:20}") int maxPerMinute) {
        this.json = json; this.db = db; this.emergencyPolicy = emergencyPolicy; this.baseUrl = baseUrl; this.token = token;
        this.maxPerMinute = maxPerMinute;
    }

    public Map<String, Object> query(Map<String, Object> body, String clientAddress) {
        UUID requestId = Checks.uuid(body, "client_request_id");
        String message = Checks.text(body, "message", 2000, true);
        String age = body.get("age_group") == null ? null : Checks.value(body, "age_group", Set.of("ADULT", "CHILD", "ALL"));
        String mode = Checks.value(body, "context_mode", Set.of("learning", "unspecified"));
        limit(clientAddress);
        if (emergencyPolicy.clearCurrentIncident(message)) {
            Map<String, Object> redirect = fallback(requestId, "emergency_redirect");
            redirect.put("safety_message_code", "CONTACT_HELP");
            return redirect;
        }
        if (baseUrl.isBlank() || token.isBlank()) return fallback(requestId, "unavailable");
        try {
            URI uri = URI.create(baseUrl.endsWith("/") ? baseUrl + "internal/v1/query" : baseUrl + "/internal/v1/query");
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("request_id", requestId.toString()); payload.put("message", message);
            payload.put("age_group", age); payload.put("context_mode", mode);
            HttpRequest request = HttpRequest.newBuilder(uri).timeout(Duration.ofSeconds(12))
                    .header("Content-Type", "application/json").header("X-Internal-Token", token)
                    .POST(HttpRequest.BodyPublishers.ofString(json.writeValueAsString(payload))).build();
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) return fallback(requestId, "unavailable");
            Map<String, Object> result = json.readValue(response.body(), new TypeReference<Map<String, Object>>() {});
            return validate(result, requestId, age);
        } catch (Exception ex) {
            return fallback(requestId, "unavailable");
        }
    }

    private Map<String, Object> validate(Map<String, Object> result, UUID requestId, String age) {
        if (!requestId.toString().equals(result.get("request_id")) || !STATUSES.contains(result.get("status")))
            return fallback(requestId, "unavailable");
        for (String key : List.of("answer_blocks", "citations", "suggested_category_code", "suggested_article_id",
                "safety_message_code", "clarification_question", "corpus_version"))
            if (!result.containsKey(key)) return fallback(requestId, "unavailable");
        if (!(result.get("answer_blocks") instanceof List<?> blocks) || !(result.get("citations") instanceof List<?> citations))
            return fallback(requestId, "unavailable");
        Set<String> citationIds = new HashSet<>();
        for (Object item : citations) {
            if (!(item instanceof Map<?, ?> citation) || !validCitation(citation, age)) return fallback(requestId, "insufficient_evidence");
            if (!citationIds.add((String) citation.get("id"))) return fallback(requestId, "insufficient_evidence");
        }
        if ("answered".equals(result.get("status"))) {
            if (blocks.isEmpty() || citationIds.isEmpty()) return fallback(requestId, "insufficient_evidence");
            for (Object item : blocks) {
                if (!(item instanceof Map<?, ?> block) || !(block.get("text") instanceof String text) || text.isBlank()
                        || !(block.get("citation_ids") instanceof List<?> ids) || ids.isEmpty()
                        || ids.stream().anyMatch(id -> !citationIds.contains(id))) return fallback(requestId, "insufficient_evidence");
            }
        } else if (!blocks.isEmpty() || !citations.isEmpty()) return fallback(requestId, "unavailable");
        if ("clarification_needed".equals(result.get("status")) &&
                (!(result.get("clarification_question") instanceof String question) || question.isBlank()))
            return fallback(requestId, "unavailable");
        if ("emergency_redirect".equals(result.get("status")) &&
                !Set.of("CONTACT_HELP", "OPEN_FIRST_AID_GUIDE").contains(result.get("safety_message_code")))
            return fallback(requestId, "unavailable");
        Object suggested = result.get("suggested_article_id");
        if (suggested != null && !validArticle(suggested, null, age)) result.put("suggested_article_id", null);
        Object category = result.get("suggested_category_code");
        if (category != null) {
            if (!(category instanceof String code) || !code.matches("FA(0[1-9]|1[0-8])")
                    || db.queryForObject("SELECT count(*) FROM categories WHERE code=? AND is_active=true", Integer.class, code) == 0)
                result.put("suggested_category_code", null);
        }
        return result;
    }

    private boolean validCitation(Map<?, ?> citation, String age) {
        try {
            String id = (String) citation.get("id");
            String evidence = (String) citation.get("evidence_id");
            UUID sourceId = UUID.fromString((String) citation.get("source_id"));
            if (id == null || id.isBlank() || evidence == null || evidence.isBlank()
                    || !(citation.get("source_revision") instanceof Number rev)) return false;
            List<Map<String, Object>> found = db.query("SELECT title,revision,media_type,page_count FROM sources WHERE id=? AND is_active=true",
                    (rs, n) -> {
                        Map<String, Object> m = new HashMap<>();
                        m.put("title", rs.getString("title")); m.put("revision", rs.getLong("revision"));
                        m.put("media_type", rs.getString("media_type")); m.put("page_count", rs.getObject("page_count"));
                        return m;
                    }, sourceId);
            if (found.size() != 1 || ((Number) found.get(0).get("revision")).longValue() != rev.longValue()) return false;
            Map<String, Object> source = found.get(0);
            Object start = citation.get("page_start"), end = citation.get("page_end");
            if ("PDF".equals(source.get("media_type"))) {
                if (!(start instanceof Number a) || !(end instanceof Number b) || a.intValue() < 1
                        || b.intValue() < a.intValue() || b.intValue() > ((Number) source.get("page_count")).intValue()) return false;
            } else if (start != null || end != null) return false;
            Object article = citation.get("article_id");
            if (article != null && (!(citation.get("article_revision") instanceof Number)
                    || !validArticle(article, citation.get("article_revision"), age)
                    || db.queryForObject("SELECT count(*) FROM article_references WHERE article_id=? AND source_id=?", Integer.class,
                            UUID.fromString((String) article), sourceId) == 0)) return false;
            ((Map<String, Object>) citation).put("source_title", source.get("title"));
            return true;
        } catch (Exception ex) { return false; }
    }

    private boolean validArticle(Object articleId, Object revision, String age) {
        try {
            UUID id = UUID.fromString((String) articleId);
            return db.query("SELECT a.content_revision,a.age_group FROM articles a JOIN categories c ON c.id=a.category_id " +
                            "WHERE a.id=? AND a.status='PUBLISHED' AND a.content_checked=true AND c.is_active=true " +
                            "AND NOT EXISTS(SELECT 1 FROM article_references r JOIN sources s ON s.id=r.source_id " +
                            "WHERE r.article_id=a.id AND s.is_active=false)",
                    (rs, n) -> (revision == null || (revision instanceof Number r && r.longValue() == rs.getLong(1)))
                            && (age == null ? "ALL".equals(rs.getString(2))
                                    : "ALL".equals(rs.getString(2)) || age.equals(rs.getString(2))), id)
                    .stream().findFirst().orElse(false);
        } catch (Exception ex) { return false; }
    }

    private Map<String, Object> fallback(UUID requestId, String status) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("request_id", requestId.toString()); result.put("status", status);
        result.put("answer_blocks", List.of()); result.put("citations", List.of());
        result.put("suggested_category_code", null); result.put("suggested_article_id", null);
        result.put("safety_message_code", null); result.put("clarification_question", null);
        result.put("corpus_version", null);
        return result;
    }

    private void limit(String ip) {
        long now = System.currentTimeMillis();
        ArrayDeque<Long> queue = windows.computeIfAbsent(ip, ignored -> new ArrayDeque<>());
        synchronized (queue) {
            while (!queue.isEmpty() && queue.peekFirst() < now - 60_000) queue.removeFirst();
            if (queue.size() >= maxPerMinute) throw new ApiFailure(HttpStatus.TOO_MANY_REQUESTS, "RATE_LIMITED", "Vui lòng thử lại sau");
            queue.addLast(now);
        }
        if (requestCount.incrementAndGet() % 100 == 0) windows.entrySet().removeIf(e -> {
            synchronized (e.getValue()) { return e.getValue().isEmpty() || e.getValue().peekLast() < now - 60_000; }
        });
    }
}
