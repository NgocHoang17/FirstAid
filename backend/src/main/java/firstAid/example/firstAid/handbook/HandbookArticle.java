package firstAid.example.firstAid.handbook;

import java.util.List;

public record HandbookArticle(
        String id,
        String category,
        String title,
        List<String> keywords,
        String summary,
        List<String> doNow,
        List<String> doNotDo,
        String reviewedAt) {
}
