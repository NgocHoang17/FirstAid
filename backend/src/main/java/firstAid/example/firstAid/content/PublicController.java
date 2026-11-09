package firstAid.example.firstAid.content;

import firstAid.example.firstAid.common.Api;
import firstAid.example.firstAid.common.ApiFailure;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
public class PublicController {
    private final CatalogService catalog;
    private final ArticleService articles;

    public PublicController(CatalogService catalog, ArticleService articles) { this.catalog = catalog; this.articles = articles; }

    @GetMapping("/categories")
    public Map<String, Object> categories() {
        List<Map<String, Object>> result = catalog.categories(false);
        if (result.size() > 30) throw tooMany();
        return Api.items(result);
    }

    @GetMapping("/articles")
    public Map<String, Object> articles(@RequestParam(required = false) UUID category_id,
            @RequestParam(required = false) String age_group, @RequestParam(required = false) String q) {
        return Api.items(articles.list(category_id, age_group, q, null, false, 1, 500));
    }

    @GetMapping("/articles/{id}")
    public Map<String, Object> article(@PathVariable UUID id) { return Api.ok(articles.get(id, false)); }

    @GetMapping("/sources")
    public Map<String, Object> sources() {
        List<Map<String, Object>> result = catalog.sources(false);
        if (result.size() > 100) throw tooMany();
        return Api.items(result);
    }

    @GetMapping("/sources/{id}")
    public Map<String, Object> source(@PathVariable UUID id) { return Api.ok(catalog.source(id, false)); }

    @GetMapping("/facilities")
    public Map<String, Object> facilities(@RequestParam(required = false) String region_code,
            @RequestParam(required = false) Double latitude, @RequestParam(required = false) Double longitude) {
        List<Map<String, Object>> result = catalog.facilities(region_code, latitude, longitude, false);
        if (region_code != null && result.size() > 100) throw tooMany();
        return Api.items(result);
    }

    @GetMapping("/facilities/{id}")
    public Map<String, Object> facility(@PathVariable UUID id) { return Api.ok(catalog.facility(id, false)); }

    private ApiFailure tooMany() {
        return new ApiFailure(HttpStatus.SERVICE_UNAVAILABLE, "SERVICE_UNAVAILABLE", "Tập dữ liệu vượt giới hạn contract");
    }
}
