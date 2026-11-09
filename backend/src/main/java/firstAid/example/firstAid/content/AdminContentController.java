package firstAid.example.firstAid.content;

import firstAid.example.firstAid.common.Api;
import firstAid.example.firstAid.common.ApiFailure;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin")
public class AdminContentController {
    private final CatalogService catalog;
    private final ArticleService articles;

    public AdminContentController(CatalogService catalog, ArticleService articles) { this.catalog = catalog; this.articles = articles; }

    @GetMapping("/categories")
    public Map<String, Object> categories(@RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int page_size) { return page(catalog.categories(true), page, page_size); }
    @GetMapping("/categories/{id}")
    public Map<String, Object> category(@PathVariable UUID id) { return Api.ok(catalog.category(id, true)); }
    @PostMapping("/categories")
    public ResponseEntity<Map<String, Object>> createCategory(@RequestBody Map<String, Object> body) {
        return Api.created(catalog.saveCategory(null, body));
    }
    @PutMapping("/categories/{id}")
    public Map<String, Object> updateCategory(@PathVariable UUID id, @RequestBody Map<String, Object> body) {
        return Api.ok(catalog.saveCategory(id, body));
    }
    @DeleteMapping("/categories/{id}")
    public ResponseEntity<Void> deleteCategory(@PathVariable UUID id) { catalog.deleteCategory(id); return ResponseEntity.noContent().build(); }

    @GetMapping("/sources")
    public Map<String, Object> sources(@RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int page_size) { return page(catalog.sources(true), page, page_size); }
    @GetMapping("/sources/{id}")
    public Map<String, Object> source(@PathVariable UUID id) { return Api.ok(catalog.source(id, true)); }
    @PostMapping("/sources")
    public ResponseEntity<Map<String, Object>> createSource(@RequestBody Map<String, Object> body) {
        return Api.created(catalog.saveSource(null, body));
    }
    @PutMapping("/sources/{id}")
    public Map<String, Object> updateSource(@PathVariable UUID id, @RequestBody Map<String, Object> body) {
        return Api.ok(catalog.saveSource(id, body));
    }
    @DeleteMapping("/sources/{id}")
    public ResponseEntity<Void> deleteSource(@PathVariable UUID id) { catalog.deleteSource(id); return ResponseEntity.noContent().build(); }

    @GetMapping("/articles")
    public Map<String, Object> articles(@RequestParam(required = false) UUID category_id,
            @RequestParam(required = false) String status, @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int page_size) {
        checkPage(page, page_size);
        return Api.ok(Map.of("items", articles.list(category_id, null, q, status, true, page, page_size),
                "page", page, "page_size", page_size, "total", articles.adminCount(category_id, status, q)));
    }
    @GetMapping("/articles/{id}")
    public Map<String, Object> article(@PathVariable UUID id) { return Api.ok(articles.get(id, true)); }
    @PostMapping("/articles")
    public ResponseEntity<Map<String, Object>> createArticle(@RequestBody Map<String, Object> body) {
        return Api.created(articles.save(null, body));
    }
    @PutMapping("/articles/{id}")
    public Map<String, Object> updateArticle(@PathVariable UUID id, @RequestBody Map<String, Object> body) {
        return Api.ok(articles.save(id, body));
    }
    @DeleteMapping("/articles/{id}")
    public ResponseEntity<Void> deleteArticle(@PathVariable UUID id) { articles.delete(id); return ResponseEntity.noContent().build(); }
    @PostMapping("/articles/{id}/publish")
    public Map<String, Object> publish(@PathVariable UUID id, @RequestBody Map<String, Object> body) {
        return Api.ok(articles.publish(id, revision(body)));
    }
    @PostMapping("/articles/{id}/unpublish")
    public Map<String, Object> unpublish(@PathVariable UUID id, @RequestBody Map<String, Object> body) {
        return Api.ok(articles.unpublish(id, revision(body)));
    }

    @GetMapping("/facilities")
    public Map<String, Object> facilities(@RequestParam(required = false) String region_code,
            @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int page_size) {
        return page(catalog.facilities(region_code, null, null, true), page, page_size);
    }
    @GetMapping("/facilities/{id}")
    public Map<String, Object> facility(@PathVariable UUID id) { return Api.ok(catalog.facility(id, true)); }
    @PostMapping("/facilities")
    public ResponseEntity<Map<String, Object>> createFacility(@RequestBody Map<String, Object> body) {
        return Api.created(catalog.saveFacility(null, body));
    }
    @PutMapping("/facilities/{id}")
    public Map<String, Object> updateFacility(@PathVariable UUID id, @RequestBody Map<String, Object> body) {
        return Api.ok(catalog.saveFacility(id, body));
    }
    @DeleteMapping("/facilities/{id}")
    public ResponseEntity<Void> deleteFacility(@PathVariable UUID id) { catalog.deleteFacility(id); return ResponseEntity.noContent().build(); }

    private Map<String, Object> page(List<?> list, int page, int pageSize) {
        checkPage(page, pageSize);
        int from = Math.min(list.size(), (page - 1) * pageSize);
        int to = Math.min(list.size(), from + pageSize);
        return Api.ok(Map.of("items", list.subList(from, to), "page", page, "page_size", pageSize, "total", list.size()));
    }

    private void checkPage(int page, int pageSize) {
        if (page < 1 || pageSize < 1 || pageSize > 100 || page > 100000)
            throw ApiFailure.invalid("page", "Phân trang không hợp lệ");
    }

    private long revision(Map<String, Object> body) {
        Object n = body.get("expected_revision");
        if (!(n instanceof Number v) || v.longValue() < 1 || v.doubleValue() != v.longValue())
            throw ApiFailure.invalid("expected_revision", "Cần revision hợp lệ");
        return v.longValue();
    }
}
