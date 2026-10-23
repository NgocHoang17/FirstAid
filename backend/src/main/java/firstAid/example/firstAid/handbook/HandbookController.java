package firstAid.example.firstAid.handbook;

import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/handbook")
public class HandbookController {

    private final HandbookService handbookService;

    public HandbookController(HandbookService handbookService) {
        this.handbookService = handbookService;
    }

    @GetMapping
    public ResponseEntity<List<HandbookArticle>> find(
            @RequestParam(required = false) String query,
            @RequestParam(required = false) String category) {
        return ResponseEntity.ok(handbookService.find(query, category));
    }

    @GetMapping("/{id}")
    public ResponseEntity<HandbookArticle> getById(@PathVariable String id) {
        return ResponseEntity.ok(handbookService.getById(id));
    }
}
