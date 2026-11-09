package firstAid.example.firstAid.content;

import firstAid.example.firstAid.common.ApiFailure;
import firstAid.example.firstAid.common.Checks;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CatalogService {
    private final JdbcTemplate db;
    private final Rows rows;

    public CatalogService(JdbcTemplate db, Rows rows) { this.db = db; this.rows = rows; }

    public void bump() {
        db.update("UPDATE public_data_state SET data_version=?, updated_at=now() WHERE id=1", UUID.randomUUID());
    }

    public List<Map<String, Object>> categories(boolean admin) {
        String sql = "SELECT * FROM categories" + (admin ? "" : " WHERE is_active=true") + " ORDER BY sort_order, code";
        return db.query(sql, rows::category);
    }

    public Map<String, Object> category(UUID id, boolean admin) {
        return db.query("SELECT * FROM categories WHERE id=?" + (admin ? "" : " AND is_active=true"), rows::category, id)
                .stream().findFirst().orElseThrow(ApiFailure::notFound);
    }

    @Transactional
    public Map<String, Object> saveCategory(UUID id, Map<String, Object> body) {
        String code = Checks.text(body, "code", 4, true);
        if (!code.matches("FA[0-9]{2}")) throw ApiFailure.invalid("code", "Cần mã FAxx");
        String name = Checks.text(body, "name", 200, true);
        String group = Checks.value(body, "group_code", Set.of("CIRCULATION", "TRAUMA", "ENVIRONMENT", "OTHER"));
        String description = Checks.text(body, "description", 4000, false);
        List<String> keywords = Checks.strings(body, "keywords", 100);
        int sort = Checks.integer(body, "sort_order", 0, 10000, 0);
        boolean active = Checks.bool(body, "is_active", true);
        if (id == null) {
            id = UUID.randomUUID();
            db.update("INSERT INTO categories(id,code,name,group_code,description,keywords_json,sort_order,is_active) " +
                    "VALUES(?,?,?,?,?,CAST(? AS jsonb),?,?)", id, code, name, group,
                    description == null ? "" : description, rows.encode(keywords), sort, active);
        } else {
            db.queryForObject("SELECT id FROM categories WHERE id=? FOR UPDATE", UUID.class, id);
            Map<String, Object> old = category(id, true);
            if (!code.equals(old.get("code")) &&
                    (((String) old.get("code")).matches("FA(0[1-9]|1[0-8])")
                            || db.queryForObject("SELECT count(*) FROM articles WHERE category_id=?", Integer.class, id) > 0))
                throw ApiFailure.invalid("code", "Mã danh mục chính thức hoặc đã có bài phải giữ ổn định");
            if (!active && db.queryForObject("SELECT count(*) FROM articles WHERE category_id=? AND status='PUBLISHED'", Integer.class, id) > 0)
                throw ApiFailure.inUse();
            db.update("UPDATE categories SET code=?,name=?,group_code=?,description=?,keywords_json=CAST(? AS jsonb),sort_order=?,is_active=? WHERE id=?",
                    code, name, group, description == null ? "" : description, rows.encode(keywords), sort, active, id);
        }
        bump();
        return category(id, true);
    }

    @Transactional
    public void deleteCategory(UUID id) {
        category(id, true);
        if (db.queryForObject("SELECT count(*) FROM articles WHERE category_id=?", Integer.class, id) > 0) throw ApiFailure.inUse();
        db.update("DELETE FROM categories WHERE id=?", id);
        bump();
    }

    public List<Map<String, Object>> sources(boolean admin) {
        String sql = "SELECT * FROM sources" + (admin ? "" : " WHERE is_active=true") + " ORDER BY code";
        return db.query(sql, rows::source);
    }

    public Map<String, Object> source(UUID id, boolean admin) {
        return db.query("SELECT * FROM sources WHERE id=?" + (admin ? "" : " AND is_active=true"), rows::source, id)
                .stream().findFirst().orElseThrow(ApiFailure::notFound);
    }

    @Transactional
    public Map<String, Object> saveSource(UUID id, Map<String, Object> body) {
        String code = Checks.text(body, "code", 80, true);
        String title = Checks.text(body, "title", 300, true);
        String publisher = Checks.text(body, "publisher", 500, true);
        String media = Checks.value(body, "media_type", Set.of("PDF", "WEB"));
        Integer year = body.get("publication_year") == null ? null : Checks.integer(body, "publication_year", 1000, 9999, 0);
        Integer pages = body.get("page_count") == null ? null : Checks.integer(body, "page_count", 1, 100000, 0);
        String url = Checks.https(Checks.text(body, "original_url", 2000, false), "original_url");
        if (media.equals("PDF") && pages == null) throw ApiFailure.invalid("page_count", "PDF cần số trang");
        if (media.equals("WEB") && (pages != null || url == null)) throw ApiFailure.invalid("media_type", "WEB cần URL HTTPS và không có số trang");
        String rights = Checks.text(body, "rights_note", 4000, false);
        boolean active = Checks.bool(body, "is_active", true);
        if (id == null) {
            id = UUID.randomUUID();
            db.update("INSERT INTO sources(id,code,title,publisher,publication_year,media_type,page_count,revision,original_url,is_active,rights_note) " +
                    "VALUES(?,?,?,?,?,?,?,1,?,?,?)", id, code, title, publisher, year, media, pages, url, active, rights);
        } else {
            db.queryForObject("SELECT id FROM sources WHERE id=? FOR UPDATE", UUID.class, id);
            Map<String, Object> old = source(id, true);
            if (!code.equals(old.get("code")) &&
                    db.queryForObject("SELECT count(*) FROM article_references WHERE source_id=?", Integer.class, id) > 0)
                throw ApiFailure.invalid("code", "Mã nguồn đã được trích dẫn phải giữ ổn định");
            if (!active && db.queryForObject("SELECT count(*) FROM article_references r JOIN articles a ON a.id=r.article_id " +
                    "WHERE r.source_id=? AND a.status='PUBLISHED'", Integer.class, id) > 0) throw ApiFailure.inUse();
            if (media.equals("WEB") && db.queryForObject("SELECT count(*) FROM article_references WHERE source_id=? " +
                    "AND (page_start IS NOT NULL OR page_end IS NOT NULL)", Integer.class, id) > 0) throw ApiFailure.inUse();
            if (media.equals("PDF") && db.queryForObject("SELECT count(*) FROM article_references WHERE source_id=? " +
                    "AND (page_start IS NULL OR page_end IS NULL OR page_end>?)", Integer.class, id, pages) > 0) throw ApiFailure.inUse();
            boolean changed = !old.get("code").equals(code) || !old.get("title").equals(title)
                    || !old.get("publisher").equals(publisher) || !java.util.Objects.equals(old.get("publication_year"), year)
                    || !old.get("media_type").equals(media) || !java.util.Objects.equals(old.get("page_count"), pages)
                    || !java.util.Objects.equals(old.get("original_url"), url);
            db.update("UPDATE sources SET code=?,title=?,publisher=?,publication_year=?,media_type=?,page_count=?," +
                    "revision=revision+?,original_url=?,is_active=?,rights_note=? WHERE id=?",
                    code, title, publisher, year, media, pages, changed ? 1 : 0, url, active, rights, id);
        }
        bump();
        return source(id, true);
    }

    @Transactional
    public void deleteSource(UUID id) {
        source(id, true);
        if (db.queryForObject("SELECT count(*) FROM article_references WHERE source_id=?", Integer.class, id) > 0) throw ApiFailure.inUse();
        db.update("DELETE FROM sources WHERE id=?", id);
        bump();
    }

    public List<Map<String, Object>> facilities(String region, Double latitude, Double longitude, boolean admin) {
        if ((latitude == null) != (longitude == null)) throw ApiFailure.invalid("latitude", "Cần cả latitude và longitude");
        if (latitude != null && (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180))
            throw ApiFailure.invalid("latitude", "Tọa độ ngoài giới hạn");
        String sql = "SELECT * FROM facilities WHERE 1=1" + (admin ? "" : " AND is_active=true") +
                (region == null ? "" : " AND region_code=?") + " ORDER BY name,id";
        List<Map<String, Object>> list = region == null ? db.query(sql, rows::facility) : db.query(sql, rows::facility, region);
        if (latitude != null) {
            for (Map<String, Object> facility : list) {
                if (facility.get("latitude") != null && facility.get("longitude") != null) {
                    double km = distance(latitude, longitude, ((Number) facility.get("latitude")).doubleValue(),
                            ((Number) facility.get("longitude")).doubleValue());
                    facility.put("distance_km", Math.round(km * 100.0) / 100.0);
                    facility.put("distance_type", "straight_line");
                }
            }
            list.sort(Comparator.comparingDouble(f -> f.get("distance_km") == null ? Double.MAX_VALUE : ((Number) f.get("distance_km")).doubleValue()));
        }
        return list;
    }

    public Map<String, Object> facility(UUID id, boolean admin) {
        return db.query("SELECT * FROM facilities WHERE id=?" + (admin ? "" : " AND is_active=true"), rows::facility, id)
                .stream().findFirst().orElseThrow(ApiFailure::notFound);
    }

    @Transactional
    public Map<String, Object> saveFacility(UUID id, Map<String, Object> body) {
        String name = Checks.text(body, "name", 200, true);
        String region = Checks.text(body, "region_code", 40, true);
        String address = Checks.text(body, "address", 4000, true);
        String phone = Checks.text(body, "phone", 40, false);
        if (phone != null) {
            phone = phone.replaceAll("[() .-]", "");
            if (!phone.matches("\\+?[0-9]{3,20}")) throw ApiFailure.invalid("phone", "Số điện thoại không hợp lệ");
        }
        BigDecimal lat = Checks.decimal(body, "latitude", -90, 90);
        BigDecimal lon = Checks.decimal(body, "longitude", -180, 180);
        if ((lat == null) != (lon == null)) throw ApiFailure.invalid("latitude", "Cần cả hai tọa độ");
        String emergency = Checks.value(body, "emergency_24h", Set.of("YES", "NO", "UNKNOWN"));
        String note = Checks.text(body, "verification_note", 4000, false);
        Instant verified = Checks.instant(body, "verified_at");
        boolean active = Checks.bool(body, "is_active", false);
        if (active && (phone == null || lat == null || note == null || verified == null))
            throw ApiFailure.invalid("is_active", "Cơ sở phải được xác minh trước khi công bố");
        if (id == null) {
            id = UUID.randomUUID();
            db.update("INSERT INTO facilities(id,name,region_code,address,phone,latitude,longitude,emergency_24h,verification_note,verified_at,is_active) " +
                    "VALUES(?,?,?,?,?,?,?,?,?,?,?)", id, name, region, address, phone, lat, lon, emergency, note,
                    verified == null ? null : Timestamp.from(verified), active);
        } else {
            facility(id, true);
            db.update("UPDATE facilities SET name=?,region_code=?,address=?,phone=?,latitude=?,longitude=?,emergency_24h=?," +
                    "verification_note=?,verified_at=?,is_active=? WHERE id=?", name, region, address, phone, lat, lon,
                    emergency, note, verified == null ? null : Timestamp.from(verified), active, id);
        }
        bump();
        return facility(id, true);
    }

    @Transactional
    public void deleteFacility(UUID id) {
        facility(id, true);
        db.update("DELETE FROM facilities WHERE id=?", id);
        bump();
    }

    private double distance(double a, double b, double c, double d) {
        double lat = Math.toRadians(c - a), lon = Math.toRadians(d - b);
        double v = Math.pow(Math.sin(lat / 2), 2) + Math.cos(Math.toRadians(a)) * Math.cos(Math.toRadians(c)) * Math.pow(Math.sin(lon / 2), 2);
        return 6371.0088 * 2 * Math.atan2(Math.sqrt(v), Math.sqrt(1 - v));
    }
}
