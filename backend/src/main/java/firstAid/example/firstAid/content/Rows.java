package firstAid.example.firstAid.content;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

@Component
public class Rows {
    private final ObjectMapper json;

    public Rows(ObjectMapper json) { this.json = json; }

    public String encode(Object value) { return json.writeValueAsString(value); }
    public List<String> strings(String value) {
        return json.readValue(value, new TypeReference<List<String>>() {});
    }

    public static Instant instant(ResultSet rs, String column) throws SQLException {
        Timestamp t = rs.getTimestamp(column);
        return t == null ? null : t.toInstant();
    }

    public Map<String, Object> category(ResultSet r, int row) throws SQLException {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.getString("id")); m.put("code", r.getString("code")); m.put("name", r.getString("name"));
        m.put("group_code", r.getString("group_code")); m.put("description", r.getString("description"));
        m.put("keywords", strings(r.getString("keywords_json"))); m.put("sort_order", r.getInt("sort_order"));
        m.put("is_active", r.getBoolean("is_active"));
        return m;
    }

    public Map<String, Object> source(ResultSet r, int row) throws SQLException {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.getString("id")); m.put("code", r.getString("code")); m.put("title", r.getString("title"));
        m.put("publisher", r.getString("publisher")); m.put("publication_year", r.getObject("publication_year"));
        m.put("media_type", r.getString("media_type")); m.put("page_count", r.getObject("page_count"));
        m.put("revision", r.getLong("revision")); m.put("original_url", r.getString("original_url"));
        m.put("is_active", r.getBoolean("is_active")); m.put("rights_note", r.getString("rights_note"));
        return m;
    }

    public Map<String, Object> article(ResultSet r, int row) throws SQLException {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.getString("id")); m.put("category_id", r.getString("category_id"));
        m.put("slug", r.getString("slug")); m.put("variant_key", r.getString("variant_key"));
        m.put("title", r.getString("title")); m.put("age_group", r.getString("age_group"));
        m.put("applies_to", r.getString("applies_to")); m.put("summary", r.getString("summary"));
        m.put("recognition", strings(r.getString("recognition_json")));
        m.put("quick_actions", strings(r.getString("quick_actions_json")));
        m.put("warnings", strings(r.getString("warnings_json")));
        m.put("seek_help", strings(r.getString("seek_help_json")));
        m.put("status", r.getString("status")); m.put("content_checked", r.getBoolean("content_checked"));
        m.put("checked_at", instant(r, "checked_at")); m.put("content_revision", r.getLong("content_revision"));
        m.put("updated_at", instant(r, "updated_at"));
        return m;
    }

    public Map<String, Object> step(ResultSet r, int row) throws SQLException {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.getString("id")); m.put("position", r.getInt("position"));
        m.put("title", r.getString("title")); m.put("instruction", r.getString("instruction"));
        m.put("asset_key", r.getString("asset_key")); m.put("image_url", r.getString("image_url"));
        m.put("alt_text", r.getString("alt_text"));
        return m;
    }

    public Map<String, Object> reference(ResultSet r, int row) throws SQLException {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("source_id", r.getString("source_id")); m.put("page_start", r.getObject("page_start"));
        m.put("page_end", r.getObject("page_end")); m.put("section_key", r.getString("section_key"));
        m.put("note", r.getString("note"));
        return m;
    }

    public Map<String, Object> facility(ResultSet r, int row) throws SQLException {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.getString("id")); m.put("name", r.getString("name"));
        m.put("region_code", r.getString("region_code")); m.put("address", r.getString("address"));
        m.put("phone", r.getString("phone")); m.put("latitude", r.getObject("latitude"));
        m.put("longitude", r.getObject("longitude")); m.put("emergency_24h", r.getString("emergency_24h"));
        m.put("verification_note", r.getString("verification_note")); m.put("verified_at", instant(r, "verified_at"));
        m.put("is_active", r.getBoolean("is_active"));
        m.put("distance_km", null); m.put("distance_type", null);
        return m;
    }
}
