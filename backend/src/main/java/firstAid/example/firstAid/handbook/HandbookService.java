package firstAid.example.firstAid.handbook;

import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import org.springframework.stereotype.Service;

@Service
public class HandbookService {

    private static final List<HandbookArticle> ARTICLES = List.of(
            new HandbookArticle("thermal-burn", "Sinh hoạt gia đình", "Sơ cứu bỏng nhiệt",
                    List.of("bỏng", "nước sôi", "lửa"), "Xử lý ban đầu khi bỏng do nhiệt.",
                    List.of("Loại bỏ nguồn nhiệt nếu an toàn.", "Làm mát vùng bỏng bằng nước sạch mát.", "Đến cơ sở y tế khi bỏng nặng, rộng hoặc ở vùng nhạy cảm."),
                    List.of("Không bôi kem đánh răng, dầu hoặc thuốc không rõ nguồn gốc.", "Không chọc vỡ bóng nước."),
                    "2026-09-11"),
            new HandbookArticle("choking", "Sinh hoạt gia đình", "Hóc dị vật",
                    List.of("hóc", "nghẹn", "dị vật"), "Nhận biết và xử trí ban đầu khi nghi ngờ tắc đường thở.",
                    List.of("Gọi hỗ trợ y tế khẩn cấp khi nạn nhân không thể thở hoặc nói.", "Dùng luồng hướng dẫn theo độ tuổi trong ứng dụng đã được phê duyệt."),
                    List.of("Không cho ăn hoặc uống.", "Không đưa ngón tay vào miệng để móc dị vật khi không nhìn thấy dị vật."),
                    "2026-09-11"),
            new HandbookArticle("bleeding", "Học đường/Công sở", "Cầm máu ban đầu",
                    List.of("chảy máu", "vết cắt", "đứt tay"), "Xử lý an toàn đối với vết thương chảy máu.",
                    List.of("Dùng gạc hoặc vải sạch ép trực tiếp nếu an toàn.", "Gọi 115 khi máu chảy xối xả hoặc nạn nhân có dấu hiệu sốc."),
                    List.of("Không tháo lớp gạc đầu tiên nếu đã thấm máu.", "Không chạm trực tiếp vào máu khi có phương tiện bảo hộ."),
                    "2026-09-11"));

    public List<HandbookArticle> find(String query, String category) {
        String normalizedQuery = normalize(query);
        String normalizedCategory = normalize(category);
        return ARTICLES.stream()
                .filter(article -> normalizedCategory.isBlank() || normalize(article.category()).contains(normalizedCategory))
                .filter(article -> normalizedQuery.isBlank() || matches(article, normalizedQuery))
                .sorted(Comparator.comparing(HandbookArticle::title))
                .toList();
    }

    public HandbookArticle getById(String id) {
        return ARTICLES.stream().filter(article -> article.id().equals(id)).findFirst()
                .orElseThrow(() -> new HandbookNotFoundException(id));
    }

    private boolean matches(HandbookArticle article, String query) {
        return normalize(article.title()).contains(query)
                || normalize(article.summary()).contains(query)
                || article.keywords().stream().map(this::normalize).anyMatch(keyword -> keyword.contains(query));
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }
}
