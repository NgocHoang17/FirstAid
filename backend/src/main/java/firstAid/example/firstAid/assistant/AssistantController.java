package firstAid.example.firstAid.assistant;

import firstAid.example.firstAid.common.Api;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/assistant")
public class AssistantController {
    private final AssistantService service;
    public AssistantController(AssistantService service) { this.service = service; }

    @PostMapping("/query")
    public Map<String, Object> query(@RequestBody Map<String, Object> body, HttpServletRequest request) {
        return Api.ok(service.query(body, request.getRemoteAddr()));
    }
}
