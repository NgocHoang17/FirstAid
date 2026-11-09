package firstAid.example.firstAid.common;

import java.math.BigDecimal;
import java.net.URI;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

public final class Checks {
    private Checks() {}

    public static String text(Map<String, Object> body, String key, int max, boolean required) {
        Object raw = body.get(key);
        if (raw == null && !required) return null;
        if (!(raw instanceof String value)) throw ApiFailure.invalid(key, "Cần chuỗi ký tự");
        value = value.trim();
        if ((required && value.isEmpty()) || value.length() > max) throw ApiFailure.invalid(key, "Độ dài không hợp lệ");
        return value.isEmpty() ? null : value;
    }

    public static String value(Map<String, Object> body, String key, Set<String> allowed) {
        String v = text(body, key, 80, true);
        if (!allowed.contains(v)) throw ApiFailure.invalid(key, "Giá trị không hợp lệ");
        return v;
    }

    public static UUID uuid(Map<String, Object> body, String key) {
        try { return UUID.fromString(text(body, key, 36, true)); }
        catch (IllegalArgumentException ex) { throw ApiFailure.invalid(key, "UUID không hợp lệ"); }
    }

    public static boolean bool(Map<String, Object> body, String key, boolean defaultValue) {
        Object v = body.get(key);
        if (v == null) return defaultValue;
        if (!(v instanceof Boolean b)) throw ApiFailure.invalid(key, "Cần true hoặc false");
        return b;
    }

    public static int integer(Map<String, Object> body, String key, int min, int max, int defaultValue) {
        Object v = body.get(key);
        if (v == null) return defaultValue;
        if (!(v instanceof Number n) || n.doubleValue() != n.intValue() || n.intValue() < min || n.intValue() > max)
            throw ApiFailure.invalid(key, "Số nguyên ngoài giới hạn");
        return n.intValue();
    }

    public static BigDecimal decimal(Map<String, Object> body, String key, int min, int max) {
        Object v = body.get(key);
        if (v == null) return null;
        if (!(v instanceof Number n)) throw ApiFailure.invalid(key, "Cần tọa độ số");
        BigDecimal d;
        try { d = new BigDecimal(n.toString()); }
        catch (NumberFormatException ex) { throw ApiFailure.invalid(key, "Cần tọa độ hữu hạn"); }
        if (d.compareTo(BigDecimal.valueOf(min)) < 0 || d.compareTo(BigDecimal.valueOf(max)) > 0)
            throw ApiFailure.invalid(key, "Tọa độ ngoài giới hạn");
        return d;
    }

    public static Instant instant(Map<String, Object> body, String key) {
        String v = text(body, key, 50, false);
        if (v == null) return null;
        try { return Instant.parse(v); }
        catch (Exception ex) { throw ApiFailure.invalid(key, "Thời gian UTC không hợp lệ"); }
    }

    public static String https(String value, String key) {
        if (value == null) return null;
        try {
            URI uri = URI.create(value);
            if (!"https".equalsIgnoreCase(uri.getScheme()) || uri.getHost() == null) throw new IllegalArgumentException();
            return value;
        } catch (IllegalArgumentException ex) { throw ApiFailure.invalid(key, "Cần URL HTTPS hợp lệ"); }
    }

    public static List<String> strings(Map<String, Object> body, String key, int max) {
        Object raw = body.get(key);
        if (!(raw instanceof List<?> list) || list.size() > max) throw ApiFailure.invalid(key, "Cần mảng chuỗi hợp lệ");
        List<String> result = new ArrayList<>();
        for (Object item : list) {
            if (!(item instanceof String s) || s.isBlank() || s.length() > 4000) throw ApiFailure.invalid(key, "Phần tử rỗng hoặc quá dài");
            result.add(s.trim());
        }
        return result;
    }

    @SuppressWarnings("unchecked")
    public static List<Map<String, Object>> objects(Map<String, Object> body, String key, int max) {
        Object raw = body.get(key);
        if (!(raw instanceof List<?> list) || list.size() > max) throw ApiFailure.invalid(key, "Cần mảng đối tượng hợp lệ");
        List<Map<String, Object>> result = new ArrayList<>();
        for (Object item : list) {
            if (!(item instanceof Map<?, ?> map) || map.keySet().stream().anyMatch(k -> !(k instanceof String)))
                throw ApiFailure.invalid(key, "Phần tử không hợp lệ");
            result.add((Map<String, Object>) map);
        }
        return result;
    }
}
