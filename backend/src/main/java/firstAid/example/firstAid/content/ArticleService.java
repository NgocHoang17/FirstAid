package firstAid.example.firstAid.content;

import firstAid.example.firstAid.common.ApiFailure;
import firstAid.example.firstAid.common.Checks;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ArticleService {
    private final JdbcTemplate db;
    private final Rows rows;
    private final CatalogService catalog;
    private final Set<String> assetKeys;

    public ArticleService(JdbcTemplate db, Rows rows, CatalogService catalog,
            @Value("${firstaid.assets.allowed-keys:}") String allowedKeys) {
        this.db = db; this.rows = rows; this.catalog = catalog;
        this.assetKeys = new HashSet<>();
        for (String key : allowedKeys.split(",")) if (!key.isBlank()) assetKeys.add(key.trim());
    }

    public Map<String, Object> get(UUID id, boolean admin) {
        String publicFilter = admin ? "" : " AND a.status='PUBLISHED' AND a.content_checked=true AND c.is_active=true " +
                "AND NOT EXISTS(SELECT 1 FROM article_references r JOIN sources s ON s.id=r.source_id " +
                "WHERE r.article_id=a.id AND s.is_active=false)";
        Map<String, Object> article = db.query("SELECT a.* FROM articles a JOIN categories c ON c.id=a.category_id WHERE a.id=?" + publicFilter,
                rows::article, id).stream().findFirst().orElseThrow(ApiFailure::notFound);
        article.put("steps", db.query("SELECT * FROM article_steps WHERE article_id=? ORDER BY position", rows::step, id));
        article.put("references", db.query("SELECT * FROM article_references WHERE article_id=? ORDER BY position", rows::reference, id));
        return article;
    }

    public List<Map<String, Object>> list(UUID category, String age, String q, String status, boolean admin, int page, int pageSize) {
        if (age != null && !Set.of("ADULT", "CHILD", "ALL").contains(age)) throw ApiFailure.invalid("age_group", "Nhóm tuổi không hợp lệ");
        if (status != null && !Set.of("DRAFT", "PUBLISHED").contains(status)) throw ApiFailure.invalid("status", "Trạng thái không hợp lệ");
        StringBuilder sql = new StringBuilder("SELECT a.* FROM articles a JOIN categories c ON c.id=a.category_id WHERE 1=1");
        List<Object> args = new ArrayList<>();
        if (!admin) sql.append(" AND a.status='PUBLISHED' AND a.content_checked=true AND c.is_active=true AND NOT EXISTS " +
                "(SELECT 1 FROM article_references r JOIN sources s ON s.id=r.source_id WHERE r.article_id=a.id AND s.is_active=false)");
        if (category != null) { sql.append(" AND a.category_id=?"); args.add(category); }
        if (age != null) { sql.append(" AND a.age_group IN (?,?)"); args.add(age); args.add("ALL"); }
        if (status != null && admin) { sql.append(" AND a.status=?"); args.add(status); }
        if (q != null && !q.isBlank()) { sql.append(" AND (lower(a.title) LIKE ? OR lower(a.summary) LIKE ? OR lower(c.name) LIKE ?)");
            String needle = "%" + q.trim().toLowerCase(java.util.Locale.ROOT).replace("%", "\\%").replace("_", "\\_") + "%";
            args.add(needle); args.add(needle); args.add(needle);
        }
        sql.append(" ORDER BY c.sort_order,a.title,a.id LIMIT ? OFFSET ?");
        args.add(admin ? pageSize : 501); args.add(admin ? (page - 1) * pageSize : 0);
        List<Map<String, Object>> result = db.query(sql.toString(), rows::article, args.toArray());
        if (!admin && result.size() > 500) throw new ApiFailure(HttpStatus.SERVICE_UNAVAILABLE, "SERVICE_UNAVAILABLE", "Danh sách vượt giới hạn contract");
        for (Map<String, Object> m : result) {
            m.keySet().retainAll(admin ? Set.of("id", "category_id", "slug", "variant_key", "title", "age_group", "summary", "content_revision", "updated_at", "status", "content_checked")
                    : Set.of("id", "category_id", "slug", "variant_key", "title", "age_group", "summary", "content_revision", "updated_at"));
        }
        return result;
    }

    public long adminCount(UUID category, String status, String q) {
        StringBuilder sql = new StringBuilder("SELECT count(*) FROM articles a JOIN categories c ON c.id=a.category_id WHERE 1=1");
        List<Object> args = new ArrayList<>();
        if (category != null) { sql.append(" AND a.category_id=?"); args.add(category); }
        if (status != null) { sql.append(" AND a.status=?"); args.add(status); }
        if (q != null && !q.isBlank()) { sql.append(" AND (lower(a.title) LIKE ? OR lower(a.summary) LIKE ? OR lower(c.name) LIKE ?)");
            String needle = "%" + q.trim().toLowerCase(java.util.Locale.ROOT) + "%";
            args.add(needle); args.add(needle); args.add(needle);
        }
        return db.queryForObject(sql.toString(), Long.class, args.toArray());
    }

    @Transactional
    public Map<String, Object> save(UUID id, Map<String, Object> body) {
        UUID category = Checks.uuid(body, "category_id");
        catalog.category(category, true);
        String slug = Checks.text(body, "slug", 200, true);
        String variant = Checks.text(body, "variant_key", 100, true);
        String title = Checks.text(body, "title", 200, true);
        String age = Checks.value(body, "age_group", Set.of("ADULT", "CHILD", "ALL"));
        String applies = Checks.text(body, "applies_to", 4000, false);
        String summary = Checks.text(body, "summary", 1000, false);
        List<String> recognition = Checks.strings(body, "recognition", 100);
        List<String> actions = Checks.strings(body, "quick_actions", 100);
        List<String> warnings = Checks.strings(body, "warnings", 100);
        List<String> seek = Checks.strings(body, "seek_help", 100);
        List<Map<String, Object>> steps = Checks.objects(body, "steps", 50);
        List<Map<String, Object>> refs = Checks.objects(body, "references", 100);
        boolean checked = Checks.bool(body, "content_checked", false);
        Map<String, Object> old = id == null ? null : get(id, true);
        if (old != null) {
            if (!category.toString().equals(old.get("category_id")) || !variant.equals(old.get("variant_key")))
                throw ApiFailure.invalid("variant_key", "Danh mục và mã biến thể phải giữ ổn định");
            long expected = expectedRevision(body);
            if (((Number) old.get("content_revision")).longValue() != expected)
                throw new ApiFailure(HttpStatus.CONFLICT, "CONTENT_CONFLICT", "Bài đã được sửa ở nơi khác");
            if ("PUBLISHED".equals(old.get("status"))) checked = false;
        } else id = UUID.randomUUID();
        Instant checkedAt = checked ? Instant.now() : null;
        if (old == null) {
            db.update("INSERT INTO articles(id,category_id,slug,variant_key,title,age_group,applies_to,summary,recognition_json," +
                    "quick_actions_json,warnings_json,seek_help_json,status,content_checked,checked_at,content_revision,updated_at) " +
                    "VALUES(?,?,?,?,?,?,?,?,CAST(? AS jsonb),CAST(? AS jsonb),CAST(? AS jsonb),CAST(? AS jsonb),'DRAFT',?,?,1,now())",
                    id, category, slug, variant, title, age, empty(applies), empty(summary), rows.encode(recognition),
                    rows.encode(actions), rows.encode(warnings), rows.encode(seek), checked, timestamp(checkedAt));
        } else {
            int changed = db.update("UPDATE articles SET category_id=?,slug=?,variant_key=?,title=?,age_group=?,applies_to=?,summary=?," +
                    "recognition_json=CAST(? AS jsonb),quick_actions_json=CAST(? AS jsonb),warnings_json=CAST(? AS jsonb)," +
                    "seek_help_json=CAST(? AS jsonb),status='DRAFT',content_checked=?,checked_at=?,content_revision=content_revision+1," +
                    "updated_at=now() WHERE id=? AND content_revision=?", category, slug, variant, title, age, empty(applies),
                    empty(summary), rows.encode(recognition), rows.encode(actions), rows.encode(warnings), rows.encode(seek),
                    checked, timestamp(checkedAt), id, expectedRevision(body));
            if (changed != 1) throw new ApiFailure(HttpStatus.CONFLICT, "CONTENT_CONFLICT", "Bài đã được sửa ở nơi khác");
            db.update("DELETE FROM article_references WHERE article_id=?", id);
            db.update("DELETE FROM article_steps WHERE article_id=?", id);
        }
        saveSteps(id, steps);
        saveReferences(id, refs);
        if (old != null && "PUBLISHED".equals(old.get("status"))) catalog.bump();
        return get(id, true);
    }

    private void saveSteps(UUID articleId, List<Map<String, Object>> steps) {
        Set<UUID> ids = new HashSet<>();
        for (int i = 0; i < steps.size(); i++) {
            Map<String, Object> s = steps.get(i);
            int position = Checks.integer(s, "position", 1, 50, -1);
            if (position != i + 1) throw ApiFailure.invalid("steps", "Vị trí bước phải liên tiếp từ 1");
            UUID id = s.get("id") == null ? UUID.randomUUID() : Checks.uuid(s, "id");
            if (!ids.add(id)) throw ApiFailure.invalid("steps", "ID bước bị trùng");
            String title = Checks.text(s, "title", 200, true);
            String instruction = Checks.text(s, "instruction", 4000, true);
            String asset = Checks.text(s, "asset_key", 200, false);
            if (asset != null && !assetKeys.contains(asset)) throw ApiFailure.invalid("asset_key", "Asset không nằm trong ứng dụng");
            String image = Checks.https(Checks.text(s, "image_url", 2000, false), "image_url");
            String alt = Checks.text(s, "alt_text", 1000, false);
            if ((asset != null || image != null) && alt == null) throw ApiFailure.invalid("alt_text", "Ảnh cần mô tả");
            db.update("INSERT INTO article_steps(id,article_id,position,title,instruction,asset_key,image_url,alt_text) VALUES(?,?,?,?,?,?,?,?)",
                    id, articleId, position, title, instruction, asset, image, alt);
        }
    }

    private void saveReferences(UUID articleId, List<Map<String, Object>> refs) {
        for (int i = 0; i < refs.size(); i++) {
            Map<String, Object> r = refs.get(i);
            UUID sourceId = Checks.uuid(r, "source_id");
            Map<String, Object> source = catalog.source(sourceId, true);
            Integer start = r.get("page_start") == null ? null : Checks.integer(r, "page_start", 1, 100000, 0);
            Integer end = r.get("page_end") == null ? null : Checks.integer(r, "page_end", 1, 100000, 0);
            if ("PDF".equals(source.get("media_type"))) {
                if (start == null || end == null || end < start || end > ((Number) source.get("page_count")).intValue())
                    throw ApiFailure.invalid("references", "Trang PDF không hợp lệ");
            } else if (start != null || end != null) throw ApiFailure.invalid("references", "Nguồn WEB không dùng số trang");
            String section = Checks.text(r, "section_key", 80, false);
            String note = Checks.text(r, "note", 4000, false);
            db.update("INSERT INTO article_references(id,article_id,source_id,position,page_start,page_end,section_key,note) " +
                    "VALUES(?,?,?,?,?,?,?,?)", UUID.randomUUID(), articleId, sourceId, i + 1, start, end,
                    section == null ? "all" : section, note);
        }
    }

    @Transactional
    public Map<String, Object> publish(UUID id, long expected) {
        Map<String, Object> a = get(id, true);
        if (((Number) a.get("content_revision")).longValue() != expected)
            throw new ApiFailure(HttpStatus.CONFLICT, "CONTENT_CONFLICT", "Bài đã được sửa ở nơi khác");
        validatePublish(a);
        int changed = db.update("UPDATE articles SET status='PUBLISHED',updated_at=now() WHERE id=? AND content_revision=? AND status='DRAFT'", id, expected);
        if (changed != 1) throw new ApiFailure(HttpStatus.CONFLICT, "CONTENT_CONFLICT", "Bài đã được xuất bản hoặc thay đổi");
        catalog.bump();
        return get(id, true);
    }

    private void validatePublish(Map<String, Object> a) {
        if (!Boolean.TRUE.equals(a.get("content_checked")) || a.get("checked_at") == null
                || ((String) a.get("applies_to")).isBlank() || ((String) a.get("summary")).isBlank()) notReady();
        for (String key : List.of("recognition", "quick_actions", "steps", "warnings", "seek_help", "references"))
            if (((List<?>) a.get(key)).isEmpty()) notReady();
        UUID categoryId = UUID.fromString((String) a.get("category_id"));
        db.queryForObject("SELECT id FROM categories WHERE id=? FOR SHARE", UUID.class, categoryId);
        if (!Boolean.TRUE.equals(catalog.category(categoryId, true).get("is_active"))) notReady();
        for (Object item : (List<?>) a.get("references")) {
            Map<?, ?> ref = (Map<?, ?>) item;
            UUID sourceId = UUID.fromString((String) ref.get("source_id"));
            db.queryForObject("SELECT id FROM sources WHERE id=? FOR SHARE", UUID.class, sourceId);
            Map<String, Object> source = catalog.source(sourceId, true);
            if (!Boolean.TRUE.equals(source.get("is_active"))) notReady();
        }
    }

    private void notReady() {
        throw new ApiFailure(HttpStatus.UNPROCESSABLE_CONTENT, "CONTENT_NOT_READY", "Bài chưa đủ nội dung hoặc nguồn để công bố");
    }

    @Transactional
    public Map<String, Object> unpublish(UUID id, long expected) {
        Map<String, Object> a = get(id, true);
        if (((Number) a.get("content_revision")).longValue() != expected)
            throw new ApiFailure(HttpStatus.CONFLICT, "CONTENT_CONFLICT", "Bài đã được sửa ở nơi khác");
        if (!"PUBLISHED".equals(a.get("status"))) return a;
        db.update("UPDATE articles SET status='DRAFT',updated_at=now() WHERE id=?", id);
        catalog.bump();
        return get(id, true);
    }

    @Transactional
    public void delete(UUID id) {
        Map<String, Object> a = get(id, true);
        db.update("DELETE FROM articles WHERE id=?", id);
        if ("PUBLISHED".equals(a.get("status"))) catalog.bump();
    }

    private long expectedRevision(Map<String, Object> body) {
        Object n = body.get("expected_revision");
        if (!(n instanceof Number number) || number.longValue() < 1 || number.doubleValue() != number.longValue())
            throw ApiFailure.invalid("expected_revision", "Cần revision hợp lệ");
        return number.longValue();
    }

    private String empty(String s) { return s == null ? "" : s; }
    private Timestamp timestamp(Instant instant) { return instant == null ? null : Timestamp.from(instant); }
}
